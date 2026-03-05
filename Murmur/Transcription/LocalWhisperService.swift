import Foundation

#if arch(arm64)
import WhisperKit
#endif

final class LocalWhisperService: TranscriptionService {
    private let modelManager: ModelManager
    private let fileManager: FileManager

    init(modelManager: ModelManager, fileManager: FileManager = .default) {
        self.modelManager = modelManager
        self.fileManager = fileManager
    }

    @MainActor
    convenience init(fileManager: FileManager = .default) {
        self.init(modelManager: .shared, fileManager: fileManager)
    }

    var isAvailable: Bool {
        if Thread.isMainThread {
            return MainActor.assumeIsolated { modelManager.isModelLoaded }
        }

        return DispatchQueue.main.sync {
            MainActor.assumeIsolated { modelManager.isModelLoaded }
        }
    }

    func transcribe(audioURL: URL, request: TranscriptionRequest) async throws -> String {
        guard isAvailable else {
            throw TranscriptionError.modelNotLoaded
        }

        guard fileManager.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.audioFileNotFound
        }

        do {
#if arch(arm64)
            let whisperKit = try await MainActor.run { () throws -> WhisperKit in
                guard let loadedModel = modelManager.whisperKit else {
                    throw TranscriptionError.modelNotLoaded
                }
                return loadedModel
            }

            let options = decodingOptions(for: request.targetLanguage)
            let results = try await whisperKit.transcribe(audioPath: audioURL.path, decodeOptions: options)

            let text = concatenateText(from: results)
            guard !text.isEmpty else {
                throw TranscriptionError.apiError("WhisperKit returned an empty transcription.")
            }

            return text
#else
            throw TranscriptionError.apiError("WhisperKit is available only on arm64 builds.")
#endif
        } catch let error as TranscriptionError {
            throw error
        } catch is CancellationError {
            throw TranscriptionError.cancelled
        } catch {
            throw TranscriptionError.apiError(error.localizedDescription)
        }
    }

#if arch(arm64)
    private func decodingOptions(for targetLanguage: String?) -> DecodingOptions {
        let normalizedLanguage = targetLanguage?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        let task: DecodingTask = (normalizedLanguage != nil && normalizedLanguage != "en") ? .translate : .transcribe
        return DecodingOptions(task: task, withoutTimestamps: true)
    }

    private func concatenateText(from results: [TranscriptionResult]) -> String {
        let segmentText = results
            .flatMap { $0.segments }
            .map(\.text)
            .map(sanitizeTranscriptionText)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        if !segmentText.isEmpty {
            return segmentText
        }

        return results
            .map(\.text)
            .map(sanitizeTranscriptionText)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func sanitizeTranscriptionText(_ text: String) -> String {
        let tokenStripped = text.replacingOccurrences(
            of: #"<\|[^|]+?\|>"#,
            with: " ",
            options: .regularExpression
        )

        return tokenStripped.replacingOccurrences(
            of: #"\s+"#,
            with: " ",
            options: .regularExpression
        )
    }
#endif
}
