import Combine
import Foundation

final class TranslationConfig: ObservableObject {
    static let shared = TranslationConfig()

    static let supportedLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Spanish"),
        ("fr", "French"),
        ("de", "German"),
        ("it", "Italian"),
        ("pt", "Portuguese"),
        ("zh", "Chinese"),
        ("ja", "Japanese"),
        ("ko", "Korean"),
        ("ru", "Russian"),
        ("ar", "Arabic"),
        ("hi", "Hindi")
    ]

    @Published private(set) var isEnabled: Bool
    @Published private(set) var targetLanguage: String

    var requiresAPI: Bool {
        isEnabled
    }

    var targetIsEnglish: Bool {
        targetLanguage == "en"
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
