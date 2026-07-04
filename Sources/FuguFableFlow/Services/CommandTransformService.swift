import Foundation

struct CommandTransformService {
    enum CommandTransformError: LocalizedError {
        case disabled
        case missingAPIKey(CommandModeProvider)
        case invalidResponse
        case server(String)

        var errorDescription: String? {
            switch self {
            case .disabled:
                "Choose a Command Mode provider in Settings."
            case .missingAPIKey(let provider):
                "Add a \(provider.apiKeyLabel) in Settings to use Command Mode."
            case .invalidResponse:
                "Command Mode returned an unreadable response."
            case .server(let message):
                message
            }
        }
    }

    let provider: CommandModeProvider
    let apiKey: String
    let model: String

    func transform(selectedText: String, command: String) async throws -> String {
        switch provider {
        case .off:
            throw CommandTransformError.disabled
        case .openRouter, .huggingFace, .openAI:
            return try await transformWithChatCompletions(selectedText: selectedText, command: command)
        case .ollama:
            return try await transformWithOllama(selectedText: selectedText, command: command)
        }
    }

    private func transformWithChatCompletions(selectedText: String, command: String) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw CommandTransformError.missingAPIKey(provider) }

        var request = URLRequest(url: provider.chatCompletionsURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if provider == .openRouter {
            request.setValue("FuguFableFlow", forHTTPHeaderField: "X-Title")
        }

        let payload: [String: Any] = [
            "model": effectiveModel,
            "messages": Self.messages(selectedText: selectedText, command: command),
            "temperature": 0.2
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response: response, data: data)

        if let outputText = try Self.chatCompletionText(from: data) {
            return outputText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw CommandTransformError.invalidResponse
    }

    private func transformWithOllama(selectedText: String, command: String) async throws -> String {
        var request = URLRequest(url: URL(string: "http://localhost:11434/api/chat")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 90
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": effectiveModel,
            "messages": Self.messages(selectedText: selectedText, command: command),
            "stream": false,
            "options": [
                "temperature": 0.2
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response: response, data: data)

        if let outputText = try Self.ollamaText(from: data) {
            return outputText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        throw CommandTransformError.invalidResponse
    }

    private var effectiveModel: String {
        let trimmed = model.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? provider.defaultModel : trimmed
    }

    private static func messages(selectedText: String, command: String) -> [[String: String]] {
        [
            [
                "role": "system",
                "content": "You are FuguFableFlow Command Mode. Return only the text to insert. Do not add explanations unless the user asked for them."
            ],
            [
                "role": "user",
                "content": prompt(selectedText: selectedText, command: command)
            ]
        ]
    }

    private static func prompt(selectedText: String, command: String) -> String {
        if selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return """
            Answer or generate text for insertion at the cursor.

            Voice command:
            \(command)
            """
        }

        return """
        Transform the selected text according to the spoken command.
        Return only the replacement text. Do not wrap it in quotes. Do not explain the change.

        Selected text:
        \(selectedText)

        Voice command:
        \(command)
        """
    }

    private static func validate(response: URLResponse, data: Data) throws {
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? "HTTP \(status)"
            throw CommandTransformError.server(body)
        }
    }

    private static func chatCompletionText(from data: Data) throws -> String? {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any],
              let choices = dictionary["choices"] as? [[String: Any]],
              let firstChoice = choices.first else {
            return nil
        }

        if let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String,
           !content.isEmpty {
            return content
        }
        return firstChoice["text"] as? String
    }

    private static func ollamaText(from data: Data) throws -> String? {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any],
              let message = dictionary["message"] as? [String: Any],
              let content = message["content"] as? String,
              !content.isEmpty else {
            return nil
        }
        return content
    }
}

private extension CommandModeProvider {
    var chatCompletionsURL: URL {
        switch self {
        case .openRouter:
            URL(string: "https://openrouter.ai/api/v1/chat/completions")!
        case .huggingFace:
            URL(string: "https://router.huggingface.co/v1/chat/completions")!
        case .openAI:
            URL(string: "https://api.openai.com/v1/chat/completions")!
        case .off, .ollama:
            preconditionFailure("Provider does not use hosted chat completions")
        }
    }
}
