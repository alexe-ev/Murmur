import Foundation

enum APIKeyError: Error {
    case saveFailed(String)
    case deleteFailed(String)
}

final class APIKeyStorage {
    private static let fileName = ".api-key"
    private static let cacheLock = NSLock()
    private static var cachedAPIKey: String?

    private static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Murmur").appendingPathComponent(fileName)
    }

    static func save(apiKey: String) throws {
        let directory = storageURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try apiKey.write(to: storageURL, atomically: true, encoding: .utf8)
        setCachedAPIKey(apiKey)
    }

    static func load() -> String? {
        if let cached = getCachedAPIKey(), !cached.isEmpty {
            return cached
        }

        guard let content = try? String(contentsOf: storageURL, encoding: .utf8) else {
            return nil
        }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        setCachedAPIKey(trimmed)
        return trimmed
    }

    static func hasStoredAPIKey() -> Bool {
        if let cached = getCachedAPIKey(), !cached.isEmpty {
            return true
        }
        return load() != nil
    }

    static func delete() throws {
        let fm = FileManager.default
        if fm.fileExists(atPath: storageURL.path) {
            try fm.removeItem(at: storageURL)
        }
        setCachedAPIKey(nil)
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
