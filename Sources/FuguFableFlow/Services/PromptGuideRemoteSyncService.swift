import Foundation

struct PromptGuideRemoteSyncSummary: Equatable, Sendable {
    let repo: String
    let guideCount: Int
    let cacheRoot: URL

    var displayText: String {
        "Remote guides: \(guideCount) synced from \(repo)"
    }
}

struct PromptGuideRemoteSyncService {
    struct Manifest: Decodable {
        struct Guide: Decodable {
            let id: String
            let path: String
            let bytes: Int
            let sha256: String
        }

        let guides: [Guide]
    }

    enum SyncError: LocalizedError {
        case missingRepo
        case invalidRepo(String)
        case invalidResponse(String)

        var errorDescription: String? {
            switch self {
            case .missingRepo:
                "Add a Hugging Face Dataset repo ID first."
            case .invalidRepo(let repo):
                "Invalid Hugging Face repo ID: \(repo)"
            case .invalidResponse(let message):
                message
            }
        }
    }

    let urlSession: URLSession
    let fileManager: FileManager

    init(urlSession: URLSession = .shared, fileManager: FileManager = .default) {
        self.urlSession = urlSession
        self.fileManager = fileManager
    }

    func sync(repo: String, cacheRoot: URL = Self.defaultCacheRoot()) async throws -> PromptGuideRemoteSyncSummary {
        let trimmedRepo = repo.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRepo.isEmpty else { throw SyncError.missingRepo }
        let manifestLocation = try await fetchManifest(repo: trimmedRepo)
        let manifestData = manifestLocation.data
        let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)

        let stagingRoot = cacheRoot
            .deletingLastPathComponent()
            .appendingPathComponent("remote-staging-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: stagingRoot, withIntermediateDirectories: true)

        do {
            for guide in manifest.guides {
                let remotePath = Self.joinPath(manifestLocation.basePath, guide.path)
                guard let guideURL = Self.huggingFaceURL(repo: trimmedRepo, path: remotePath) else {
                    throw SyncError.invalidResponse("Invalid guide path in manifest: \(guide.path)")
                }
                let data = try await data(from: guideURL)
                if data.count != guide.bytes {
                    throw SyncError.invalidResponse("Downloaded \(guide.id) size did not match manifest.")
                }
                let destination = stagingRoot.appendingPathComponent(guide.path)
                try fileManager.createDirectory(
                    at: destination.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try data.write(to: destination, options: .atomic)
            }

            if fileManager.fileExists(atPath: cacheRoot.path) {
                try fileManager.removeItem(at: cacheRoot)
            }
            try fileManager.moveItem(at: stagingRoot, to: cacheRoot)
        } catch {
            try? fileManager.removeItem(at: stagingRoot)
            throw error
        }

        return PromptGuideRemoteSyncSummary(
            repo: trimmedRepo,
            guideCount: manifest.guides.count,
            cacheRoot: cacheRoot
        )
    }

    static func defaultCacheRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support", isDirectory: true)
        return base
            .appendingPathComponent("FuguFableFlow", isDirectory: true)
            .appendingPathComponent("PromptGuides", isDirectory: true)
            .appendingPathComponent("remote", isDirectory: true)
    }

    private static func huggingFaceURL(repo: String, path: String) -> URL? {
        var allowedPath = CharacterSet.urlPathAllowed
        allowedPath.remove(charactersIn: "#?")
        guard let encodedPath = path.addingPercentEncoding(withAllowedCharacters: allowedPath) else {
            return nil
        }
        return URL(string: "https://huggingface.co/datasets/\(repo)/resolve/main/\(encodedPath)?download=1")
    }

    private func fetchManifest(repo: String) async throws -> (data: Data, basePath: String) {
        let candidates = ["manifest.json", "prompt-guides/manifest.json"]
        var lastError: Error?
        for path in candidates {
            guard let url = Self.huggingFaceURL(repo: repo, path: path) else { continue }
            do {
                return (try await data(from: url), Self.basePath(for: path))
            } catch {
                lastError = error
            }
        }
        if let lastError {
            throw lastError
        }
        throw SyncError.invalidRepo(repo)
    }

    private static func joinPath(_ basePath: String, _ relativePath: String) -> String {
        let trimmedBase = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/."))
        let trimmedRelative = relativePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !trimmedBase.isEmpty else { return trimmedRelative }
        return "\(trimmedBase)/\(trimmedRelative)"
    }

    private static func basePath(for path: String) -> String {
        guard let slashIndex = path.lastIndex(of: "/") else { return "" }
        return String(path[..<slashIndex])
    }

    private func data(from url: URL) async throws -> Data {
        let (data, response) = try await urlSession.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            throw SyncError.invalidResponse("Hugging Face returned HTTP \(status) for \(url.lastPathComponent).")
        }
        return data
    }
}
