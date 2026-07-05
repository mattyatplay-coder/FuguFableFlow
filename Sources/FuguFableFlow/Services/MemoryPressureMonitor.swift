import Dispatch
import Foundation

enum MemoryPressureLevel {
    case warning
    case critical
}

final class MemoryPressureMonitor {
    private var source: DispatchSourceMemoryPressure?
    private let handler: @MainActor @Sendable (MemoryPressureLevel) -> Void

    init(handler: @escaping @MainActor @Sendable (MemoryPressureLevel) -> Void) {
        self.handler = handler
        let queue = DispatchQueue(label: "app.fugufableflow.memory-pressure")
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: queue
        )
        source.setEventHandler { [weak source, handler] in
            guard let event = source?.data else { return }
            let level: MemoryPressureLevel = event.contains(.critical) ? .critical : .warning
            Task { @MainActor in
                handler(level)
            }
        }
        source.resume()
        self.source = source
    }

    deinit {
        source?.cancel()
    }
}
