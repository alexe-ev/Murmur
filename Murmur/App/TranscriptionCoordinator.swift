import Combine
import Foundation

@MainActor
final class TranscriptionCoordinator {
    private let settingsModel: SettingsModel
    private let translationConfig: TranslationConfig
    private var service: TranscriptionService = LocalWhisperService()
    private var cancellables = Set<AnyCancellable>()

    var onMissingAPIKey: (() -> Void)?

    init(settingsModel: SettingsModel, translationConfig: TranslationConfig) {
        self.settingsModel = settingsModel
        self.translationConfig = translationConfig
    }

    func start() {
        observeBackendChanges()
        observeTranslationConfigChanges()
        enforceBackendForCurrentConfig()
    }

    func transcribe(audioURL: URL) async throws -> String? {
        enforceBackendForCurrentConfig()

        let requiresAPIKey = translationConfig.requiresAPI || settingsModel.whisperBackend == .api
        if requiresAPIKey && !KeychainManager.hasStoredAPIKey() {
            onMissingAPIKey?()
            return nil
        }

        let request = TranscriptionRequest(
            sourceLanguage: settingsModel.speechLanguage.rawValue,
            targetLanguage: translationConfig.targetLanguage.rawValue,
            isTranslationEnabled: translationConfig.isEnabled
        )
        return try await service.transcribe(audioURL: audioURL, request: request)
    }

    private func observeBackendChanges() {
        settingsModel.$whisperBackend
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.enforceBackendForCurrentConfig()
            }
            .store(in: &cancellables)
    }

    private func observeTranslationConfigChanges() {
        translationConfig.$isEnabled
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.enforceBackendForCurrentConfig()
            }
            .store(in: &cancellables)

        translationConfig.$targetLanguage
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.enforceBackendForCurrentConfig()
            }
            .store(in: &cancellables)
    }

    private func applyTranscriptionBackend() {
        switch settingsModel.whisperBackend {
        case .api:
            service = OpenAIWhisperService()
        case .local:
            service = LocalWhisperService()
            Task {
                do {
                    try await ModelManager.shared.loadModel()
                } catch is CancellationError {
                    return
                } catch {
                    print("Failed to load local Whisper model: \(error.localizedDescription)")
                }
            }
        }
    }

    private func enforceBackendForCurrentConfig() {
        if translationConfig.requiresAPI {
            if settingsModel.whisperBackend == .api {
                applyTranscriptionBackend()
            } else {
                service = OpenAIWhisperService()
            }
            return
        }

        applyTranscriptionBackend()
    }
}
