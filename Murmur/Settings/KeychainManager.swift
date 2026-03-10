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
        let dataProtectionStatus = upsert(data: data, useDataProtectionKeychain: true)
        if dataProtectionStatus == errSecSuccess {
            _ = deleteFromKeychain(useDataProtectionKeychain: false)
            setCachedAPIKey(apiKey)
            return
        }

        // Legacy fallback for environments where Data Protection Keychain is unavailable.
        let legacyStatus = upsert(data: data, useDataProtectionKeychain: false)
        if legacyStatus == errSecSuccess {
            setCachedAPIKey(apiKey)
            return
        }

        throw KeychainError.saveFailed(legacyStatus)
    }

    static func load(allowAuthenticationUI: Bool = true) -> String? {
        if let cached = getCachedAPIKey(), !cached.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return cached
        }

        if let apiKey = loadFromKeychain(useDataProtectionKeychain: true, allowAuthenticationUI: allowAuthenticationUI) {
            setCachedAPIKey(apiKey)
            return apiKey
        }

        // One-time migration path for legacy login-keychain items created by older builds.
        guard let legacyAPIKey = loadFromKeychain(useDataProtectionKeychain: false, allowAuthenticationUI: allowAuthenticationUI) else {
            setCachedAPIKey(nil)
            return nil
        }

        try? save(apiKey: legacyAPIKey)
        if hasItemInKeychain(useDataProtectionKeychain: true) {
            _ = deleteFromKeychain(useDataProtectionKeychain: false)
        }
        setCachedAPIKey(legacyAPIKey)
        return legacyAPIKey
    }

    static func hasStoredAPIKey() -> Bool {
        if let cached = getCachedAPIKey(), !cached.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return true
        }

        if hasItemInKeychain(useDataProtectionKeychain: true) {
            return true
        }

        return hasItemInKeychain(useDataProtectionKeychain: false)
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
        let dataProtectionStatus = deleteFromKeychain(useDataProtectionKeychain: true)
        let legacyStatus = deleteFromKeychain(useDataProtectionKeychain: false)

        let dataProtectionDeleted = (dataProtectionStatus == errSecSuccess || dataProtectionStatus == errSecItemNotFound)
        let legacyDeleted = (legacyStatus == errSecSuccess || legacyStatus == errSecItemNotFound)

        if dataProtectionDeleted && legacyDeleted {
            setCachedAPIKey(nil)
            return
        }

        if dataProtectionStatus != errSecSuccess && dataProtectionStatus != errSecItemNotFound {
            throw KeychainError.deleteFailed(dataProtectionStatus)
        }
        throw KeychainError.deleteFailed(legacyStatus)
    }

    private static func baseQuery(useDataProtectionKeychain: Bool) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        if useDataProtectionKeychain {
            query[kSecUseDataProtectionKeychain as String] = true
        }
        return query
    }

    private static func loadFromKeychain(useDataProtectionKeychain: Bool, allowAuthenticationUI: Bool) -> String? {
        var query = baseQuery(useDataProtectionKeychain: useDataProtectionKeychain)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        if !allowAuthenticationUI {
            query[kSecUseAuthenticationContext as String] = nonInteractiveAuthContext()
        }

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }
        return apiKey
    }

    private static func hasItemInKeychain(useDataProtectionKeychain: Bool) -> Bool {
        var query = baseQuery(useDataProtectionKeychain: useDataProtectionKeychain)
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecUseAuthenticationContext as String] = nonInteractiveAuthContext()

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        return status == errSecSuccess
    }

    private static func deleteFromKeychain(useDataProtectionKeychain: Bool) -> OSStatus {
        let query = baseQuery(useDataProtectionKeychain: useDataProtectionKeychain)
        return SecItemDelete(query as CFDictionary)
    }

    private static func upsert(data: Data, useDataProtectionKeychain: Bool) -> OSStatus {
        let query = baseQuery(useDataProtectionKeychain: useDataProtectionKeychain)
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibilityPolicy
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        if updateStatus == errSecSuccess {
            return errSecSuccess
        }

        if updateStatus == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = accessibilityPolicy
            return SecItemAdd(addQuery as CFDictionary, nil)
        }

        return updateStatus
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
