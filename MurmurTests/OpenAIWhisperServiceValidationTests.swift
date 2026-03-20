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
            // apiError("No API key") is acceptable if the file size check passes
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
            // Should get apiError (no key), NOT fileTooLarge
            guard case .apiError = error else {
                XCTFail("Expected apiError (no key), got \(error)")
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
