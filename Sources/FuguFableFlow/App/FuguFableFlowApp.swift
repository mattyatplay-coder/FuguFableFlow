import SwiftUI
import AppKit

@main
struct FuguFableFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var dictationStore = DictationStore()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(dictationStore)
        } label: {
            menuBarLabel
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(dictationStore)
        }
    }

    @ViewBuilder
    private var menuBarLabel: some View {
        if let image = MenuBarLogo.image {
            ZStack(alignment: .bottomTrailing) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .frame(width: 18, height: 18)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                if dictationStore.isRecording {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                        .overlay(
                            Circle()
                                .stroke(.black.opacity(0.45), lineWidth: 0.5)
                        )
                        .offset(x: 1, y: 1)
                }
            }
            .accessibilityLabel(dictationStore.isRecording ? "FuguFableFlow recording" : "FuguFableFlow")
        } else {
            Label("FuguFableFlow", systemImage: dictationStore.menuBarIcon)
        }
    }
}

private enum MenuBarLogo {
    static let image: NSImage? = {
        guard let url = Bundle.main.url(forResource: "FuguFableFlow", withExtension: "png"),
              let image = NSImage(contentsOf: url) else {
            return nil
        }
        image.isTemplate = false
        image.size = NSSize(width: 18, height: 18)
        return image
    }()
}
