import Combine
import Foundation

final class TranslationConfig: ObservableObject {
    static let shared = TranslationConfig()

    static let supportedLanguages: [(code: String, name: String)] =
        SettingsModel.TargetLanguage.allCases.map { language in
            (language.rawValue, language.displayName)
        }

    @Published private(set) var outputMode: SettingsModel.OutputMode
    @Published private(set) var targetLanguage: SettingsModel.TargetLanguage

    private let settings: SettingsModel
    private var cancellables = Set<AnyCancellable>()

    private init(settings: SettingsModel = .shared) {
        self.settings = settings
        outputMode = settings.outputMode
        targetLanguage = settings.targetLanguage

        settings.$outputMode
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?.outputMode = value
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
