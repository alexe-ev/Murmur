import XCTest
@testable import Murmur

final class OpenAIWhisperServiceValidationTests: XCTestCase {
    private var service: OpenAIWhisperService!

    override func setUp() {
        super.setUp()
        service = OpenAIWhisperService()
    }

    // MARK: - File size validation

    func testFileTooLargeThrowsError() async {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("murmur_test_large_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: url) }

        // Create a file > 25 MB (26 MB)
        let size = 26 * 1_048_576
        let data = Data(count: size)
        FileManager.default.createFile(atPath: url.path, contents: data)

        let request = TranscriptionRequest(
            sourceLanguage: "en",
            targetLanguage: nil,
            outputMode: .transcription
        )

        do {
            _ = try await service.transcribe(audioURL: url, request: request)
            XCTFail("Expected fileTooLarge error")
        } catch let error as TranscriptionError {
            guard case .fileTooLarge(let sizeMB) = error else {
                XCTFail("Expected fileTooLarge, got \(error)")
                return
            }
            XCTAssertGreaterThan(sizeMB, 25.0)
        } catch {
            // failed(.other("No API key")) is acceptable if the file size check passes
            // (meaning file was under 25MB). But we created 26MB so this shouldn't happen.
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFileUnder25MBPassesValidation() async {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("murmur_test_small_\(UUID().uuidString).wav")
        defer { try? FileManager.default.removeItem(at: url) }

        // Create a 1 MB file (under limit)
        let data = Data(count: 1_048_576)
        FileManager.default.createFile(atPath: url.path, contents: data)

        let request = TranscriptionRequest(
            sourceLanguage: "en",
            targetLanguage: nil,
            outputMode: .transcription
        )

        do {
            _ = try await service.transcribe(audioURL: url, request: request)
            XCTFail("Should have thrown (no API key), but not fileTooLarge")
        } catch let error as TranscriptionError {
            // Should get failed (no key), NOT fileTooLarge
            guard case .failed = error else {
                XCTFail("Expected failed (no key), got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testMissingFileThrowsAudioFileNotFound() async {
        let url = URL(fileURLWithPath: "/tmp/murmur_nonexistent_\(UUID().uuidString).wav")

        let request = TranscriptionRequest(
            sourceLanguage: "en",
            targetLanguage: nil,
            outputMode: .transcription
        )

        do {
            _ = try await service.transcribe(audioURL: url, request: request)
            XCTFail("Expected audioFileNotFound error")
        } catch let error as TranscriptionError {
            guard case .audioFileNotFound = error else {
                XCTFail("Expected audioFileNotFound, got \(error)")
                return
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

final class OpenAIErrorClassificationTests: XCTestCase {
    private func body(_ json: String) -> Data { Data(json.utf8) }

    // Envelope measured on a real 401 from api.openai.com, 2026-08-27 (fake key; the fragment is OpenAI's own masking).
    private let measured401 = #"{"error": {"message": "Incorrect API key provided: sk-not-a********************heck. You can find your API key at https://platform.openai.com/account/api-keys.", "type": "invalid_request_error", "code": "invalid_api_key", "param": null}, "status": 401}"#

    func test401IsUnauthorizedWithVendorMessageAsDetail() {
        let f = OpenAIWhisperService.failure(forStatus: 401, body: body(measured401), stage: nil)
        XCTAssertEqual(f.kind, .unauthorized)
        XCTAssertEqual(f.headline, "OpenAI did not accept your API key. Check it in Settings.")
        XCTAssertTrue(f.displayDetail.hasPrefix("Incorrect API key provided:"))
        XCTAssertFalse(f.displayDetail.contains("{"), "detail must be the message, not the JSON envelope")
    }

    func test401WithNullCodeStillUnauthorized() {
        let json = #"{"error": {"message": "You didn't provide an API key.", "type": "invalid_request_error", "param": null, "code": null}}"#
        let f = OpenAIWhisperService.failure(forStatus: 401, body: body(json), stage: nil)
        XCTAssertEqual(f.kind, .unauthorized)
        XCTAssertEqual(f.displayDetail, "You didn't provide an API key.")

        let empty = OpenAIWhisperService.failure(forStatus: 401, body: Data(), stage: nil)
        XCTAssertEqual(empty.kind, .unauthorized)
        XCTAssertEqual(empty.displayDetail, "HTTP 401")
    }

    func test429WithCreditCodesIsOutOfCredit() {
        for code in ["insufficient_quota", "credit_balance_exhausted", "organization_spend_limit_exceeded", "project_spend_limit_exceeded", "organization_usage_limit_exceeded", "billing_hard_limit_reached"] {
            let json = #"{"error": {"message": "You exceeded your current quota, please check your plan and billing details.", "type": "x", "code": "\#(code)"}}"#
            let f = OpenAIWhisperService.failure(forStatus: 429, body: body(json), stage: nil)
            XCTAssertEqual(f.kind, .outOfCredit, "code \(code)")
            XCTAssertEqual(f.headline, "OpenAI account is out of credit or over its spend limit.")
        }
    }

    func test429WithRateLimitCodeIsRateLimited() {
        let json = #"{"error": {"message": "Rate limit reached for gpt-4o on requests per min (RPM): Limit 3, Used 3, Requested 1. Please try again in 20s.", "type": "requests", "param": null, "code": "rate_limit_exceeded"}}"#
        let f = OpenAIWhisperService.failure(forStatus: 429, body: body(json), stage: nil)
        XCTAssertEqual(f.kind, .rateLimited)
        XCTAssertEqual(f.headline, "OpenAI rate limit reached. Wait a moment and try again.")
    }

    func test429WithRateLimitMessageOnlyIsRateLimited() {
        let json = #"{"error": {"message": "Rate limit reached, slow down.", "type": null, "code": null}}"#
        XCTAssertEqual(OpenAIWhisperService.failure(forStatus: 429, body: body(json), stage: nil).kind, .rateLimited)
    }

    func test429UnclassifiedIsLimitedWithBodyAsDetail() {
        let json = #"{"error": {"message": "Slow down.", "type": "server_error", "code": "weird"}}"#
        let f = OpenAIWhisperService.failure(forStatus: 429, body: body(json), stage: nil)
        XCTAssertEqual(f.kind, .limited)
        XCTAssertEqual(f.headline, "OpenAI limited the request: out of credit or too many requests.")
        XCTAssertEqual(f.displayDetail, "Slow down.")

        let empty = OpenAIWhisperService.failure(forStatus: 429, body: Data(), stage: nil)
        XCTAssertEqual(empty.kind, .limited)
        XCTAssertEqual(empty.displayDetail, "HTTP 429")
    }

    func test5xxIsServerErrorAndHTMLBodyCollapsesToStatusLine() {
        let html = "<html><head><title>502 Bad Gateway</title></head><body>cloudflare</body></html>"
        let f = OpenAIWhisperService.failure(forStatus: 502, body: Data(html.utf8), stage: nil)
        XCTAssertEqual(f.kind, .serverError(502))
        XCTAssertEqual(f.headline, "OpenAI is having trouble (HTTP 502). Try again shortly.")
        XCTAssertEqual(f.displayDetail, "HTTP 502")

        XCTAssertEqual(OpenAIWhisperService.failure(forStatus: 503, body: Data(), stage: nil).kind, .serverError(503))
    }

    func test403FallsToGenericHTTPWithReasonInDetail() {
        let json = #"{"error": {"message": "Country, region, or territory not supported", "type": "request_forbidden", "code": "unsupported_country_region_territory"}}"#
        let f = OpenAIWhisperService.failure(forStatus: 403, body: body(json), stage: nil)
        XCTAssertEqual(f.kind, .http(403))
        XCTAssertEqual(f.headline, "Transcription failed (HTTP 403).")
        XCTAssertEqual(f.displayDetail, "Country, region, or territory not supported")

        let notFound = OpenAIWhisperService.failure(forStatus: 404, body: Data(), stage: nil)
        XCTAssertEqual(notFound.kind, .http(404))
        XCTAssertEqual(notFound.displayDetail, "HTTP 404")
    }

    func testTranscriptBodyEmptyOrWhitespaceIsEmptyTranscript() {
        XCTAssertEqual(try OpenAIWhisperService.transcript(from: Data("  hello \n".utf8), stage: nil), "hello")
        for body in ["", "  \n\t"] {
            XCTAssertThrowsError(try OpenAIWhisperService.transcript(from: Data(body.utf8), stage: .speechToText)) { error in
                guard case .failed(let f) = error as? TranscriptionError else { return XCTFail("\(error)") }
                XCTAssertEqual(f.kind, .emptyTranscript)
                XCTAssertEqual(f.headline, "Nothing recognised. Check the speech language or speak up.")
                XCTAssertEqual(f.displayDetail, "Speech-to-text: The transcript came back empty.")
            }
        }
        XCTAssertThrowsError(try OpenAIWhisperService.transcript(from: Data([0xFF, 0xFE]), stage: nil)) { error in
            guard case .failed(let f) = error as? TranscriptionError else { return XCTFail("\(error)") }
            XCTAssertEqual(f.kind, .unexpectedResponse)
        }
    }

    func testChatContentUnreadableOrEmptyIsUnexpectedResponse() {
        let good = #"{"choices": [{"message": {"role": "assistant", "content": " Cleaned. "}}]}"#
        XCTAssertEqual(try OpenAIWhisperService.chatContent(from: Data(good.utf8)), "Cleaned.")
        for (body, expectedDetail) in [(#"{"foo": 1}"#, #"Post-processing: {"foo": 1}"#), ("", "Post-processing: Empty response body."), ("<html>", "Post-processing: <html>")] {
            XCTAssertThrowsError(try OpenAIWhisperService.chatContent(from: Data(body.utf8))) { error in
                guard case .failed(let f) = error as? TranscriptionError else { return XCTFail("\(error)") }
                XCTAssertEqual(f.kind, .unexpectedResponse)
                XCTAssertEqual(f.displayDetail, expectedDetail)
            }
        }
        let emptyContent = #"{"choices": [{"message": {"content": "   "}}]}"#
        XCTAssertThrowsError(try OpenAIWhisperService.chatContent(from: Data(emptyContent.utf8))) { error in
            guard case .failed(let f) = error as? TranscriptionError else { return XCTFail("\(error)") }
            XCTAssertEqual(f.kind, .unexpectedResponse)
            XCTAssertEqual(f.displayDetail, "Post-processing: The model returned empty text.")
        }
    }

    func testJSONWithoutErrorMessageUsesRawBody() {
        let f = OpenAIWhisperService.failure(forStatus: 400, body: body(#"{"detail": "nope"}"#), stage: nil)
        XCTAssertEqual(f.kind, .http(400))
        XCTAssertEqual(f.displayDetail, #"{"detail": "nope"}"#)
    }

    func testDetailIsCappedAt500Characters() {
        let json = #"{"error": {"message": "\#(String(repeating: "x", count: 600))"}}"#
        let f = OpenAIWhisperService.failure(forStatus: 400, body: body(json), stage: nil)
        XCTAssertEqual(f.displayDetail.count, TranscriptionFailure.detailCap + 1)
        XCTAssertTrue(f.displayDetail.hasSuffix("…"))
    }

    // URLError built by hand carries only the generic "(NSURLErrorDomain error -N.)" description; the readable text
    // arrives only on errors a live URLSession produces. Assert on kind, never on the description.
    func testTransportErrorsMapToOfflineTimeoutOrOther() {
        for code in [URLError.notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed] {
            XCTAssertEqual(OpenAIWhisperService.failure(for: URLError(code), stage: nil).kind, .offline, "\(code)")
        }
        XCTAssertEqual(OpenAIWhisperService.failure(for: URLError(.timedOut), stage: nil).kind, .timedOut)
        XCTAssertEqual(OpenAIWhisperService.failure(for: URLError(.timedOut), stage: nil).headline, "The request timed out. Try again.")

        let tls = OpenAIWhisperService.failure(for: URLError(.secureConnectionFailed), stage: nil)
        guard case .other = tls.kind else { return XCTFail("expected .other, got \(tls.kind)") }
        XCTAssertTrue(tls.headline.hasPrefix("Transcription failed: "))

        let boom = OpenAIWhisperService.failure(for: NSError(domain: "x", code: 1, userInfo: [NSLocalizedDescriptionKey: "boom"]), stage: nil)
        XCTAssertEqual(boom.kind, .other("boom"))
        XCTAssertEqual(boom.headline, "Transcription failed: boom")
    }

    func testStagePrefixOnlyWhenStageIsSet() {
        let single = TranscriptionFailure(kind: .timedOut, stage: nil, detail: "The request timed out.")
        XCTAssertEqual(single.displayDetail, "The request timed out.")
        let stt = TranscriptionFailure(kind: .timedOut, stage: .speechToText, detail: "The request timed out.")
        XCTAssertEqual(stt.displayDetail, "Speech-to-text: The request timed out.")
        let post = OpenAIWhisperService.failure(forStatus: 500, body: Data(), stage: .postProcessing)
        XCTAssertEqual(post.displayDetail, "Post-processing: HTTP 500")
    }

    func testOnlyUnauthorizedHeadlineMentionsTheKey() {
        let kinds: [TranscriptionFailure.Kind] = [
            .offline, .timedOut, .unauthorized, .outOfCredit, .rateLimited, .limited,
            .serverError(503), .unexpectedResponse, .emptyTranscript, .http(403), .other("boom"),
        ]
        for kind in kinds {
            let headline = TranscriptionFailure(kind: kind, stage: nil, detail: "x").headline
            let mentionsKey = headline.range(of: "key", options: .caseInsensitive) != nil
            XCTAssertEqual(mentionsKey, kind == .unauthorized, "\(kind): \(headline)")
        }
        XCTAssertEqual(TranscriptionFailure(kind: .emptyTranscript, stage: nil, detail: "x").headline,
                       "Nothing recognised. Check the speech language or speak up.")
        XCTAssertEqual(TranscriptionFailure(kind: .unexpectedResponse, stage: nil, detail: "x").headline,
                       "OpenAI returned an unexpected response.")
    }
}
