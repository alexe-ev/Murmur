import Combine
import Foundation

final class TranslationConfig: ObservableObject {
    static let shared = TranslationConfig()

    static let supportedLanguages: [(code: String, name: String)] =
        SettingsModel.TargetLanguage.allCases.map { language in
            (language.rawValue, language.displayName)
        }

    @Published private(set) var isEnabled: Bool
    @Published private(set) var targetLanguage: SettingsModel.TargetLanguage

    var requiresAPI: Bool {
        isEnabled
    }

    var targetIsEnglish: Bool {
        targetLanguage == .en
    }

    private let settings: SettingsModel
    private var cancellables = Set<AnyCancellable>()

    private init(settings: SettingsModel = .shared) {
        self.settings = settings
        isEnabled = settings.translationEnabled
        targetLanguage = settings.targetLanguage

        settings.$translationEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.isEnabled = value
            }
            .store(in: &cancellables)

        settings.$targetLanguage
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.targetLanguage = value
            }
            .store(in: &cancellables)
    }
}
