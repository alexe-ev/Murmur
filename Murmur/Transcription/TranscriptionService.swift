import Foundation

struct TranscriptionRequest {
    let sourceLanguage: String?
    let targetLanguage: String?
    let outputMode: SettingsModel.OutputMode
}

protocol TranscriptionService: AnyObject {
    /// Indicates whether the transcription backend is currently available.
    var isAvailable: Bool { get }

    /// Transcribe audio at the given URL.
    /// - Parameters:
    ///   - audioURL: Path to a 16kHz mono WAV file.
    ///   - request: Explicit runtime context for transcription/translation behavior.
    /// - Returns: The transcribed (and optionally translated) text.
    func transcribe(audioURL: URL, request: TranscriptionRequest) async throws -> String
}

enum TranscriptionError: Error {
    case modelNotLoaded
    case audioFileNotFound
    case apiError(String)
    case cancelled
}
