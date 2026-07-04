import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var store: DictationStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                store.toggleRecording()
            } label: {
                Label(store.primaryActionTitle, systemImage: store.isRecording ? "stop.circle.fill" : "mic.circle.fill")
            }

            Text(store.dictationShortcutDescription)
                .lineLimit(1)
                .foregroundStyle(.secondary)

            Text(store.audioInputText)
                .lineLimit(1)
                .foregroundStyle(.secondary)

            if !store.transcriptPreview.isEmpty {
                Divider()
                Text(store.transcriptPreview)
                    .lineLimit(4)
                    .frame(maxWidth: 280, alignment: .leading)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button {
                openSettings()
                bringSettingsToFront()
            } label: {
                Label("Settings", systemImage: "gearshape")
            }

            Divider()

            Text(store.statusText)
                .lineLimit(2)
                .frame(maxWidth: 280, alignment: .leading)
                .foregroundStyle(store.isErrorState ? .red : .secondary)

            Button {
                NSApp.terminate(nil)
            } label: {
                Label("Quit", systemImage: "power")
            }
            .keyboardShortcut("q")
        }
        .padding(.vertical, 4)
    }

    private func bringSettingsToFront() {
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSApp.activate(ignoringOtherApps: true)
            let settingsWindow = NSApp.windows.first { window in
                window.identifier?.rawValue == "com.apple.SwiftUI.Settings" ||
                    window.title.localizedCaseInsensitiveContains("settings")
            }
            settingsWindow?.makeKeyAndOrderFront(nil)
        }
    }
}
