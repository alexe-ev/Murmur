import Foundation

final class OpenAIWhisperService: TranscriptionService {
    private let session: URLSession
    private let fileManager: FileManager
    private let transcriptionsEndpointURL = URL(string: "https://api.openai.com/v1/audio/transcriptions")!
    private let chatCompletionsEndpointURL = URL(string: "https://api.openai.com/v1/chat/completions")!

    init(session: URLSession = .shared, fileManager: FileManager = .default) {
        self.session = session
        self.fileManager = fileManager
    }

    var isAvailable: Bool {
        KeychainManager.hasStoredAPIKey()
    }

    func transcribe(audioURL: URL, request: TranscriptionRequest) async throws -> String {
        guard let apiKey = KeychainManager.load(), !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TranscriptionError.apiError("No API key")
        }

        guard fileManager.fileExists(atPath: audioURL.path) else {
            throw TranscriptionError.audioFileNotFound
        }

        do {
            let normalizedSourceLanguage = request.sourceLanguage?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let normalizedTargetLanguage = request.targetLanguage?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let result: String

            if request.isTranslationEnabled, let targetLanguage = normalizedTargetLanguage, !targetLanguage.isEmpty {
                let transcriptionRequest = try buildTranscriptionRequest(
                    audioURL: audioURL,
                    sourceLanguage: normalizedSourceLanguage,
                    apiKey: apiKey
                )
                let transcribedText = try await performTextRequest(transcriptionRequest)
                result = try await chatTranslate(transcribedText, to: targetLanguage, apiKey: apiKey)
            } else {
                let apiRequest = try buildTranscriptionRequest(
                    audioURL: audioURL,
                    sourceLanguage: normalizedSourceLanguage,
                    apiKey: apiKey
                )
                result = try await performTextRequest(apiRequest)
            }

            return result
        } catch let error as TranscriptionError {
            throw error
        } catch is CancellationError {
            throw TranscriptionError.cancelled
        } catch {
            throw TranscriptionError.apiError(error.localizedDescription)
        }
    }

    private func performTextRequest(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.apiError("Invalid API response.")
        }

        let responseText = String(data: data, encoding: .utf8) ?? ""
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = responseText.isEmpty ? "HTTP \(httpResponse.statusCode)" : responseText
            throw TranscriptionError.apiError(errorBody)
        }

        let text = responseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw TranscriptionError.apiError("OpenAI API returned an empty transcription.")
        }

        return text
    }

    private func chatTranslate(_ text: String, to targetLanguage: String, apiKey: String) async throws -> String {
        let languageName = TranslationConfig.supportedLanguages.first { $0.code == targetLanguage }?.name ?? targetLanguage
        let systemPrompt = """
            You are a professional translator. Translate the text naturally into \(languageName). \
            Adapt idioms, filler words, and colloquial expressions to sound native in the target language. \
            Do not translate literally: convey the meaning, not word-for-word structure. \
            Return only the translated text, no explanation.
            """

        let payload: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ]
        ]

        let requestBody = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: chatCompletionsEndpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.apiError("Invalid API response.")
        }

        let responseText = String(data: data, encoding: .utf8) ?? ""
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = responseText.isEmpty ? "HTTP \(httpResponse.statusCode)" : responseText
            throw TranscriptionError.apiError(errorBody)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw TranscriptionError.apiError("Invalid Chat Completions response format.")
        }

        let translatedText = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !translatedText.isEmpty else {
            throw TranscriptionError.apiError("Chat Completions returned empty text.")
        }

        return translatedText
    }

    private func buildTranscriptionRequest(audioURL: URL, sourceLanguage: String?, apiKey: String) throws -> URLRequest {
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: transcriptionsEndpointURL)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = try makeMultipartBody(
            audioURL: audioURL,
            boundary: boundary,
            includeLanguageField: true,
            targetLanguage: sourceLanguage
        )
        return request
    }

    private func makeMultipartBody(audioURL: URL, boundary: String, includeLanguageField: Bool, targetLanguage: String?) throws -> Data {
        let audioData = try Data(contentsOf: audioURL)
        var body = Data()

        appendFormField(named: "model", value: "whisper-1", to: &body, boundary: boundary)
        appendFormField(named: "response_format", value: "text", to: &body, boundary: boundary)

        if includeLanguageField, let language = targetLanguage, !language.isEmpty {
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
