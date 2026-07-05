import Foundation

struct PromptBuilderCommandParser: Sendable {
    let registry: PromptBuilderModelRegistry

    init(registry: PromptBuilderModelRegistry = PromptBuilderModelRegistry()) {
        self.registry = registry
    }

    func parse(_ command: String) -> PromptBuilderCommand {
        let normalized = PromptBuilderModelRegistry.normalized(command)
        let model = registry.resolveModel(in: command)
        return PromptBuilderCommand(
            originalCommand: command,
            targetModel: model,
            task: Self.inferTask(from: normalized),
            intent: command.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func inferTask(from normalizedCommand: String) -> PromptBuilderTask {
        if containsAny(["image to video", "image into video", "i2v", "animate this image", "animate the image"], in: normalizedCommand) {
            return .imageToVideo
        }
        if containsAny(["text to video", "t2v", "video prompt", "generate a video"], in: normalizedCommand) {
            return .textToVideo
        }
        if containsAny(["video edit", "edit video", "retake", "extend video"], in: normalizedCommand) {
            return .videoEditing
        }
        if containsAny(["image edit", "edit image", "inpaint", "outpaint", "replace background"], in: normalizedCommand) {
            return .imageEditing
        }
        if containsAny(["text to image", "t2i", "image prompt", "generate an image"], in: normalizedCommand) {
            return .textToImage
        }
        if containsAny(["text to speech", "tts", "voiceover", "voice over", "narration"], in: normalizedCommand) {
            return .textToSpeech
        }
        if containsAny(["speech to text", "stt", "asr", "transcribe"], in: normalizedCommand) {
            return .speechToText
        }
        if containsAny(["music", "song", "soundtrack", "score", "instrumental", "vocals"], in: normalizedCommand) {
            return .textToMusic
        }
        return .generic
    }

    private static func containsAny(_ phrases: [String], in text: String) -> Bool {
        phrases.contains { phrase in
            let normalizedPhrase = PromptBuilderModelRegistry.normalized(phrase)
            return text == normalizedPhrase
                || text.hasPrefix("\(normalizedPhrase) ")
                || text.hasSuffix(" \(normalizedPhrase)")
                || text.contains(" \(normalizedPhrase) ")
        }
    }
}
