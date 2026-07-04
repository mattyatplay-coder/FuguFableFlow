import OSLog

enum DiagnosticLog {
    static let app = Logger(subsystem: "app.fugufableflow.local", category: "app")
    static let audio = Logger(subsystem: "app.fugufableflow.local", category: "audio")
    static let hotKey = Logger(subsystem: "app.fugufableflow.local", category: "hotkey")
    static let insertion = Logger(subsystem: "app.fugufableflow.local", category: "insertion")
    static let media = Logger(subsystem: "app.fugufableflow.local", category: "media")
    static let speech = Logger(subsystem: "app.fugufableflow.local", category: "speech")
}
