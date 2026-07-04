import Dispatch
import Foundation

enum MemoryPressureLevel {
    case warning
    case critical
}

@MainActor
final class MemoryPressureMonitor {
    private var source: DispatchSourceMemoryPressure?
    private let handler: (MemoryPressureLevel) -> Void

    init(handler: @escaping (MemoryPressureLevel) -> Void) {
        self.handler = handler
        let queue = DispatchQueue(label: "app.fugufableflow.memory-pressure")
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: queue
        )
        source.setEventHandler { [weak self, weak source] in
            guard let event = source?.data else { return }
            let level: MemoryPressureLevel = event.contains(.critical) ? .critical : .warning
            Task { @MainActor in
                self?.handler(level)
            }
        }
        source.resume()
        self.source = source
    }

    deinit {
        source?.cancel()
    }
}
