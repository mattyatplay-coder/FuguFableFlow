import Foundation

enum PromptBuilderModality: String, CaseIterable, Sendable {
    case image
    case video
    case speech
    case music
}

enum PromptBuilderTask: String, CaseIterable, Sendable {
    case textToImage
    case imageEditing
    case textToVideo
    case imageToVideo
    case videoEditing
    case textToMusic
    case textToSpeech
    case speechToText
    case generic

    var displayName: String {
        switch self {
        case .textToImage: "Text to Image"
        case .imageEditing: "Image Editing"
        case .textToVideo: "Text to Video"
        case .imageToVideo: "Image to Video"
        case .videoEditing: "Video Editing"
        case .textToMusic: "Text to Music"
        case .textToSpeech: "Text to Speech"
        case .speechToText: "Speech to Text"
        case .generic: "Generic Prompt"
        }
    }
}

struct PromptBuilderModelProfile: Equatable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let aliases: [String]
    let modalities: [PromptBuilderModality]
    let guidePathHints: [String]
    let isOpenWeights: Bool
    let priority: Int
}

struct PromptBuilderCommand: Equatable, Sendable {
    let originalCommand: String
    let targetModel: PromptBuilderModelProfile?
    let task: PromptBuilderTask
    let intent: String

    var isPromptBuilderRequest: Bool {
        let normalized = PromptBuilderModelRegistry.normalized(originalCommand)
        return targetModel != nil
            || task != .generic
            || normalized.contains("prompt")
            || normalized.contains("image to video")
            || normalized.contains("text to image")
            || normalized.contains("text to video")
            || normalized.contains("music brief")
    }

    var requestsClipboardImageReference: Bool {
        let normalized = PromptBuilderModelRegistry.normalized(originalCommand)
        let phrases = [
            "clipboard image",
            "copied image",
            "reference image",
            "image reference",
            "using the image",
            "use the image",
            "using this image",
            "use this image",
            "using the screenshot",
            "use the screenshot",
            "using clipboard",
            "from clipboard"
        ]
        return phrases.contains { normalized.contains($0) }
    }
}

struct PromptGuideSearchResult: Equatable, Sendable {
    let fileURL: URL
    let score: Int
    let snippet: String
}

struct PromptGuideIndexSummary: Equatable, Sendable {
    let roots: [String]
    let fileCount: Int
    let totalBytes: Int
    let skippedLargeFiles: Int
    let scannedAt: Date

    var displayText: String {
        guard !roots.isEmpty else { return "No guide folders selected" }
        return "\(fileCount) guide files, \(ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)) indexed"
    }
}

struct PromptBuilderImageReference: Equatable, Sendable {
    let mimeType: String
    let base64Data: String
    let width: Int
    let height: Int
    let byteCount: Int

    var dataURL: String {
        "data:\(mimeType);base64,\(base64Data)"
    }

    var displayText: String {
        "\(width)x\(height), \(ByteCountFormatter.string(fromByteCount: Int64(byteCount), countStyle: .file))"
    }
}

struct PromptModelWeightSummary: Equatable, Sendable {
    let roots: [String]
    let fileCount: Int
    let totalBytes: Int
    let extensions: [String]
    let scannedAt: Date

    var displayText: String {
        guard !roots.isEmpty else { return "No model weight folders selected" }
        guard fileCount > 0 else { return "No local model weight files found" }
        return "\(fileCount) weight files, \(ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)) referenced"
    }
}
