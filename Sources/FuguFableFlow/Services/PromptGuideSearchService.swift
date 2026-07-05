import Foundation

struct PromptGuideSearchConfiguration: Sendable {
    var maxFileBytes = 64 * 1024
    var maxTotalBytes = 256 * 1024
    var maxFilesScanned = 500
    var maxResults = 5
    var maxSnippetCharacters = 700
    var allowedExtensions: Set<String> = ["md", "markdown", "txt", "json"]
}

struct PromptGuideSearchService {
    let configuration: PromptGuideSearchConfiguration
    private let fileManager: FileManager

    init(
        configuration: PromptGuideSearchConfiguration = PromptGuideSearchConfiguration(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }

    func search(roots: [URL], command: PromptBuilderCommand) throws -> [PromptGuideSearchResult] {
        let queryTerms = Self.queryTerms(for: command)
        guard !queryTerms.isEmpty else { return [] }

        var results: [PromptGuideSearchResult] = []
        var scannedFiles = 0
        var totalBytesRead = 0

        for root in roots where scannedFiles < configuration.maxFilesScanned && totalBytesRead < configuration.maxTotalBytes {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                guard scannedFiles < configuration.maxFilesScanned,
                      totalBytesRead < configuration.maxTotalBytes else {
                    break
                }
                guard shouldInspect(fileURL) else { continue }
                let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                guard values.isRegularFile == true else { continue }
                let fileSize = values.fileSize ?? 0
                guard fileSize > 0, fileSize <= configuration.maxFileBytes else { continue }
                guard totalBytesRead + fileSize <= configuration.maxTotalBytes else { break }

                scannedFiles += 1
                let data = try Data(contentsOf: fileURL)
                totalBytesRead += data.count
                guard let contents = String(data: data, encoding: .utf8) else { continue }
                let score = Self.score(fileURL: fileURL, contents: contents, terms: queryTerms, command: command)
                guard score > 0 else { continue }
                results.append(
                    PromptGuideSearchResult(
                        fileURL: fileURL,
                        score: score,
                        snippet: Self.snippet(from: contents, terms: queryTerms, maxCharacters: configuration.maxSnippetCharacters)
                    )
                )
            }
        }

        return results
            .sorted { lhs, rhs in
                if lhs.score == rhs.score {
                    lhs.fileURL.path < rhs.fileURL.path
                } else {
                    lhs.score > rhs.score
                }
            }
            .prefix(configuration.maxResults)
            .map { $0 }
    }

    private func shouldInspect(_ fileURL: URL) -> Bool {
        let ext = fileURL.pathExtension.lowercased()
        guard configuration.allowedExtensions.contains(ext) else { return false }
        let filename = fileURL.lastPathComponent
        return !filename.hasPrefix(".") && !filename.hasPrefix("._")
    }

    private static func queryTerms(for command: PromptBuilderCommand) -> [String] {
        var terms: [String] = []
        if let model = command.targetModel {
            terms.append(model.displayName)
            terms.append(model.id)
            terms.append(contentsOf: model.aliases)
            terms.append(contentsOf: model.guidePathHints)
        }
        terms.append(command.task.displayName)
        terms.append(command.originalCommand)
        return uniqueTerms(from: terms)
    }

    private static func uniqueTerms(from strings: [String]) -> [String] {
        let stopWords: Set<String> = ["the", "this", "that", "into", "turn", "make", "for", "with", "and", "prompt", "strong"]
        var seen = Set<String>()
        return strings
            .flatMap { PromptBuilderModelRegistry.normalized($0).split(separator: " ").map(String.init) }
            .filter { $0.count > 2 && !stopWords.contains($0) }
            .filter { seen.insert($0).inserted }
    }

    private static func score(
        fileURL: URL,
        contents: String,
        terms: [String],
        command: PromptBuilderCommand
    ) -> Int {
        let normalizedPath = PromptBuilderModelRegistry.normalized(fileURL.path)
        let normalizedContents = PromptBuilderModelRegistry.normalized(contents)
        var score = 0

        for term in terms {
            if normalizedPath.contains(term) {
                score += 3
            }
            if normalizedContents.contains(term) {
                score += 1
            }
        }

        if let model = command.targetModel {
            for hint in model.guidePathHints where normalizedPath.contains(PromptBuilderModelRegistry.normalized(hint)) {
                score += 5
            }
        }
        return score
    }

    private static func snippet(from contents: String, terms: [String], maxCharacters: Int) -> String {
        let normalizedContents = PromptBuilderModelRegistry.normalized(contents)
        let firstMatch = terms.compactMap { term -> String.Index? in
            normalizedContents.range(of: term)?.lowerBound
        }.min()

        guard let firstMatch else {
            return String(contents.prefix(maxCharacters)).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let offset = normalizedContents.distance(from: normalizedContents.startIndex, to: firstMatch)
        let startOffset = max(0, offset - maxCharacters / 3)
        let endOffset = min(contents.count, startOffset + maxCharacters)
        let start = contents.index(contents.startIndex, offsetBy: startOffset)
        let end = contents.index(contents.startIndex, offsetBy: endOffset)
        return String(contents[start..<end]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
