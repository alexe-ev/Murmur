import Foundation

protocol TranscriptionService: AnyObject {
    /// Indicates whether the transcription backend is currently available.
    var isAvailable: Bool { get }

    /// Transcribe audio at the given URL.
    /// - Parameters:
    ///   - audioURL: Path to a 16kHz mono WAV file.
    ///   - targetLanguage: BCP-47 language code for the desired output language, or nil for auto-detect.
    /// - Returns: The transcribed (and optionally translated) text.
    func transcribe(audioURL: URL, targetLanguage: String?) async throws -> String
}

enum TranscriptionError: Error {
    case modelNotLoaded
    case audioFileNotFound
    case apiError(String)
    case cancelled
}
