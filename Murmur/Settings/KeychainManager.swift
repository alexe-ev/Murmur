import Foundation
import LocalAuthentication
import Security

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case loadFailed
    case deleteFailed(OSStatus)
}

final class KeychainManager {
    private static let service = "com.murmur.app"
    private static let account = "openai-api-key"
    // Keep the API key on this device and available after first user unlock.
    private static let accessibilityPolicy = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    private static let cacheLock = NSLock()
    private static var cachedAPIKey: String?

    static func save(apiKey: String) throws {
        let data = Data(apiKey.utf8)
        let query = baseQuery()
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibilityPolicy
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if updateStatus == errSecSuccess {
            setCachedAPIKey(apiKey)
            return
        }

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = accessibilityPolicy
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.saveFailed(addStatus)
            }
            setCachedAPIKey(apiKey)
            return
        }

        throw KeychainError.saveFailed(updateStatus)
    }

    static func load(allowAuthenticationUI: Bool = true) -> String? {
        if let cached = getCachedAPIKey(), !cached.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return cached
        }

        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if !allowAuthenticationUI {
            query[kSecUseAuthenticationContext as String] = nonInteractiveAuthContext()
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            setCachedAPIKey(nil)
            return nil
        }

        guard status == errSecSuccess,
              let data = item as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }

        setCachedAPIKey(apiKey)
        return apiKey
    }

    static func hasStoredAPIKey() -> Bool {
        if let cached = getCachedAPIKey(), !cached.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        var query = baseQuery()
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = nonInteractiveAuthContext()

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess
    }

    static func hasValidAPIKey() -> Bool {
        guard
            let apiKey = load(allowAuthenticationUI: false),
            !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return false
        }
        return true
    }

    static func delete() throws {
        let query = baseQuery()
        let status = SecItemDelete(query as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            setCachedAPIKey(nil)
            return
        }

        throw KeychainError.deleteFailed(status)
    }

    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    private static func nonInteractiveAuthContext() -> LAContext {
        let context = LAContext()
        context.interactionNotAllowed = true
        return context
    }

    private static func getCachedAPIKey() -> String? {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        return cachedAPIKey
    }

    private static func setCachedAPIKey(_ value: String?) {
        cacheLock.lock()
        cachedAPIKey = value
        cacheLock.unlock()
    }
}
