import Carbon.HIToolbox
import Foundation

final class SettingsModel: ObservableObject {
    private static let hotkeyModifierMask = Int(cmdKey | optionKey | controlKey | shiftKey)
    private static let legacyCommandModifier = 0x0010_0000
    private static let legacyOptionModifier = 0x0008_0000
    private static let legacyControlModifier = 0x0004_0000
    private static let legacyShiftModifier = 0x0002_0000

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

    enum OutputMode: String, CaseIterable, Identifiable {
        case transcription
        case cleanup
        case translation

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .transcription: return "Transcription"
            case .cleanup: return "Clean-up"
            case .translation: return "Translation"
            }
        }

        static func fromPersisted(_ rawValue: String?) -> OutputMode {
            let cleaned = rawValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            return OutputMode(rawValue: cleaned ?? "") ?? .transcription
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
        static let outputMode = "outputMode"
        static let speechLanguage = "speechLanguage"
        static let targetLanguage = "targetLanguage"
        static let whisperBackend = "whisperBackend"
        static let whisperModel = "whisperModel"
        static let launchAtLogin = "launchAtLogin"
        static let restoreClipboardAfterPaste = "restoreClipboardAfterPaste"
    }

    private enum Defaults {
        static let hotkeyKeyCode = 49
        static let hotkeyModifiers = Int(optionKey)
        static let outputMode: OutputMode = .transcription
        static let speechLanguage: TargetLanguage = .en
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
            let normalizedModifiers = Self.normalizeHotkeyModifiers(hotkeyModifiers)
            if hotkeyModifiers != normalizedModifiers {
                hotkeyModifiers = normalizedModifiers
                return
            }

            // Never allow a modifier-less global hotkey because it can hijack regular typing (e.g. Space).
            if normalizedModifiers == 0 {
                hotkeyKeyCode = Defaults.hotkeyKeyCode
                hotkeyModifiers = Defaults.hotkeyModifiers
                return
            }

            userDefaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers)
            guard hotkeyModifiers != oldValue else { return }
            Task { @MainActor in
                AppDelegate.shared?.reregisterHotkey()
            }
        }
    }

    @Published var outputMode: OutputMode {
        didSet { userDefaults.set(outputMode.rawValue, forKey: Keys.outputMode) }
    }

    @Published var speechLanguage: TargetLanguage {
        didSet { userDefaults.set(speechLanguage.rawValue, forKey: Keys.speechLanguage) }
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
        // Migrate from old boolean translationEnabled to outputMode enum.
        let resolvedMode: OutputMode
        if let legacyTranslation = userDefaults.object(forKey: "translationEnabled") as? Bool {
            resolvedMode = legacyTranslation ? .translation : .transcription
            userDefaults.removeObject(forKey: "translationEnabled")
            userDefaults.set(resolvedMode.rawValue, forKey: Keys.outputMode)
        } else {
            resolvedMode = OutputMode.fromPersisted(userDefaults.string(forKey: Keys.outputMode))
        }
        outputMode = resolvedMode
        let persistedTargetLanguage = TargetLanguage.fromPersisted(userDefaults.string(forKey: Keys.targetLanguage))
        targetLanguage = persistedTargetLanguage
        let persistedSpeechLanguageRaw = userDefaults.string(forKey: Keys.speechLanguage) ?? persistedTargetLanguage.rawValue
        speechLanguage = TargetLanguage.fromPersisted(persistedSpeechLanguageRaw)
        whisperBackend = WhisperBackend.fromPersisted(userDefaults.string(forKey: Keys.whisperBackend))
        whisperModel = WhisperModel.fromPersisted(userDefaults.string(forKey: Keys.whisperModel))
        launchAtLogin = userDefaults.object(forKey: Keys.launchAtLogin) as? Bool ?? Defaults.launchAtLogin
        restoreClipboardAfterPaste = userDefaults.object(forKey: Keys.restoreClipboardAfterPaste) as? Bool ?? Defaults.restoreClipboardAfterPaste

        normalizeHotkeyConfigurationIfNeeded()
        persistNormalizedConfigurationValues()
    }

    func reset() {
        hotkeyKeyCode = Defaults.hotkeyKeyCode
        hotkeyModifiers = Defaults.hotkeyModifiers
        outputMode = Defaults.outputMode
        speechLanguage = Defaults.speechLanguage
        targetLanguage = Defaults.targetLanguage
        whisperBackend = Defaults.whisperBackend
        whisperModel = Defaults.whisperModel
        launchAtLogin = Defaults.launchAtLogin
        restoreClipboardAfterPaste = Defaults.restoreClipboardAfterPaste
    }

    private func persistNormalizedConfigurationValues() {
        userDefaults.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode)
        userDefaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers)
        userDefaults.set(speechLanguage.rawValue, forKey: Keys.speechLanguage)
        userDefaults.set(targetLanguage.rawValue, forKey: Keys.targetLanguage)
        userDefaults.set(whisperBackend.rawValue, forKey: Keys.whisperBackend)
        userDefaults.set(whisperModel.rawValue, forKey: Keys.whisperModel)
    }

    private func normalizeHotkeyConfigurationIfNeeded() {
        let normalizedModifiers = Self.normalizeHotkeyModifiers(hotkeyModifiers)
        if normalizedModifiers == 0 {
            hotkeyKeyCode = Defaults.hotkeyKeyCode
            hotkeyModifiers = Defaults.hotkeyModifiers
            return
        }

        if hotkeyModifiers != normalizedModifiers {
            hotkeyModifiers = normalizedModifiers
        }
    }

    private static func normalizeHotkeyModifiers(_ raw: Int) -> Int {
        let carbonModifiers = raw & hotkeyModifierMask
        if carbonModifiers != 0 || raw == 0 {
            return carbonModifiers
        }

        // Migrate legacy NSEvent-style modifier flags persisted by older builds.
        var converted = 0
        if raw & legacyCommandModifier != 0 { converted |= Int(cmdKey) }
        if raw & legacyOptionModifier != 0 { converted |= Int(optionKey) }
        if raw & legacyControlModifier != 0 { converted |= Int(controlKey) }
        if raw & legacyShiftModifier != 0 { converted |= Int(shiftKey) }
        return converted
    }
}
