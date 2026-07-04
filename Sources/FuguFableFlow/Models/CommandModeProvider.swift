import Foundation

enum CommandModeProvider: String, CaseIterable, Identifiable {
    case off
    case openRouter
    case huggingFace
    case openAI
    case ollama

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .off:
            "Off"
        case .openRouter:
            "OpenRouter"
        case .huggingFace:
            "Hugging Face"
        case .openAI:
            "OpenAI"
        case .ollama:
            "Local Ollama"
        }
    }

    var detail: String {
        switch self {
        case .off:
            "Command Mode will not send text to an AI provider."
        case .openRouter:
            "Uses OpenRouter's hosted API. Good for low-cost and free model routing."
        case .huggingFace:
            "Uses Hugging Face Inference Providers through its OpenAI-compatible router."
        case .openAI:
            "Uses OpenAI's hosted chat completions API."
        case .ollama:
            "Uses an already-running local Ollama server. Private, but model memory is outside this app."
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .off, .ollama:
            false
        case .openRouter, .huggingFace, .openAI:
            true
        }
    }

    var apiKeyLabel: String {
        switch self {
        case .openRouter:
            "OpenRouter API Key"
        case .huggingFace:
            "Hugging Face Token"
        case .openAI:
            "OpenAI API Key"
        case .off, .ollama:
            "API Key"
        }
    }

    var modelLabel: String {
        switch self {
        case .ollama:
            "Ollama Model"
        default:
            "Model"
        }
    }

    var defaultModel: String {
        switch self {
        case .off:
            ""
        case .openRouter:
            "openrouter/free"
        case .huggingFace:
            "Qwen/Qwen2.5-7B-Instruct"
        case .openAI:
            "gpt-4.1-mini"
        case .ollama:
            "llama3.2:3b"
        }
    }
}
