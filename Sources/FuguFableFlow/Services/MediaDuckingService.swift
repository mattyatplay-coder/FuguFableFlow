import AppKit
import CoreAudio
import Foundation

@MainActor
final class MediaDuckingService {
    private struct SystemOutputState {
        let deviceID: AudioDeviceID
        let wasMuted: UInt32?
        let volume: Float32?
        let changedMute: Bool
        let changedVolume: Bool
    }

    private struct ChromeTabReference: Hashable {
        let windowIndex: Int
        let tabIndex: Int
    }

    private enum MediaApp: String, CaseIterable {
        case music = "com.apple.Music"
        case spotify = "com.spotify.client"

        var displayName: String {
            switch self {
            case .music: "Music"
            case .spotify: "Spotify"
            }
        }

        var pauseScript: String {
            """
            tell application "\(displayName)"
                if player state is playing then
                    pause
                    return "paused"
                end if
                return "unchanged"
            end tell
            """
        }

        var resumeScript: String {
            """
            tell application "\(displayName)"
                play
            end tell
            """
        }
    }

    private var pausedApps = Set<MediaApp>()
    private var pausedChromeSpotifyTabs = Set<ChromeTabReference>()
    private var systemOutputState: SystemOutputState?

    func begin() {
        pausedApps.removeAll()
        pausedChromeSpotifyTabs.removeAll()
        for app in MediaApp.allCases where isRunning(bundleIdentifier: app.rawValue) {
            if runAppleScript(app.pauseScript) == "paused" {
                pausedApps.insert(app)
                DiagnosticLog.media.info("paused media app=\(app.displayName, privacy: .public)")
            }
        }
        pausedChromeSpotifyTabs = pauseChromeSpotifyTabs()
        systemOutputState = muteSystemOutput()
    }

    func end() {
        restoreSystemOutput()
        resumeChromeSpotifyTabs()
        for app in pausedApps where isRunning(bundleIdentifier: app.rawValue) {
            _ = runAppleScript(app.resumeScript)
            DiagnosticLog.media.info("resumed media app=\(app.displayName, privacy: .public)")
        }
        pausedChromeSpotifyTabs.removeAll()
        pausedApps.removeAll()
    }

    private func isRunning(bundleIdentifier: String) -> Bool {
        NSWorkspace.shared.runningApplications.contains { $0.bundleIdentifier == bundleIdentifier }
    }

    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: source)?.executeAndReturnError(&error)
        if let error {
            DiagnosticLog.media.error("appleScript failed error=\(String(describing: error), privacy: .public)")
            return nil
        }
        return result?.stringValue
    }

    private func pauseChromeSpotifyTabs() -> Set<ChromeTabReference> {
        guard isRunning(bundleIdentifier: "com.google.Chrome") else { return [] }
        let script = """
        with timeout of 2 seconds
            tell application "Google Chrome"
                set AppleScript's text item delimiters to linefeed
                set pausedTabs to {}
                repeat with windowIndex from 1 to count of windows
                    repeat with tabIndex from 1 to count of tabs of window windowIndex
                        set tabRef to tab tabIndex of window windowIndex
                        set tabURL to URL of tabRef as string
                        if tabURL contains "open.spotify.com" then
                            set pauseResult to execute javascript "(() => { const button = document.querySelector('[data-testid=\\\"control-button-playpause\\\"]'); const label = (button?.getAttribute('aria-label') || '').toLowerCase(); if (label.includes('pause')) { button.click(); return 'paused'; } return 'unchanged'; })();" in tabRef
                            if pauseResult is "paused" then
                                set end of pausedTabs to ((windowIndex as string) & ":" & (tabIndex as string))
                            end if
                        end if
                    end repeat
                end repeat
                return pausedTabs as text
            end tell
        end timeout
        """

        guard let result = runAppleScript(script), !result.isEmpty else { return [] }
        let refs = Set(result
            .split(separator: "\n")
            .compactMap { value -> ChromeTabReference? in
                let parts = value.split(separator: ":")
                guard parts.count == 2,
                      let windowIndex = Int(parts[0]),
                      let tabIndex = Int(parts[1]) else {
                    return nil
                }
                return ChromeTabReference(windowIndex: windowIndex, tabIndex: tabIndex)
            })
        if !refs.isEmpty {
            DiagnosticLog.media.info("paused chrome spotify tabs count=\(refs.count, privacy: .public)")
        }
        return refs
    }

    private func resumeChromeSpotifyTabs() {
        guard isRunning(bundleIdentifier: "com.google.Chrome") else { return }
        for tab in pausedChromeSpotifyTabs {
            let script = """
            with timeout of 2 seconds
                tell application "Google Chrome"
                    if (count of windows) >= \(tab.windowIndex) then
                        if (count of tabs of window \(tab.windowIndex)) >= \(tab.tabIndex) then
                            set tabRef to tab \(tab.tabIndex) of window \(tab.windowIndex)
                            set tabURL to URL of tabRef as string
                            if tabURL contains "open.spotify.com" then
                                execute javascript "(() => { const button = document.querySelector('[data-testid=\\\"control-button-playpause\\\"]'); const label = (button?.getAttribute('aria-label') || '').toLowerCase(); if (label.includes('play')) { button.click(); return 'resumed'; } return 'unchanged'; })();" in tabRef
                            end if
                        end if
                    end if
                end tell
            end timeout
            """
            _ = runAppleScript(script)
        }
        if !pausedChromeSpotifyTabs.isEmpty {
            DiagnosticLog.media.info("resumed chrome spotify tabs count=\(self.pausedChromeSpotifyTabs.count, privacy: .public)")
        }
    }

    private func muteSystemOutput() -> SystemOutputState? {
        guard let deviceID = defaultOutputDeviceID(), deviceID != kAudioObjectUnknown else {
            DiagnosticLog.media.info("system output mute skipped no default output")
            return nil
        }

        let priorMute = getUInt32(
            deviceID: deviceID,
            selector: kAudioDevicePropertyMute,
            scope: kAudioDevicePropertyScopeOutput
        )
        if priorMute == 1 {
            DiagnosticLog.media.info("system output already muted deviceID=\(deviceID, privacy: .public)")
            return nil
        }

        if isSettable(
            deviceID: deviceID,
            selector: kAudioDevicePropertyMute,
            scope: kAudioDevicePropertyScopeOutput
        ) {
            if priorMute != 1,
               setUInt32(
                   1,
                   deviceID: deviceID,
                   selector: kAudioDevicePropertyMute,
                   scope: kAudioDevicePropertyScopeOutput
               ) {
                DiagnosticLog.media.info("system output muted deviceID=\(deviceID, privacy: .public)")
                return SystemOutputState(
                    deviceID: deviceID,
                    wasMuted: priorMute,
                    volume: nil,
                    changedMute: true,
                    changedVolume: false
                )
            }
        }

        let priorVolume = getFloat32(
            deviceID: deviceID,
            selector: kAudioDevicePropertyVolumeScalar,
            scope: kAudioDevicePropertyScopeOutput
        )
        if let priorVolume,
           isSettable(
               deviceID: deviceID,
               selector: kAudioDevicePropertyVolumeScalar,
               scope: kAudioDevicePropertyScopeOutput
           ),
           priorVolume > 0,
           setFloat32(
               0,
               deviceID: deviceID,
               selector: kAudioDevicePropertyVolumeScalar,
               scope: kAudioDevicePropertyScopeOutput
           ) {
            DiagnosticLog.media.info("system output volume lowered deviceID=\(deviceID, privacy: .public)")
            return SystemOutputState(
                deviceID: deviceID,
                wasMuted: priorMute,
                volume: priorVolume,
                changedMute: false,
                changedVolume: true
            )
        }

        DiagnosticLog.media.info("system output mute unsupported deviceID=\(deviceID, privacy: .public)")
        return nil
    }

    private func restoreSystemOutput() {
        guard let state = systemOutputState else { return }
        defer { systemOutputState = nil }

        if state.changedVolume, let volume = state.volume {
            _ = setFloat32(
                volume,
                deviceID: state.deviceID,
                selector: kAudioDevicePropertyVolumeScalar,
                scope: kAudioDevicePropertyScopeOutput
            )
            DiagnosticLog.media.info("system output volume restored deviceID=\(state.deviceID, privacy: .public)")
        }

        if state.changedMute, let wasMuted = state.wasMuted {
            _ = setUInt32(
                wasMuted,
                deviceID: state.deviceID,
                selector: kAudioDevicePropertyMute,
                scope: kAudioDevicePropertyScopeOutput
            )
            DiagnosticLog.media.info("system output mute restored deviceID=\(state.deviceID, privacy: .public)")
        }
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID()
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &deviceID
        )
        return status == noErr ? deviceID : nil
    }

    private func isSettable(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> Bool {
        var address = propertyAddress(selector: selector, scope: scope)
        guard AudioObjectHasProperty(deviceID, &address) else { return false }
        var settable = DarwinBoolean(false)
        let status = AudioObjectIsPropertySettable(deviceID, &address, &settable)
        return status == noErr && settable.boolValue
    }

    private func getUInt32(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> UInt32? {
        var address = propertyAddress(selector: selector, scope: scope)
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        return status == noErr ? value : nil
    }

    private func setUInt32(
        _ value: UInt32,
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> Bool {
        var address = propertyAddress(selector: selector, scope: scope)
        var mutableValue = value
        let size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &mutableValue)
        return status == noErr
    }

    private func getFloat32(
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> Float32? {
        var address = propertyAddress(selector: selector, scope: scope)
        guard AudioObjectHasProperty(deviceID, &address) else { return nil }
        var value: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        return status == noErr ? value : nil
    }

    private func setFloat32(
        _ value: Float32,
        deviceID: AudioDeviceID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> Bool {
        var address = propertyAddress(selector: selector, scope: scope)
        var mutableValue = value
        let size = UInt32(MemoryLayout<Float32>.size)
        let status = AudioObjectSetPropertyData(deviceID, &address, 0, nil, size, &mutableValue)
        return status == noErr
    }

    private func propertyAddress(
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope
    ) -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
    }
}
