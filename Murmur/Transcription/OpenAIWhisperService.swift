import Foundation

final class OpenAIWhisperService: TranscriptionService {
    private let session: URLSession
    private let fileManager: FileManager
    private let endpointURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")!

    init(session: URLSession = .shared, fileManager: FileManager = .default) {
        self.session = session
        self.fileManager = fileManager
    }

    var isAvailable: Bool {
        KeychainManager.load() != nil
    }

    func transcribe(audioURL: URL, targetLanguage: String?) async throws -> String {
        guard let apiKey = KeychainManager.load(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.apiError("No API key")
        }

        guard fileManager.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.audioFileNotFound
        }

        do {
            let boundary = "Boundary-\(UUID().uuidString)"
            var request = URLRequest(url: endpointURL)
            request.httpMethod = "POST"
            request.timeoutInterval = 30
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.httpBody = try makeMultipartBody(audioURL: audioURL, targetLanguage: targetLanguage, boundary: boundary)

            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw TranscriptionError.apiError("Invalid API response.")
            }

            let responseText = String(data: data, encoding: .utf8) ?? ""
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorBody = responseText.isEmpty ? "HTTP \(httpResponse.statusCode)" : responseText
                throw TranscriptionError.apiError(errorBody)
            }

            let transcription = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !transcription.isEmpty else {
                throw TranscriptionError.apiError("OpenAI API returned an empty transcription.")
            }

            try? fileManager.removeItem(at: audioURL)
            return transcription
        } catch let error as TranscriptionError {
            throw error
        } catch is CancellationError {
            throw TranscriptionError.cancelled
        } catch {
            throw TranscriptionError.apiError(error.localizedDescription)
        }
    }

    private func makeMultipartBody(audioURL: URL, targetLanguage: String?, boundary: String) throws -> Data {
        let audioData = try Data(contentsOf: audioURL)
        var body = Data()

        appendFormField(named: "model", value: "whisper-1", to: &body, boundary: boundary)
        appendFormField(named: "response_format", value: "text", to: &body, boundary: boundary)

        if let language = targetLanguage?.trimmingCharacters(in: .whitespacesAndNewlines), !language.isEmpty {
            appendFormField(named: "language", value: language, to: &body, boundary: boundary)
        }

        body.append("--\(boundary)\r\n".utf8Data)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(audioURL.lastPathComponent)\"\r\n".utf8Data)
        body.append("Content-Type: audio/wav\r\n\r\n".utf8Data)
        body.append(audioData)
        body.append("\r\n".utf8Data)
        body.append("--\(boundary)--\r\n".utf8Data)

        return body
    }

    private func appendFormField(named name: String, value: String, to body: inout Data, boundary: String) {
        body.append("--\(boundary)\r\n".utf8Data)
        body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8Data)
        body.append("\(value)\r\n".utf8Data)
    }
}

private extension String {
    var utf8Data: Data {
        Data(utf8)
    }
}
