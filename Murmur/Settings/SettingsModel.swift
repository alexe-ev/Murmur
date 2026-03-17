import Carbon.HIToolbox
import Foundation

final class SettingsModel: ObservableObject {
    private static let hotkeyModifierMask = Int(cmdKey | optionKey | controlKey | shiftKey)
    private static let legacyCommandModifier = 0x0010_0000
    private static let legacyOptionModifier = 0x0008_0000
    private static let legacyControlModifier = 0x0004_0000
    private static let legacyShiftModifier = 0x0002_0000

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
        // Sorted alphabetically by display name
        case sq, am, ar, hy, az
        case eu, be, bn, bs, bg
        case my, ca, zh, hr, cs
        case da, nl, en, et, fi
        case fr, gl, ka, de, el
        case gu, ht, ha, he, hi
        case hu, `is`, id, it, ja
        case jw, kn, kk, km, ko
        case lo, la, lv, ln, lt
        case lb, mk, mg, ms, ml
        case mt, mi, mr, mn, ne
        case no, nn, oc, ps, fa
        case pl, pt, pa, ro, ru
        case sa, sd, sr, si, sk
        case sl, so, es, su, sw
        case sv, tl, tg, ta, tt
        case te, th, bo, tr, tk
        case uk, ur, uz, vi, cy
        case yi, yo

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .sq: return "Albanian"
            case .am: return "Amharic"
            case .ar: return "Arabic"
            case .hy: return "Armenian"
            case .az: return "Azerbaijani"
            case .eu: return "Basque"
            case .be: return "Belarusian"
            case .bn: return "Bengali"
            case .bs: return "Bosnian"
            case .bg: return "Bulgarian"
            case .my: return "Burmese"
            case .ca: return "Catalan"
            case .zh: return "Chinese"
            case .hr: return "Croatian"
            case .cs: return "Czech"
            case .da: return "Danish"
            case .nl: return "Dutch"
            case .en: return "English"
            case .et: return "Estonian"
            case .fi: return "Finnish"
            case .fr: return "French"
            case .gl: return "Galician"
            case .ka: return "Georgian"
            case .de: return "German"
            case .el: return "Greek"
            case .gu: return "Gujarati"
            case .ht: return "Haitian Creole"
            case .ha: return "Hausa"
            case .he: return "Hebrew"
            case .hi: return "Hindi"
            case .hu: return "Hungarian"
            case .is: return "Icelandic"
            case .id: return "Indonesian"
            case .it: return "Italian"
            case .ja: return "Japanese"
            case .jw: return "Javanese"
            case .kn: return "Kannada"
            case .kk: return "Kazakh"
            case .km: return "Khmer"
            case .ko: return "Korean"
            case .lo: return "Lao"
            case .la: return "Latin"
            case .lv: return "Latvian"
            case .ln: return "Lingala"
            case .lt: return "Lithuanian"
            case .lb: return "Luxembourgish"
            case .mk: return "Macedonian"
            case .mg: return "Malagasy"
            case .ms: return "Malay"
            case .ml: return "Malayalam"
            case .mt: return "Maltese"
            case .mi: return "Maori"
            case .mr: return "Marathi"
            case .mn: return "Mongolian"
            case .ne: return "Nepali"
            case .no: return "Norwegian"
            case .nn: return "Norwegian Nynorsk"
            case .oc: return "Occitan"
            case .ps: return "Pashto"
            case .fa: return "Persian"
            case .pl: return "Polish"
            case .pt: return "Portuguese"
            case .pa: return "Punjabi"
            case .ro: return "Romanian"
            case .ru: return "Russian"
            case .sa: return "Sanskrit"
            case .sd: return "Sindhi"
            case .sr: return "Serbian"
            case .si: return "Sinhala"
            case .sk: return "Slovak"
            case .sl: return "Slovenian"
            case .so: return "Somali"
            case .es: return "Spanish"
            case .su: return "Sundanese"
            case .sw: return "Swahili"
            case .sv: return "Swedish"
            case .tl: return "Tagalog"
            case .tg: return "Tajik"
            case .ta: return "Tamil"
            case .tt: return "Tatar"
            case .te: return "Telugu"
            case .th: return "Thai"
            case .bo: return "Tibetan"
            case .tr: return "Turkish"
            case .tk: return "Turkmen"
            case .uk: return "Ukrainian"
            case .ur: return "Urdu"
            case .uz: return "Uzbek"
            case .vi: return "Vietnamese"
            case .cy: return "Welsh"
            case .yi: return "Yiddish"
            case .yo: return "Yoruba"
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
        static let launchAtLogin = "launchAtLogin"
        static let restoreClipboardAfterPaste = "restoreClipboardAfterPaste"
    }

    private enum Defaults {
        static let hotkeyKeyCode = 49
        static let hotkeyModifiers = Int(optionKey)
        static let outputMode: OutputMode = .transcription
        static let speechLanguage: TargetLanguage = .en
        static let targetLanguage: TargetLanguage = .en
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
        launchAtLogin = Defaults.launchAtLogin
        restoreClipboardAfterPaste = Defaults.restoreClipboardAfterPaste
    }

    private func persistNormalizedConfigurationValues() {
        userDefaults.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode)
        userDefaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers)
        userDefaults.set(speechLanguage.rawValue, forKey: Keys.speechLanguage)
        userDefaults.set(targetLanguage.rawValue, forKey: Keys.targetLanguage)
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
