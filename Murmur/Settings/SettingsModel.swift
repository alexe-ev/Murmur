import Foundation

final class SettingsModel: ObservableObject {
    enum WhisperBackend: String, CaseIterable, Identifiable {
        case local
        case api

        var id: String { rawValue }

        static func fromPersisted(_ rawValue: String?) -> WhisperBackend {
            let cleaned = rawValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            return WhisperBackend(rawValue: cleaned ?? "") ?? .local
        }
    }

    enum WhisperModel: String, CaseIterable, Identifiable {
        case tiny
        case base
        case small

        var id: String { rawValue }

        static func fromPersisted(_ rawValue: String?) -> WhisperModel {
            let cleaned = rawValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
                .replacingOccurrences(of: "whisper-", with: "")

            return WhisperModel(rawValue: cleaned ?? "") ?? .base
        }
    }

    enum TargetLanguage: String, CaseIterable, Identifiable {
        case en
        case es
        case fr
        case de
        case it
        case pt
        case zh
        case ja
        case ko
        case ru
        case ar
        case hi

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .en: return "English"
            case .es: return "Spanish"
            case .fr: return "French"
            case .de: return "German"
            case .it: return "Italian"
            case .pt: return "Portuguese"
            case .zh: return "Chinese"
            case .ja: return "Japanese"
            case .ko: return "Korean"
            case .ru: return "Russian"
            case .ar: return "Arabic"
            case .hi: return "Hindi"
            }
        }

        static func fromPersisted(_ rawValue: String?) -> TargetLanguage {
            let cleaned = rawValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            return TargetLanguage(rawValue: cleaned ?? "") ?? .en
        }
    }

    static let shared = SettingsModel()

    private enum Keys {
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let translationEnabled = "translationEnabled"
        static let targetLanguage = "targetLanguage"
        static let whisperBackend = "whisperBackend"
        static let whisperModel = "whisperModel"
        static let launchAtLogin = "launchAtLogin"
        static let restoreClipboardAfterPaste = "restoreClipboardAfterPaste"
    }

    private enum Defaults {
        static let hotkeyKeyCode = 49
        static let hotkeyModifiers = 0x0008_0000
        static let translationEnabled = false
        static let targetLanguage: TargetLanguage = .en
        static let whisperBackend: WhisperBackend = .local
        static let whisperModel: WhisperModel = .base
        static let launchAtLogin = false
        static let restoreClipboardAfterPaste = true
    }

    private let userDefaults: UserDefaults

    var launchAtLoginDidChange: ((Bool) -> Void)?

    @Published var hotkeyKeyCode: Int {
        didSet {
            userDefaults.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode)
            guard hotkeyKeyCode != oldValue else { return }
            Task { @MainActor in
                AppDelegate.shared?.reregisterHotkey()
            }
        }
    }

    @Published var hotkeyModifiers: Int {
        didSet {
            userDefaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers)
            guard hotkeyModifiers != oldValue else { return }
            Task { @MainActor in
                AppDelegate.shared?.reregisterHotkey()
            }
        }
    }

    @Published var translationEnabled: Bool {
        didSet { userDefaults.set(translationEnabled, forKey: Keys.translationEnabled) }
    }

    @Published var targetLanguage: TargetLanguage {
        didSet { userDefaults.set(targetLanguage.rawValue, forKey: Keys.targetLanguage) }
    }

    @Published var whisperBackend: WhisperBackend {
        didSet { userDefaults.set(whisperBackend.rawValue, forKey: Keys.whisperBackend) }
    }

    @Published var whisperModel: WhisperModel {
        didSet { userDefaults.set(whisperModel.rawValue, forKey: Keys.whisperModel) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            userDefaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            launchAtLoginDidChange?(launchAtLogin)
        }
    }

    @Published var restoreClipboardAfterPaste: Bool {
        didSet { userDefaults.set(restoreClipboardAfterPaste, forKey: Keys.restoreClipboardAfterPaste) }
    }

    private init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        hotkeyKeyCode = userDefaults.object(forKey: Keys.hotkeyKeyCode) as? Int ?? Defaults.hotkeyKeyCode
        hotkeyModifiers = userDefaults.object(forKey: Keys.hotkeyModifiers) as? Int ?? Defaults.hotkeyModifiers
        translationEnabled = userDefaults.object(forKey: Keys.translationEnabled) as? Bool ?? Defaults.translationEnabled
        targetLanguage = TargetLanguage.fromPersisted(userDefaults.string(forKey: Keys.targetLanguage))
        whisperBackend = WhisperBackend.fromPersisted(userDefaults.string(forKey: Keys.whisperBackend))
        whisperModel = WhisperModel.fromPersisted(userDefaults.string(forKey: Keys.whisperModel))
        launchAtLogin = userDefaults.object(forKey: Keys.launchAtLogin) as? Bool ?? Defaults.launchAtLogin
        restoreClipboardAfterPaste = userDefaults.object(forKey: Keys.restoreClipboardAfterPaste) as? Bool ?? Defaults.restoreClipboardAfterPaste

        persistNormalizedConfigurationValues()
    }

    func reset() {
        hotkeyKeyCode = Defaults.hotkeyKeyCode
        hotkeyModifiers = Defaults.hotkeyModifiers
        translationEnabled = Defaults.translationEnabled
        targetLanguage = Defaults.targetLanguage
        whisperBackend = Defaults.whisperBackend
        whisperModel = Defaults.whisperModel
        launchAtLogin = Defaults.launchAtLogin
        restoreClipboardAfterPaste = Defaults.restoreClipboardAfterPaste
    }

    private func persistNormalizedConfigurationValues() {
        userDefaults.set(targetLanguage.rawValue, forKey: Keys.targetLanguage)
        userDefaults.set(whisperBackend.rawValue, forKey: Keys.whisperBackend)
        userDefaults.set(whisperModel.rawValue, forKey: Keys.whisperModel)
    }
}
