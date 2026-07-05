import Foundation

struct PromptGuideIndexConfiguration: Sendable {
    var maxFileBytes = 128 * 1024
    var maxFilesScanned = 2_000
    var allowedExtensions: Set<String> = ["md", "markdown", "txt", "json"]
}

struct PromptGuideIndexService {
    let configuration: PromptGuideIndexConfiguration
    private let fileManager: FileManager

    init(
        configuration: PromptGuideIndexConfiguration = PromptGuideIndexConfiguration(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }

    func index(roots: [URL]) throws -> PromptGuideIndexSummary {
        var fileCount = 0
        var totalBytes = 0
        var skippedLargeFiles = 0

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
                guard configuration.allowedExtensions.contains(fileURL.pathExtension.lowercased()) else { continue }
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                guard values.isRegularFile == true else { continue }
                let size = values.fileSize ?? 0
                guard size > 0 else { continue }
                guard size <= configuration.maxFileBytes else {
                    skippedLargeFiles += 1
                    continue
                }
                fileCount += 1
                totalBytes += size
            }
        }

        return PromptGuideIndexSummary(
            roots: roots.map(\.path),
            fileCount: fileCount,
            totalBytes: totalBytes,
            skippedLargeFiles: skippedLargeFiles,
            scannedAt: Date()
        )
    }
}
