import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: DictationStore
    @State private var draftMode = DictationShortcutMode.rightFunctionRightCommandPushToTalk
    @State private var draftKeyCode = HotKeyShortcut.defaultDictation.keyCode
    @State private var draftModifiers = HotKeyShortcut.defaultDictation.modifiers

    private var draftShortcut: HotKeyShortcut {
        HotKeyShortcut(keyCode: draftKeyCode, modifiers: draftModifiers)
    }

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $store.pasteAutomatically) {
                    Label("Paste on Stop", systemImage: "doc.on.clipboard")
                }

                Toggle(isOn: $store.restoreClipboardAfterPaste) {
                    Label("Restore Clipboard", systemImage: "clipboard")
                }
            } header: {
                Text("Paste Behavior")
            } footer: {
                Text("When paste is blocked by macOS, FuguFableFlow keeps the latest transcript on the clipboard.")
            }

            Section {
                Toggle(isOn: $store.muteMusicWhileDictating) {
                    Label("Mute Music While Dictating", systemImage: "speaker.slash")
                }

                Toggle(isOn: $store.dictationNotificationSounds) {
                    Label("Dictation and Notification Sounds", systemImage: "speaker.wave.2")
                }

                HStack {
                    Picker("Start Sound", selection: $store.dictationStartSound) {
                        ForEach(NotificationSoundOption.allCases) { sound in
                            Text(sound.displayName).tag(sound.rawValue)
                        }
                    }

                    Button("Preview") {
                        store.previewNotificationSound(store.dictationStartSound)
                    }
                }
                .disabled(!store.dictationNotificationSounds)

                HStack {
                    Picker("Stop Sound", selection: $store.dictationStopSound) {
                        ForEach(NotificationSoundOption.allCases) { sound in
                            Text(sound.displayName).tag(sound.rawValue)
                        }
                    }

                    Button("Preview") {
                        store.previewNotificationSound(store.dictationStopSound)
                    }
                    .disabled(!store.dictationNotificationSounds)
                }
                .disabled(!store.dictationNotificationSounds)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Notification Volume")
                        Spacer()
                        Text("\(Int(store.dictationNotificationVolume * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $store.dictationNotificationVolume, in: 0...1)
                        .disabled(!store.dictationNotificationSounds)
                }
            } header: {
                Text("Audio Feedback")
            } footer: {
                Text("Music muting pauses Music, Spotify, and Spotify tabs in Chrome when JavaScript from Apple Events is enabled. It also attempts system-output mute, though some USB interfaces do not expose software mute.")
            }

            Section {
                Toggle(isOn: $store.smartFormattingEnabled) {
                    Label("Smart Formatting", systemImage: "textformat")
                }

                Picker("Writing Style", selection: writingStyleBinding) {
                    ForEach(WritingStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }

                Toggle(isOn: $store.backtrackEnabled) {
                    Label("Backtrack", systemImage: "arrow.uturn.backward")
                }
            } header: {
                Text("Smart Formatting")
            } footer: {
                Text("Converts spoken punctuation and line breaks, cleans simple false starts, formats short lists, and adjusts trailing periods based on writing style.")
            }

            Section {
                Toggle(isOn: $store.recognizeCodingCommands) {
                    Label("Recognize Coding Commands", systemImage: "chevron.left.forwardslash.chevron.right")
                }

                Toggle(isOn: $store.pressEnterVoiceCommandEnabled) {
                    Label("Press Enter Voice Command", systemImage: "return")
                }
            } header: {
                Text("Coding")
            } footer: {
                Text("Improves recognition of coding terms and converts spoken commands like new line, open parenthesis, fat arrow, and press enter.")
            }

            Section {
                Toggle(isOn: $store.commandModeEnabled) {
                    Label("Command Mode", systemImage: "wand.and.stars")
                }

                Text(store.commandModeShortcutDescription)
                    .foregroundStyle(.secondary)

                Picker("Provider", selection: commandModeProviderBinding) {
                    ForEach(CommandModeProvider.allCases) { provider in
                        Text(provider.displayName).tag(provider)
                    }
                }

                Text(store.commandModeProvider.detail)
                    .foregroundStyle(.secondary)

                if store.commandModeProvider != .off {
                    TextField(store.commandModeProvider.modelLabel, text: $store.commandModeModel)
                        .textFieldStyle(.roundedBorder)
                }

                if store.commandModeProvider.requiresAPIKey {
                    SecureField(store.commandModeProvider.apiKeyLabel, text: $store.commandModeAPIKey)
                        .textFieldStyle(.roundedBorder)
                }
            } header: {
                Text("Command Mode")
            } footer: {
                Text("Highlight text, hold the shortcut, speak an instruction, then release. Hosted providers receive the selected text and spoken command. Local Ollama stays on device but uses external model memory.")
            }

            Section {
                Toggle(isOn: $store.promptBuilderEnabled) {
                    Label("Model-Aware Prompt Builder", systemImage: "sparkles.rectangle.stack")
                }

                Text("Uses Command Mode when the spoken instruction looks like a prompt-building request.")
                    .foregroundStyle(.secondary)

                Toggle(isOn: $store.promptBuilderIndexOnLaunch) {
                    Label("Index Guide Metadata on Launch", systemImage: "list.bullet.rectangle")
                }

                TextEditor(text: $store.promptBuilderGuideRootsText)
                    .font(.body.monospaced())
                    .frame(minHeight: 72)

                HStack {
                    Button {
                        store.addPromptGuideFolder()
                    } label: {
                        Label("Add Guide Folder", systemImage: "folder.badge.plus")
                    }

                    Button {
                        store.rebuildPromptGuideIndex()
                    } label: {
                        Label("Rebuild Index", systemImage: "arrow.clockwise")
                    }

                    Spacer()

                    Button("Clear") {
                        store.clearPromptGuideFolders()
                    }
                }

                Text(store.promptBuilderIndexStatus)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Prompt Builder")
            } footer: {
                Text("Guide indexing stores only lightweight file metadata. Prompt Builder reads capped text snippets on demand and skips media files and oversized documents.")
            }

            Section {
                Toggle(isOn: $store.promptBuilderLocalWeightsEnabled) {
                    Label("Reference Local Model Weights", systemImage: "externaldrive")
                }

                TextEditor(text: $store.promptBuilderWeightRootsText)
                    .font(.body.monospaced())
                    .frame(minHeight: 64)
                    .disabled(!store.promptBuilderLocalWeightsEnabled)

                HStack {
                    Button {
                        store.addModelWeightFolder()
                    } label: {
                        Label("Add Weight Folder", systemImage: "folder.badge.plus")
                    }
                    .disabled(!store.promptBuilderLocalWeightsEnabled)

                    Button {
                        store.scanLocalModelWeights()
                    } label: {
                        Label("Scan Filenames", systemImage: "magnifyingglass")
                    }
                    .disabled(!store.promptBuilderLocalWeightsEnabled)

                    Spacer()

                    Button("Clear") {
                        store.clearModelWeightFolders()
                    }
                }

                Text(store.promptBuilderWeightStatus)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Local Model Weights")
            } footer: {
                Text("FuguFableFlow never loads model weights. This only references local GGUF, safetensors, Core ML, or ONNX files so Prompt Builder can mention what you have available. Running local models remains external, for example through Ollama.")
            }

            Section {
                TextEditor(text: $store.customDictionaryText)
                    .font(.body.monospaced())
                    .frame(minHeight: 96)

                Text("\(store.customDictionaryTerms.count) custom terms")
                    .foregroundStyle(.secondary)
            } header: {
                Text("Dictionary")
            } footer: {
                Text("Add names, project terms, libraries, commands, or unusual words. Separate entries with commas or new lines.")
            }

            Section {
                Picker("Shortcut", selection: $draftMode) {
                    ForEach(DictationShortcutMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Text(draftMode.detail)
                    .foregroundStyle(.secondary)

                if draftMode == .customToggle {
                    Divider()

                Picker("Key", selection: $draftKeyCode) {
                    ForEach(HotKeyKeyOption.supported) { option in
                        Text(option.displayName).tag(option.keyCode)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Modifiers")
                        .foregroundStyle(.secondary)
                    HStack {
                        ForEach(HotKeyModifierOption.allCases) { option in
                            Toggle(option.displayName, isOn: modifierBinding(for: option))
                                .toggleStyle(.checkbox)
                        }
                    }
                }
                }
            } header: {
                Text("Dictation Shortcut")
            } footer: {
                Text("Current: \(store.dictationShortcutDescription)")
            }

            if let validationMessage = draftShortcut.validationMessage {
                Text(validationMessage)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Reset to Default") {
                    store.resetDictationShortcut()
                    loadCurrentShortcut()
                }

                Spacer()

                Button("Apply") {
                    if draftMode == .rightFunctionRightCommandPushToTalk {
                        store.updateShortcutMode(.rightFunctionRightCommandPushToTalk)
                    } else if draftMode == .rightCommandPushToTalk {
                        store.updateShortcutMode(.rightCommandPushToTalk)
                    } else {
                        store.updateDictationShortcut(draftShortcut)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(applyDisabled)
            }

            Section {
                Button {
                    store.requestAccessibilityPermission()
                } label: {
                    Label("Accessibility Permission", systemImage: "figure.wave")
                }

                Button {
                    store.requestMicrophonePermission()
                } label: {
                    Label("Microphone Permission", systemImage: "mic")
                }
            } header: {
                Text("Permissions")
            }

            Section {
                Text(store.audioInputText)
                    .foregroundStyle(.secondary)

                Button {
                    store.usePreferredMicrophone()
                } label: {
                    Label("Use Best Available Microphone", systemImage: "mic.and.signal.meter")
                }
            } header: {
                Text("Audio Input")
            }

            Section {
                Button {
                    store.copyLastTranscript()
                } label: {
                    Label("Copy Last Transcript", systemImage: "doc.on.doc")
                }

                if !store.transcriptPreview.isEmpty {
                    Text(store.transcriptPreview)
                        .lineLimit(4)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Transcript")
            }
        }
        .formStyle(.grouped)
        .padding(24)
        .frame(width: 500)
        .onAppear(perform: loadCurrentShortcut)
    }

    private func loadCurrentShortcut() {
        draftMode = store.dictationShortcutMode
        draftKeyCode = store.dictationShortcut.keyCode
        draftModifiers = store.dictationShortcut.modifiers
    }

    private var applyDisabled: Bool {
        if draftMode == .rightFunctionRightCommandPushToTalk || draftMode == .rightCommandPushToTalk {
            return store.dictationShortcutMode == draftMode
        }
        return draftShortcut.validationMessage != nil
            || (store.dictationShortcutMode == .customToggle && draftShortcut == store.dictationShortcut)
    }

    private func modifierBinding(for option: HotKeyModifierOption) -> Binding<Bool> {
        Binding {
            draftModifiers & option.carbonValue != 0
        } set: { isOn in
            if isOn {
                draftModifiers |= option.carbonValue
            } else {
                draftModifiers &= ~option.carbonValue
            }
        }
    }

    private var writingStyleBinding: Binding<WritingStyle> {
        Binding {
            store.writingStyle
        } set: { style in
            store.writingStyle = style
        }
    }

    private var commandModeProviderBinding: Binding<CommandModeProvider> {
        Binding {
            store.commandModeProvider
        } set: { provider in
            store.commandModeProvider = provider
        }
    }
}
