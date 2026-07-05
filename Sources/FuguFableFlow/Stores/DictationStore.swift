import AppKit
import Foundation
import SwiftUI

@MainActor
final class DictationStore: ObservableObject {
    private enum RecordingMode {
        case dictation
        case command
    }

    @Published private(set) var isRecording = false
    @Published private(set) var transcriptPreview = ""
    @Published private(set) var statusText = "Ready"
    @Published private(set) var audioInputText = "Audio Input: Checking"
    @Published private(set) var isErrorState = false
    @AppStorage("pasteAutomatically") var pasteAutomatically = true
    @AppStorage("restoreClipboardAfterPaste") var restoreClipboardAfterPaste = true
    @AppStorage("muteMusicWhileDictating") var muteMusicWhileDictating = false
    @AppStorage("dictationNotificationSounds") var dictationNotificationSounds = true
    @AppStorage("dictationNotificationVolume") var dictationNotificationVolume = 0.55
    @AppStorage("dictationStartSound") var dictationStartSound = NotificationSoundOption.tink.rawValue
    @AppStorage("dictationStopSound") var dictationStopSound = NotificationSoundOption.glass.rawValue
    @AppStorage("smartFormattingEnabled") var smartFormattingEnabled = true
    @AppStorage("backtrackEnabled") var backtrackEnabled = true
    @AppStorage("writingStyle") private var writingStyleRaw = WritingStyle.automatic.rawValue
    @AppStorage("recognizeCodingCommands") var recognizeCodingCommands = true
    @AppStorage("customDictionaryText") var customDictionaryText = ""
    @AppStorage("commandModeEnabled") var commandModeEnabled = false
    @AppStorage("pressEnterVoiceCommandEnabled") var pressEnterVoiceCommandEnabled = true
    @AppStorage("commandModeProvider") private var commandModeProviderRaw = CommandModeProvider.off.rawValue
    @AppStorage("commandModeModel") var commandModeModel = "gpt-4.1-mini"
    @AppStorage("promptBuilderEnabled") var promptBuilderEnabled = true
    @AppStorage("promptBuilderGuideRootsText") var promptBuilderGuideRootsText = ""
    @AppStorage("promptBuilderRemoteGuidesEnabled") var promptBuilderRemoteGuidesEnabled = true
    @AppStorage("promptBuilderRemoteGuideRepo") var promptBuilderRemoteGuideRepo = "MikoMurra/FuguFableFlow-Prompt-Guides"
    @AppStorage("promptBuilderIndexOnLaunch") var promptBuilderIndexOnLaunch = false
    @AppStorage("promptBuilderLocalWeightsEnabled") var promptBuilderLocalWeightsEnabled = false
    @AppStorage("promptBuilderWeightRootsText") var promptBuilderWeightRootsText = ""
    @Published private(set) var promptBuilderIndexStatus = "Guide index: Not built"
    @Published private(set) var promptBuilderRemoteStatus = "Remote guides: Not synced"
    @Published private(set) var promptBuilderWeightStatus = "Local weights: Not scanned"
    @AppStorage("dictationShortcutMode") private var dictationShortcutModeRaw = DictationShortcutMode.rightFunctionRightCommandPushToTalk.rawValue
    @AppStorage("dictationHotKeyCode") private var dictationHotKeyCode = Int(HotKeyShortcut.defaultDictation.keyCode)
    @AppStorage("dictationHotKeyModifiers") private var dictationHotKeyModifiers = Int(HotKeyShortcut.defaultDictation.modifiers)
    @Published var commandModeAPIKey: String {
        didSet {
            guard commandModeAPIKey != oldValue else { return }
            KeychainService.saveAPIKey(commandModeAPIKey, for: commandModeProvider)
        }
    }

    private let hotKeyService = GlobalHotKeyService()
    private let textInsertionService = TextInsertionService()
    private let audioInputDeviceService = AudioInputDeviceService()
    private let mediaDuckingService = MediaDuckingService()
    private let dictationSoundService = DictationSoundService()
    private let clipboardImageReferenceService = ClipboardImageReferenceService()
    private var speechService: SpeechRecognitionService?
    private var memoryPressureMonitor: MemoryPressureMonitor?
    private var pendingStopTask: Task<Void, Never>?
    private var commandModeReleaseMonitorTask: Task<Void, Never>?
    private var recordingMode: RecordingMode = .dictation
    private var commandModeStarting = false
    private var latestTranscript = ""
    private var lastCapturedTranscript = ""
    private var didStart = false
    private let releaseTailDelayNanoseconds: UInt64 = 900_000_000

    init() {
        commandModeAPIKey = Self.loadCommandModeAPIKey()
        DiagnosticLog.app.info("DictationStore init")
        if dictationShortcutModeRaw == DictationShortcutMode.rightFunctionRightCommandPushToTalk.rawValue {
            DiagnosticLog.hotKey.info("migrate shortcut mode rightFnRightCommand -> rightCommandPushToTalk")
            dictationShortcutModeRaw = DictationShortcutMode.rightCommandPushToTalk.rawValue
        }
        DispatchQueue.main.async { [weak self] in
            self?.start()
        }
    }

    var menuBarIcon: String {
        isRecording ? "waveform.circle.fill" : "waveform.circle"
    }

    var primaryActionTitle: String {
        isRecording ? "Stop and Paste" : "Start Dictation"
    }

    var dictationShortcutMode: DictationShortcutMode {
        DictationShortcutMode(rawValue: dictationShortcutModeRaw) ?? .rightFunctionRightCommandPushToTalk
    }

    var dictationShortcut: HotKeyShortcut {
        HotKeyShortcut(
            keyCode: UInt32(dictationHotKeyCode),
            modifiers: UInt32(dictationHotKeyModifiers)
        )
    }

    var dictationShortcutDescription: String {
        switch dictationShortcutMode {
        case .rightFunctionRightCommandPushToTalk:
            "Right Fn + Right Command (hold)"
        case .rightCommandPushToTalk:
            "Right Command (hold)"
        case .customToggle:
            dictationShortcut.displayName
        }
    }

    func start() {
        guard !didStart else { return }
        DiagnosticLog.app.info("DictationStore start")
        didStart = true
        registerDictationShortcut()
        registerCommandModeShortcut()
        refreshAudioInputStatus()
        refreshPromptBuilderStatuses()
        memoryPressureMonitor = MemoryPressureMonitor { [weak self] level in
            self?.handleMemoryPressure(level)
        }
        if promptBuilderIndexOnLaunch {
            rebuildPromptGuideIndex()
        }
    }

    func updateDictationShortcut(_ shortcut: HotKeyShortcut) {
        guard shortcut.validationMessage == nil else { return }
        dictationShortcutModeRaw = DictationShortcutMode.customToggle.rawValue
        dictationHotKeyCode = Int(shortcut.keyCode)
        dictationHotKeyModifiers = Int(shortcut.modifiers)
        registerDictationShortcut()
    }

    func updateShortcutMode(_ mode: DictationShortcutMode) {
        dictationShortcutModeRaw = mode.rawValue
        registerDictationShortcut()
    }

    func resetDictationShortcut() {
        dictationShortcutModeRaw = DictationShortcutMode.rightCommandPushToTalk.rawValue
        dictationHotKeyCode = Int(HotKeyShortcut.defaultDictation.keyCode)
        dictationHotKeyModifiers = Int(HotKeyShortcut.defaultDictation.modifiers)
        registerDictationShortcut()
    }

    func toggleRecording() {
        DiagnosticLog.app.info("toggleRecording isRecording=\(self.isRecording, privacy: .public) speechServicePresent=\(self.speechService != nil, privacy: .public) textLength=\(self.latestTranscript.count, privacy: .public)")
        if isRecording {
            scheduleStopRecording(shouldPaste: pasteAutomatically, reason: "toggle")
        } else {
            Task {
                await startRecording(mode: .dictation)
            }
        }
    }

    func requestAccessibilityPermission() {
        _ = textInsertionService.requestAccessibilityPermission()
    }

    func requestMicrophonePermission() {
        Task {
            DiagnosticLog.app.info("requestMicrophonePermission begin")
            statusText = "Requesting microphone"
            let granted = await SpeechRecognitionService.requestMicrophonePermission()
            DiagnosticLog.app.info("requestMicrophonePermission result granted=\(granted, privacy: .public)")
            if granted {
                isErrorState = false
                statusText = "Microphone enabled"
            } else {
                showError("Microphone permission is required")
            }
        }
    }

    func copyLastTranscript() {
        let text = lastCapturedTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        DiagnosticLog.insertion.info("copyLastTranscript textLength=\(text.count, privacy: .public)")
        guard !text.isEmpty else {
            statusText = "No captured transcript"
            return
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        statusText = "Copied transcript"
    }

    func usePreferredMicrophone() {
        DiagnosticLog.audio.info("usePreferredMicrophone begin")
        do {
            let device = try audioInputDeviceService.preferredInputDevice()
            DiagnosticLog.audio.info("usePreferredMicrophone selected id=\(device.id, privacy: .public) name=\(device.name, privacy: .public)")
            audioInputText = "Audio Input: \(device.name)"
            statusText = "Using \(device.name)"
            isErrorState = false
        } catch {
            DiagnosticLog.audio.error("usePreferredMicrophone failed error=\(error.localizedDescription, privacy: .public)")
            showError(error.localizedDescription)
        }
    }

    func refreshAudioInputStatus() {
        let description = audioInputDeviceService.defaultInputDeviceDescription()
        DiagnosticLog.audio.info("refreshAudioInputStatus default=\(description, privacy: .public)")
        audioInputText = "Audio Input: \(description)"
    }

    var customDictionaryTerms: [String] {
        Self.parseDictionaryTerms(customDictionaryText)
    }

    var commandModeShortcutDescription: String {
        "Control + Option + Command (hold)"
    }

    var commandModeProvider: CommandModeProvider {
        get {
            CommandModeProvider(rawValue: commandModeProviderRaw) ?? .off
        }
        set {
            let oldProvider = commandModeProvider
            commandModeProviderRaw = newValue.rawValue
            if commandModeModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                commandModeModel == oldProvider.defaultModel {
                commandModeModel = newValue.defaultModel
            }
            commandModeAPIKey = KeychainService.loadAPIKey(for: newValue)
        }
    }

    var writingStyle: WritingStyle {
        get {
            WritingStyle(rawValue: writingStyleRaw) ?? .automatic
        }
        set {
            writingStyleRaw = newValue.rawValue
        }
    }

    var promptBuilderGuideRoots: [URL] {
        var roots = Self.parseFolderRoots(promptBuilderGuideRootsText)
        if promptBuilderRemoteGuidesEnabled {
            let remoteRoot = PromptGuideRemoteSyncService.defaultCacheRoot()
            if FileManager.default.fileExists(atPath: remoteRoot.path) {
                roots.append(remoteRoot)
            }
        }
        return roots
    }

    var promptBuilderWeightRoots: [URL] {
        Self.parseFolderRoots(promptBuilderWeightRootsText)
    }

    func addPromptGuideFolder() {
        guard let url = Self.chooseFolder(title: "Choose Prompt Guide Folder") else { return }
        promptBuilderGuideRootsText = Self.addFolder(url.path, to: promptBuilderGuideRootsText)
        rebuildPromptGuideIndex()
    }

    func clearPromptGuideFolders() {
        promptBuilderGuideRootsText = ""
        refreshPromptBuilderStatuses()
    }

    func rebuildPromptGuideIndex() {
        let roots = promptBuilderGuideRoots
        guard !roots.isEmpty else {
            promptBuilderIndexStatus = "Guide index: No guide folders selected"
            return
        }
        promptBuilderIndexStatus = "Guide index: Scanning metadata"
        Task {
            do {
                let summary = try PromptGuideIndexService().index(roots: roots)
                await MainActor.run {
                    self.promptBuilderIndexStatus = "Guide index: \(summary.displayText)"
                    if summary.skippedLargeFiles > 0 {
                        self.promptBuilderIndexStatus += ", \(summary.skippedLargeFiles) large skipped"
                    }
                }
            } catch {
                await MainActor.run {
                    self.promptBuilderIndexStatus = "Guide index failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func syncRemotePromptGuides() {
        promptBuilderRemoteStatus = "Remote guides: Syncing"
        Task {
            do {
                let summary = try await PromptGuideRemoteSyncService().sync(repo: self.promptBuilderRemoteGuideRepo)
                await MainActor.run {
                    self.promptBuilderRemoteStatus = summary.displayText
                    self.rebuildPromptGuideIndex()
                }
            } catch {
                await MainActor.run {
                    self.promptBuilderRemoteStatus = "Remote guides failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func addModelWeightFolder() {
        guard let url = Self.chooseFolder(title: "Choose Local Model Weight Folder") else { return }
        promptBuilderWeightRootsText = Self.addFolder(url.path, to: promptBuilderWeightRootsText)
        scanLocalModelWeights()
    }

    func clearModelWeightFolders() {
        promptBuilderWeightRootsText = ""
        promptBuilderWeightStatus = "Local weights: No folders selected"
    }

    func scanLocalModelWeights() {
        let roots = promptBuilderWeightRoots
        guard !roots.isEmpty else {
            promptBuilderWeightStatus = "Local weights: No folders selected"
            return
        }
        promptBuilderWeightStatus = "Local weights: Scanning filenames"
        Task {
            do {
                let summary = try PromptModelWeightScanner().scan(roots: roots)
                await MainActor.run {
                    self.promptBuilderWeightStatus = "Local weights: \(summary.displayText)"
                    if !summary.extensions.isEmpty {
                        self.promptBuilderWeightStatus += " (\(summary.extensions.joined(separator: ", ")))"
                    }
                }
            } catch {
                await MainActor.run {
                    self.promptBuilderWeightStatus = "Local weight scan failed: \(error.localizedDescription)"
                }
            }
        }
    }

    private func registerDictationShortcut() {
        switch dictationShortcutMode {
        case .rightFunctionRightCommandPushToTalk:
            DiagnosticLog.hotKey.info("register shortcut mode=rightFunctionRightCommandPushToTalk")
            let installed = hotKeyService.registerRightFunctionRightCommand(
                onPress: { [weak self] in
                    self?.startPushToTalk()
                },
                onRelease: { [weak self] in
                    self?.stopPushToTalk()
                }
            )
            if installed {
                statusText = "Ready: \(dictationShortcutDescription)"
                isErrorState = false
                DiagnosticLog.hotKey.info("register rightFnRightCommand installed")
            } else {
                DiagnosticLog.hotKey.error("register rightFnRightCommand failed")
                showError("Enable Accessibility permission for Right Fn + Right Command.")
            }
        case .rightCommandPushToTalk:
            DiagnosticLog.hotKey.info("register shortcut mode=rightCommandPushToTalk")
            let installed = hotKeyService.registerRightCommand(
                onPress: { [weak self] in
                    self?.startPushToTalk()
                },
                onRelease: { [weak self] in
                    self?.stopPushToTalk()
                }
            )
            if installed {
                statusText = "Ready: \(dictationShortcutDescription)"
                isErrorState = false
                DiagnosticLog.hotKey.info("register rightCommand installed")
            } else {
                DiagnosticLog.hotKey.error("register rightCommand failed")
                showError("Enable Input Monitoring for Right Command.")
            }
        case .customToggle:
            DiagnosticLog.hotKey.info("register shortcut mode=customToggle shortcut=\(self.dictationShortcutDescription, privacy: .public)")
            let status = hotKeyService.register(shortcut: dictationShortcut) { [weak self] in
                self?.toggleRecording()
            }
            if status == noErr {
                statusText = "Ready: \(dictationShortcutDescription)"
                isErrorState = false
                DiagnosticLog.hotKey.info("register customToggle success")
            } else {
                DiagnosticLog.hotKey.error("register customToggle failed status=\(status, privacy: .public)")
                showError("Shortcut unavailable: \(dictationShortcutDescription)")
            }
        }
    }

    private func registerCommandModeShortcut() {
        hotKeyService.registerCommandMode(
            onPress: { [weak self] in
                self?.startCommandMode()
            },
            onRelease: { [weak self] in
                self?.stopCommandMode()
            }
        )
    }

    private func startPushToTalk() {
        DiagnosticLog.hotKey.info("startPushToTalk received isRecording=\(self.isRecording, privacy: .public) speechServicePresent=\(self.speechService != nil, privacy: .public)")
        pendingStopTask?.cancel()
        pendingStopTask = nil
        guard !isRecording && speechService == nil else { return }
        Task {
            await startRecording(mode: .dictation)
        }
    }

    private func stopPushToTalk() {
        DiagnosticLog.hotKey.info("stopPushToTalk received isRecording=\(self.isRecording, privacy: .public) speechServicePresent=\(self.speechService != nil, privacy: .public)")
        guard isRecording || speechService != nil else { return }
        scheduleStopRecording(shouldPaste: pasteAutomatically, reason: "pushToTalkRelease")
    }

    private func startCommandMode() {
        DiagnosticLog.hotKey.info("startCommandMode received enabled=\(self.commandModeEnabled, privacy: .public) isRecording=\(self.isRecording, privacy: .public)")
        guard commandModeEnabled else {
            statusText = "Command Mode disabled"
            isErrorState = true
            return
        }
        pendingStopTask?.cancel()
        pendingStopTask = nil
        guard !commandModeStarting && !isRecording && speechService == nil else { return }
        commandModeStarting = true
        Task {
            statusText = "Command Mode"
            await startRecording(mode: .command)
            commandModeStarting = false
            startCommandModeReleaseMonitor()
        }
    }

    private func stopCommandMode() {
        DiagnosticLog.hotKey.info("stopCommandMode received isRecording=\(self.isRecording, privacy: .public) speechServicePresent=\(self.speechService != nil, privacy: .public) starting=\(self.commandModeStarting, privacy: .public)")
        guard isRecording || speechService != nil else {
            return
        }
        scheduleStopRecording(shouldPaste: true, reason: "commandModeRelease")
    }

    private func startRecording(mode: RecordingMode) async {
        DiagnosticLog.app.info("startRecording begin")
        pendingStopTask?.cancel()
        pendingStopTask = nil
        recordingMode = mode
        resetError()
        latestTranscript = ""
        transcriptPreview = ""
        statusText = "Requesting permissions"

        let service = SpeechRecognitionService()
        speechService = service

        do {
            if muteMusicWhileDictating {
                mediaDuckingService.begin()
            }
            DiagnosticLog.audio.info("startRecording preferredInputDevice begin")
            let device = try audioInputDeviceService.preferredInputDevice()
            DiagnosticLog.audio.info("startRecording preferredInputDevice selected id=\(device.id, privacy: .public) name=\(device.name, privacy: .public)")
            audioInputText = "Audio Input: \(device.name)"
            statusText = "Using \(device.name)"
            DiagnosticLog.speech.info("startRecording requestPermissions begin")
            try await service.requestPermissions()
            DiagnosticLog.speech.info("startRecording requestPermissions success")
            guard speechService === service else { return }
            DiagnosticLog.speech.info("startRecording speechService.start begin")
            let contextualStrings = speechContextualStrings()
            try service.start(contextualStrings: contextualStrings) { [weak self, weak service] text in
                guard let self, self.speechService === service else {
                    DiagnosticLog.speech.info("transcript ignored staleService textLength=\(text.count, privacy: .public)")
                    return
                }
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    DiagnosticLog.speech.info("transcript ignored empty text")
                    return
                }
                self.latestTranscript = text
                self.transcriptPreview = Self.preview(from: text)
                self.statusText = "Listening..."
            }
            DiagnosticLog.speech.info("startRecording speechService.start success")
            guard speechService === service else {
                service.stop()
                return
            }
            isRecording = true
            if dictationNotificationSounds {
                dictationSoundService.playStart(
                    soundName: dictationStartSound,
                    volume: dictationNotificationVolume
                )
            }
            statusText = "Listening"
        } catch {
            mediaDuckingService.end()
            speechService = nil
            DiagnosticLog.app.error("startRecording failed error=\(error.localizedDescription, privacy: .public)")
            showError(error.localizedDescription)
        }
    }

    private func markReady() {
        if !isRecording {
            statusText = "Ready"
            isErrorState = false
        }
    }

    private func scheduleStopRecording(shouldPaste: Bool, reason: String) {
        DiagnosticLog.app.info("scheduleStopRecording reason=\(reason, privacy: .public) shouldPaste=\(shouldPaste, privacy: .public) textLength=\(self.latestTranscript.count, privacy: .public)")
        pendingStopTask?.cancel()
        statusText = "Finishing"
        pendingStopTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: self?.releaseTailDelayNanoseconds ?? 900_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self?.pendingStopTask = nil
                self?.stopRecording(shouldPaste: shouldPaste)
            }
        }
    }

    private func stopRecording(shouldPaste: Bool) {
        DiagnosticLog.app.info("stopRecording begin shouldPaste=\(shouldPaste, privacy: .public) textLength=\(self.latestTranscript.count, privacy: .public)")
        pendingStopTask?.cancel()
        pendingStopTask = nil
        guard isRecording || speechService != nil else { return }
        isRecording = false
        speechService?.stop()
        speechService = nil
        commandModeStarting = false
        commandModeReleaseMonitorTask?.cancel()
        commandModeReleaseMonitorTask = nil
        mediaDuckingService.end()
        if dictationNotificationSounds {
            dictationSoundService.playStop(
                soundName: dictationStopSound,
                volume: dictationNotificationVolume
            )
        }

        let rawText = latestTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        let text = processCapturedText(rawText)
        guard !text.isEmpty else {
            statusText = "No speech captured"
            transcriptPreview = ""
            return
        }
        lastCapturedTranscript = text
        DiagnosticLog.app.info("stopRecording captured rawLength=\(rawText.count, privacy: .public) textLength=\(text.count, privacy: .public) codingCommands=\(self.recognizeCodingCommands, privacy: .public)")

        statusText = shouldPaste ? "Pasting" : "Captured"
        if shouldPaste {
            Task {
                await finishCapturedText(text)
            }
        }
    }

    private func finishCapturedText(_ text: String) async {
        switch recordingMode {
        case .dictation:
            let parsed = Self.parsePressEnterCommand(text, enabled: pressEnterVoiceCommandEnabled)
            if !parsed.text.isEmpty {
                let result = await textInsertionService.insert(
                    parsed.text,
                    restoreClipboard: restoreClipboardAfterPaste
                )
                handleInsertResult(result)
            }
            if parsed.shouldPressEnter {
                _ = await textInsertionService.pressEnter()
                statusText = parsed.text.isEmpty ? "Pressed Enter" : statusText
            }
        case .command:
            statusText = "Command Mode processing"
            do {
                DiagnosticLog.app.info("commandMode captureSelectedText begin")
                let selectedText = await textInsertionService.captureSelectedText()
                let promptBuilderCommand = PromptBuilderCommandParser().parse(text)
                let transformed: String
                if promptBuilderEnabled && promptBuilderCommand.isPromptBuilderRequest {
                    statusText = "Prompt Builder processing"
                    DiagnosticLog.app.info("promptBuilder begin provider=\(self.commandModeProvider.rawValue, privacy: .public) model=\(self.commandModeModel, privacy: .public) selectedLength=\(selectedText.count, privacy: .public) commandLength=\(text.count, privacy: .public)")
                    let weightSummary = promptBuilderLocalWeightsEnabled
                        ? try? PromptModelWeightScanner().scan(roots: promptBuilderWeightRoots)
                        : nil
                    let imageReference: PromptBuilderImageReference?
                    if promptBuilderCommand.requestsClipboardImageReference {
                        imageReference = try clipboardImageReferenceService.imageReferenceFromClipboard()
                        DiagnosticLog.app.info("promptBuilder clipboardImage bytes=\(imageReference?.byteCount ?? 0, privacy: .public)")
                    } else {
                        imageReference = nil
                    }
                    let service = PromptBuilderService(
                        provider: commandModeProvider,
                        apiKey: commandModeAPIKey,
                        model: commandModeModel,
                        guideRoots: promptBuilderGuideRoots,
                        localWeightsEnabled: promptBuilderLocalWeightsEnabled,
                        weightSummary: weightSummary,
                        imageReference: imageReference
                    )
                    transformed = try await service.build(
                        selectedText: selectedText,
                        command: promptBuilderCommand
                    )
                } else {
                    DiagnosticLog.app.info("commandMode transform begin provider=\(self.commandModeProvider.rawValue, privacy: .public) model=\(self.commandModeModel, privacy: .public) selectedLength=\(selectedText.count, privacy: .public) commandLength=\(text.count, privacy: .public)")
                    let service = CommandTransformService(
                        provider: commandModeProvider,
                        apiKey: commandModeAPIKey,
                        model: commandModeModel
                    )
                    transformed = try await service.transform(
                        selectedText: selectedText,
                        command: text
                    )
                }
                guard !transformed.isEmpty else {
                    DiagnosticLog.app.info("commandMode transform empty")
                    statusText = "Command Mode returned no text"
                    isErrorState = true
                    return
                }
                DiagnosticLog.app.info("commandMode transform success outputLength=\(transformed.count, privacy: .public)")
                let result = await textInsertionService.insert(
                    transformed,
                    restoreClipboard: restoreClipboardAfterPaste
                )
                handleInsertResult(result)
            } catch {
                DiagnosticLog.app.error("commandMode failed provider=\(self.commandModeProvider.rawValue, privacy: .public) model=\(self.commandModeModel, privacy: .public)")
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                statusText = error.localizedDescription
                isErrorState = true
            }
        }
        recordingMode = .dictation
        latestTranscript = ""
        transcriptPreview = ""
    }

    private func startCommandModeReleaseMonitor() {
        guard case .command = recordingMode else { return }
        commandModeReleaseMonitorTask?.cancel()
        commandModeReleaseMonitorTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 300_000_000)
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000)
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self,
                          self.isRecording,
                          self.speechService != nil,
                          case .command = self.recordingMode else {
                        return
                    }
                    let flags = NSEvent.modifierFlags
                    let commandModeStillHeld = flags.contains(.command)
                        && flags.contains(.option)
                        && flags.contains(.control)
                    if !commandModeStillHeld {
                        DiagnosticLog.hotKey.info("commandMode releaseMonitor stop")
                        self.commandModeReleaseMonitorTask?.cancel()
                        self.commandModeReleaseMonitorTask = nil
                        self.scheduleStopRecording(shouldPaste: true, reason: "commandModeReleaseMonitor")
                    }
                }
            }
        }
    }

    private func processCapturedText(_ rawText: String) -> String {
        var text = rawText
        if smartFormattingEnabled, case .dictation = recordingMode {
            text = SmartFormattingProcessor.process(
                text,
                options: .init(
                    writingStyle: writingStyle,
                    backtrackEnabled: backtrackEnabled,
                    frontmostBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier
                )
            )
        }
        if recognizeCodingCommands {
            text = CodingCommandProcessor.process(text)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleInsertResult(_ result: TextInsertionService.InsertResult) {
        switch result {
        case .pasted:
            statusText = "Ready"
            isErrorState = false
        case .copiedAccessibilityRequired:
            statusText = "Copied. Enable Accessibility to paste."
            isErrorState = true
        case .failed:
            statusText = "Paste failed"
            isErrorState = true
        }
    }

    private func handleMemoryPressure(_ level: MemoryPressureLevel) {
        switch level {
        case .warning:
            if !isRecording {
                latestTranscript = ""
                transcriptPreview = ""
                speechService = nil
            }
            statusText = isRecording ? "Listening; memory pressure" : "Ready"
        case .critical:
            if isRecording {
                stopRecording(shouldPaste: pasteAutomatically)
            } else {
                latestTranscript = ""
                transcriptPreview = ""
                speechService = nil
            }
            statusText = "Memory pressure cleanup"
        }
    }

    private func showError(_ message: String) {
        DiagnosticLog.app.error("showError message=\(message, privacy: .public)")
        isRecording = false
        isErrorState = true
        statusText = message
    }

    private func resetError() {
        isErrorState = false
    }

    func previewNotificationSound(_ soundName: String) {
        guard dictationNotificationSounds else { return }
        dictationSoundService.preview(soundName: soundName, volume: dictationNotificationVolume)
    }

    private static func loadCommandModeAPIKey() -> String {
        let provider = CommandModeProvider(rawValue: UserDefaults.standard.string(forKey: "commandModeProvider") ?? "") ?? .off
        let keychainKey = KeychainService.loadAPIKey(for: provider)
        if !keychainKey.isEmpty {
            return keychainKey
        }

        let legacyKey = UserDefaults.standard.string(forKey: "commandModeAPIKey") ?? ""
        if !legacyKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            KeychainService.migrateLegacyOpenAIKey(legacyKey)
            UserDefaults.standard.removeObject(forKey: "commandModeAPIKey")
            if provider == .openAI {
                return legacyKey
            }
        }

        UserDefaults.standard.removeObject(forKey: "commandModeAPIKey")
        return ""
    }

    private func refreshPromptBuilderStatuses() {
        promptBuilderIndexStatus = promptBuilderGuideRoots.isEmpty
            ? "Guide index: No guide folders selected"
            : "Guide index: Ready to scan \(promptBuilderGuideRoots.count) folder(s)"
        let remoteRoot = PromptGuideRemoteSyncService.defaultCacheRoot()
        if FileManager.default.fileExists(atPath: remoteRoot.path) {
            promptBuilderRemoteStatus = "Remote guides: Cached"
        } else {
            promptBuilderRemoteStatus = "Remote guides: Not synced"
        }
        promptBuilderWeightStatus = promptBuilderWeightRoots.isEmpty
            ? "Local weights: No folders selected"
            : "Local weights: Ready to scan \(promptBuilderWeightRoots.count) folder(s)"
    }

    private func speechContextualStrings() -> [String] {
        var terms = customDictionaryTerms
        if recognizeCodingCommands {
            terms.append(contentsOf: CodingCommandProcessor.contextualTerms)
        }

        var seen = Set<String>()
        let uniqueTerms = terms.compactMap { term -> String? in
            let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            let key = trimmed.lowercased()
            guard seen.insert(key).inserted else { return nil }
            return trimmed
        }
        DiagnosticLog.speech.info("speechContextualStrings count=\(uniqueTerms.count, privacy: .public)")
        return uniqueTerms
    }

    private static func parseDictionaryTerms(_ value: String) -> [String] {
        value
            .components(separatedBy: CharacterSet(charactersIn: "\n,"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func parseFolderRoots(_ value: String) -> [URL] {
        value
            .components(separatedBy: CharacterSet(charactersIn: "\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .map { URL(fileURLWithPath: $0, isDirectory: true) }
    }

    private static func addFolder(_ path: String, to value: String) -> String {
        var paths = parseFolderRoots(value).map(\.path)
        guard !paths.contains(path) else { return value }
        paths.append(path)
        return paths.joined(separator: "\n")
    }

    private static func chooseFolder(title: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = title
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func parsePressEnterCommand(
        _ value: String,
        enabled: Bool
    ) -> (text: String, shouldPressEnter: Bool) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard enabled else { return (trimmed, false) }
        let pattern = #"(?i)(?:^|[ \t\r\n,;:\-]+)press[ \t\r\n]+enter[\s\p{P}]*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return (trimmed, false)
        }
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)
        guard let match = regex.firstMatch(in: trimmed, range: range),
              let commandRange = Range(match.range, in: trimmed) else {
            return (trimmed, false)
        }
        var text = trimmed
        text.removeSubrange(commandRange)
        return (text.trimmingCharacters(in: .whitespacesAndNewlines), true)
    }

    private static func preview(from text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 220 else { return trimmed }
        return String(trimmed.suffix(220))
    }
}
