import Foundation

@MainActor
final class TranscriptionCoordinator {
    private let settingsModel: SettingsModel
    private let translationConfig: TranslationConfig
    private let service: TranscriptionService = OpenAIWhisperService()

    var onMissingAPIKey: (() -> Void)?

    init(settingsModel: SettingsModel, translationConfig: TranslationConfig) {
        self.settingsModel = settingsModel
        self.translationConfig = translationConfig
    }

    func transcribe(audioURL: URL) async throws -> String? {
        if !APIKeyStorage.hasStoredAPIKey() {
            onMissingAPIKey?()
            return nil
        }

        let request = TranscriptionRequest(
            sourceLanguage: settingsModel.speechLanguage.rawValue,
            targetLanguage: translationConfig.targetLanguage.rawValue,
            outputMode: translationConfig.outputMode
        )
        return try await service.transcribe(audioURL: audioURL, request: request)
    }
}
