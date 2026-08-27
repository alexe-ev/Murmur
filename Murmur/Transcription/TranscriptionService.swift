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
    case audioFileNotFound
    case failed(TranscriptionFailure)
    case cancelled
    case fileTooLarge(sizeMB: Double)
}

/// One classified transcription failure. `headline` is the app's own sentence, shown identically in the
/// notification and in the expanded pill; `displayDetail` is the vendor's / system's text for the pill's detail box.
struct TranscriptionFailure: Equatable {
    enum Stage: Equatable {
        case speechToText
        case postProcessing

        var label: String {
            switch self {
            case .speechToText: return "Speech-to-text"
            case .postProcessing: return "Post-processing"
            }
        }
    }

    enum Kind: Equatable {
        case offline
        case timedOut
        case unauthorized
        case outOfCredit
        case rateLimited
        case limited
        case serverError(Int)
        case unexpectedResponse
        case emptyTranscript
        case http(Int)
        case other(String)
    }

    /// Longest detail shown in the pill, in characters. Provisional: the box scrolls (maxHeight 200), the cap only
    /// keeps a multi-KB HTML page out of a SwiftUI Text; OpenAI messages seen so far are under 300 characters.
    static let detailCap = 500

    let kind: Kind
    /// nil in single-call (Transcription) mode; set in Clean-up / Translation so the detail names the failed call.
    let stage: Stage?
    let detail: String

    var headline: String {
        switch kind {
        case .offline: return "No internet connection. Transcription failed."
        case .timedOut: return "The request timed out. Try again."
        case .unauthorized: return "OpenAI did not accept your API key. Check it in Settings."
        case .outOfCredit: return "OpenAI account is out of credit or over its spend limit."
        case .rateLimited: return "OpenAI rate limit reached. Wait a moment and try again."
        case .limited: return "OpenAI limited the request: out of credit or too many requests."
        case .serverError(let code): return "OpenAI is having trouble (HTTP \(code)). Try again shortly."
        case .unexpectedResponse: return "OpenAI returned an unexpected response."
        case .emptyTranscript: return "Nothing recognised. Check the speech language or speak up."
        case .http(let code): return "Transcription failed (HTTP \(code))."
        case .other(let reason): return "Transcription failed: \(reason)"
        }
    }

    var displayDetail: String {
        guard let stage else { return detail }
        return "\(stage.label): \(detail)"
    }

    static func capped(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > detailCap else { return trimmed }
        return String(trimmed.prefix(detailCap)) + "…"
    }
}
