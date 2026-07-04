import AppKit
import Foundation

@MainActor
final class MediaDuckingService {
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

    func begin() {
        pausedApps.removeAll()
        for app in MediaApp.allCases where isRunning(bundleIdentifier: app.rawValue) {
            if runAppleScript(app.pauseScript) == "paused" {
                pausedApps.insert(app)
                DiagnosticLog.media.info("paused media app=\(app.displayName, privacy: .public)")
            }
        }
    }

    func end() {
        for app in pausedApps where isRunning(bundleIdentifier: app.rawValue) {
            _ = runAppleScript(app.resumeScript)
            DiagnosticLog.media.info("resumed media app=\(app.displayName, privacy: .public)")
        }
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
}
