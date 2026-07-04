import Carbon.HIToolbox
import AppKit
import Foundation

@MainActor
final class GlobalHotKeyService {
    nonisolated(unsafe) private var hotKeyRef: EventHotKeyRef?
    nonisolated(unsafe) private var eventHandlerRef: EventHandlerRef?
    nonisolated(unsafe) private var eventTap: CFMachPort?
    nonisolated(unsafe) private var eventTapSource: CFRunLoopSource?
    nonisolated(unsafe) private var commandModeFlagsMonitor: Any?
    private var action: (() -> Void)?
    private var pressAction: (() -> Void)?
    private var releaseAction: (() -> Void)?
    private var commandModePressAction: (() -> Void)?
    private var commandModeReleaseAction: (() -> Void)?
    private var isHandlerInstalled = false
    private var isPushToTalkActive = false
    private var isCommandModeActive = false
    private var functionKeyDown = false
    private var rightCommandDown = false
    private var requiresFunctionForPushToTalk = true

    func register(shortcut: HotKeyShortcut, action: @escaping () -> Void) -> OSStatus {
        DiagnosticLog.hotKey.info("GlobalHotKeyService.register custom keyCode=\(shortcut.keyCode, privacy: .public) modifiers=\(shortcut.modifiers, privacy: .public)")
        unregisterEventTap()
        installCommandModeFlagsMonitorIfNeeded()
        if !isHandlerInstalled {
            let status = installHandler()
            guard status == noErr else { return status }
        }

        self.action = action
        unregisterHotKey()

        let hotKeyID = EventHotKeyID(signature: fourCharacterCode("PFLW"), id: 1)
        return RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }

    func registerRightFunctionRightCommand(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) -> Bool {
        registerRightCommandPushToTalk(requiresFunction: true, onPress: onPress, onRelease: onRelease)
    }

    func registerRightCommand(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) -> Bool {
        registerRightCommandPushToTalk(requiresFunction: false, onPress: onPress, onRelease: onRelease)
    }

    func registerCommandMode(
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) {
        commandModePressAction = onPress
        commandModeReleaseAction = onRelease
        isCommandModeActive = false
        installCommandModeFlagsMonitorIfNeeded()
    }

    private func registerRightCommandPushToTalk(
        requiresFunction: Bool,
        onPress: @escaping () -> Void,
        onRelease: @escaping () -> Void
    ) -> Bool {
        DiagnosticLog.hotKey.info("registerRightFunctionRightCommand begin")
        unregisterHotKey()
        unregisterCommandModeFlagsMonitor()
        pressAction = onPress
        releaseAction = onRelease
        functionKeyDown = false
        rightCommandDown = false
        isPushToTalkActive = false
        requiresFunctionForPushToTalk = requiresFunction

        let eventMask = CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, type, event, userInfo in
                guard let userInfo else {
                    return Unmanaged.passUnretained(event)
                }
                let service = Unmanaged<GlobalHotKeyService>
                    .fromOpaque(userInfo)
                    .takeUnretainedValue()

                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    Task { @MainActor in
                        service.enableEventTap()
                    }
                    return Unmanaged.passUnretained(event)
                }

                guard type == .flagsChanged else {
                    return Unmanaged.passUnretained(event)
                }

                let nsEvent = NSEvent(cgEvent: event)
                Task { @MainActor in
                    if let nsEvent {
                        service.handleFlagsChanged(event: nsEvent, source: "CGEvent")
                    } else {
                        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                        service.handleFlagsChanged(
                            keyCode: keyCode,
                            functionDown: event.flags.contains(.maskSecondaryFn),
                            rightCommandDown: CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(kVK_RightCommand)),
                            commandDown: event.flags.contains(.maskCommand),
                            optionDown: event.flags.contains(.maskAlternate),
                            controlDown: event.flags.contains(.maskControl),
                            source: "CGEvent"
                        )
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        ) else {
            DiagnosticLog.hotKey.error("registerRightFunctionRightCommand tapCreate failed")
            installCommandModeFlagsMonitorIfNeeded()
            return false
        }

        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0) else {
            CFMachPortInvalidate(tap)
            DiagnosticLog.hotKey.error("registerRightFunctionRightCommand runLoopSource failed")
            installCommandModeFlagsMonitorIfNeeded()
            return false
        }

        eventTap = tap
        eventTapSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        DiagnosticLog.hotKey.info("registerRightCommandPushToTalk success requiresFunction=\(requiresFunction, privacy: .public) eventTap=true commandModeFallbackMonitor=false")
        return true
    }

    private func installHandler() -> OSStatus {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData in
                guard let userData else { return noErr }
                let service = Unmanaged<GlobalHotKeyService>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                Task { @MainActor in
                    service.action?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
        isHandlerInstalled = status == noErr
        return status
    }

    nonisolated private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installCommandModeFlagsMonitorIfNeeded() {
        guard eventTap == nil,
              commandModeFlagsMonitor == nil,
              commandModePressAction != nil,
              commandModeReleaseAction != nil else {
            return
        }
        commandModeFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            Task { @MainActor in
                self?.handleFlagsChanged(event: event, source: "NSEventCommandMode")
            }
        }
        DiagnosticLog.hotKey.info("commandMode fallback monitor installed")
    }

    private func handleFlagsChanged(event: NSEvent, source: String) {
        let rightCommandIsDown = event.modifierFlags.contains(.rightCommand) ||
            CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(kVK_RightCommand))
        let functionIsDown: Bool
        if event.keyCode == UInt16(kVK_Function) {
            functionIsDown = event.modifierFlags.contains(.function)
        } else {
            functionIsDown = functionKeyDown || event.modifierFlags.contains(.function)
        }
        handleFlagsChanged(
            keyCode: UInt16(event.keyCode),
            functionDown: functionIsDown,
            rightCommandDown: rightCommandIsDown,
            commandDown: event.modifierFlags.contains(.command),
            optionDown: event.modifierFlags.contains(.option),
            controlDown: event.modifierFlags.contains(.control),
            source: source
        )
    }

    private func handleFlagsChanged(
        keyCode: UInt16,
        functionDown: Bool,
        rightCommandDown eventRightCommandDown: Bool,
        commandDown: Bool,
        optionDown: Bool,
        controlDown: Bool,
        source: String
    ) {
        DiagnosticLog.hotKey.info("flagsChanged source=\(source, privacy: .public) keyCode=\(keyCode, privacy: .public) fn=\(functionDown, privacy: .public) command=\(commandDown, privacy: .public) option=\(optionDown, privacy: .public) control=\(controlDown, privacy: .public) rightCommand=\(eventRightCommandDown, privacy: .public) rightCommandBefore=\(self.rightCommandDown, privacy: .public)")
        functionKeyDown = functionDown
        if keyCode == UInt16(kVK_Function) {
            rightCommandDown = eventRightCommandDown
        } else if keyCode == UInt16(kVK_RightCommand) {
            rightCommandDown = eventRightCommandDown
        } else if !commandDown {
            rightCommandDown = false
        }

        let shouldCommandModeRecord = commandDown && optionDown && controlDown
        if shouldCommandModeRecord && !isCommandModeActive {
            DiagnosticLog.hotKey.info("commandMode press")
            isCommandModeActive = true
            commandModePressAction?()
        } else if !shouldCommandModeRecord && isCommandModeActive {
            DiagnosticLog.hotKey.info("commandMode release")
            isCommandModeActive = false
            commandModeReleaseAction?()
        }

        guard source != "NSEventCommandMode" else { return }

        let shouldRecord = rightCommandDown && (!requiresFunctionForPushToTalk || functionKeyDown)
        if shouldCommandModeRecord {
            return
        } else if shouldRecord && !isPushToTalkActive {
            DiagnosticLog.hotKey.info("pushToTalk press")
            isPushToTalkActive = true
            pressAction?()
        } else if !shouldRecord && isPushToTalkActive {
            DiagnosticLog.hotKey.info("pushToTalk release")
            isPushToTalkActive = false
            releaseAction?()
        }
    }

    private func enableEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: true)
        }
    }

    nonisolated private func unregisterEventTap() {
        if let eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
        if let eventTapSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapSource, .commonModes)
            self.eventTapSource = nil
        }
    }

    private func unregisterCommandModeFlagsMonitor() {
        if let commandModeFlagsMonitor {
            NSEvent.removeMonitor(commandModeFlagsMonitor)
            self.commandModeFlagsMonitor = nil
        }
    }

    deinit {
        unregisterHotKey()
        unregisterEventTap()
        if let commandModeFlagsMonitor {
            NSEvent.removeMonitor(commandModeFlagsMonitor)
        }
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }
}

private extension NSEvent.ModifierFlags {
    static let rightCommand = Self(rawValue: UInt(NX_DEVICERCMDKEYMASK))
}
