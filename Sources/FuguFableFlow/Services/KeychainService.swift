import Foundation
import Security

enum KeychainService {
    private static let service = "app.fugufableflow.local"
    private static let legacyService = "app.personalflow.local"
    private static let legacyOpenAIAccount = "openai-api-key"

    static func loadAPIKey(for provider: CommandModeProvider) -> String {
        if let value = load(service: service, account: account(for: provider)) {
            return value
        }

        if let legacyValue = load(service: legacyService, account: account(for: provider)) {
            saveAPIKey(legacyValue, for: provider)
            return legacyValue
        }

        if provider == .openAI, let legacyValue = load(service: legacyService, account: legacyOpenAIAccount) {
            saveAPIKey(legacyValue, for: provider)
            return legacyValue
        }

        return ""
    }

    static func saveAPIKey(_ value: String, for provider: CommandModeProvider) {
        guard provider.requiresAPIKey else { return }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            deleteAPIKey(for: provider)
            return
        }

        let data = Data(trimmed.utf8)
        let query = baseQuery(account: account(for: provider))
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    static func migrateLegacyOpenAIKey(_ value: String) {
        saveAPIKey(value, for: .openAI)
    }

    private static func deleteAPIKey(for provider: CommandModeProvider) {
        SecItemDelete(baseQuery(account: account(for: provider)) as CFDictionary)
    }

    private static func account(for provider: CommandModeProvider) -> String {
        "command-mode-\(provider.rawValue)-api-key"
    }

    private static func baseQuery(account: String) -> [String: Any] {
        baseQuery(service: service, account: account)
    }

    private static func baseQuery(service: String, account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func load(service: String, account: String) -> String? {
        var query = baseQuery(service: service, account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }
}
