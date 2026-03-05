import Foundation

final class SettingsModel: ObservableObject {
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
        static let targetLanguage = "en"
        static let whisperBackend = "local"
        static let whisperModel = "base"
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

    @Published var targetLanguage: String {
        didSet { userDefaults.set(targetLanguage, forKey: Keys.targetLanguage) }
    }

    @Published var whisperBackend: String {
        didSet { userDefaults.set(whisperBackend, forKey: Keys.whisperBackend) }
    }

    @Published var whisperModel: String {
        didSet { userDefaults.set(whisperModel, forKey: Keys.whisperModel) }
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
        targetLanguage = userDefaults.string(forKey: Keys.targetLanguage) ?? Defaults.targetLanguage
        whisperBackend = userDefaults.string(forKey: Keys.whisperBackend) ?? Defaults.whisperBackend
        whisperModel = userDefaults.string(forKey: Keys.whisperModel) ?? Defaults.whisperModel
        launchAtLogin = userDefaults.object(forKey: Keys.launchAtLogin) as? Bool ?? Defaults.launchAtLogin
        restoreClipboardAfterPaste = userDefaults.object(forKey: Keys.restoreClipboardAfterPaste) as? Bool ?? Defaults.restoreClipboardAfterPaste
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
}
