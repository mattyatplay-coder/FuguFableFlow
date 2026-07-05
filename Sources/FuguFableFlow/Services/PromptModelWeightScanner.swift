import Foundation

struct PromptModelWeightScannerConfiguration: Sendable {
    var maxFilesScanned = 1_000
    var allowedExtensions: Set<String> = ["gguf", "safetensors", "mlmodel", "mlmodelc", "onnx"]
}

struct PromptModelWeightScanner {
    let configuration: PromptModelWeightScannerConfiguration
    private let fileManager: FileManager

    init(
        configuration: PromptModelWeightScannerConfiguration = PromptModelWeightScannerConfiguration(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }

    func scan(roots: [URL]) throws -> PromptModelWeightSummary {
        var fileCount = 0
        var totalBytes = 0
        var extensions = Set<String>()

        for root in roots where fileCount < configuration.maxFilesScanned {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                guard fileCount < configuration.maxFilesScanned else { break }
                let fileExtension = fileURL.pathExtension.lowercased()
                guard configuration.allowedExtensions.contains(fileExtension) else { continue }
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                guard values.isRegularFile == true || fileExtension == "mlmodelc" else { continue }
                fileCount += 1
                totalBytes += values.fileSize ?? 0
                extensions.insert(fileExtension)
            }
        }

        return PromptModelWeightSummary(
            roots: roots.map(\.path),
            fileCount: fileCount,
            totalBytes: totalBytes,
            extensions: extensions.sorted(),
            scannedAt: Date()
        )
    }
}
