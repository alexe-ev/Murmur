import XCTest
@testable import Murmur

// MARK: - Mocks

@MainActor
final class MockAudioRecorder: AudioRecording {
    var startRecordingError: Error?
    var stopRecordingURL: URL?
    var hasDetectedSpeech: Bool = true
    var startRecordingCallCount = 0
    var stopRecordingCallCount = 0

    func startRecording() throws {
        startRecordingCallCount += 1
        if let error = startRecordingError {
            throw error
        }
    }

    func stopRecording() -> URL? {
        stopRecordingCallCount += 1
        return stopRecordingURL
    }
}

@MainActor
final class MockPasteController: TextPasting {
    var pasteError: Error?
    var pasteResult: PasteResult = .directInsert
    var pastedTexts: [String] = []

    @discardableResult
    func paste(_ text: String) throws -> PasteResult {
        pastedTexts.append(text)
        if let error = pasteError {
            throw error
        }
        return pasteResult
    }
}

@MainActor
final class MockMenuBarController: MenuBarControlling {
    var states: [MenuBarState] = []
    var lastTranscripts: [String] = []

    func setState(_ state: MenuBarState) {
        states.append(state)
    }

    func setLastTranscript(_ text: String) {
        lastTranscripts.append(text)
    }
}

// MARK: - Tests

@MainActor
final class RecordingFlowCoordinatorTests: XCTestCase {
    private var recorder: MockAudioRecorder!
    private var paster: MockPasteController!
    private var menuBar: MockMenuBarController!
    private var errors: [Error]!
    private var sut: RecordingFlowCoordinator!

    private var transcriptionResult: String?
    private var transcriptionError: Error?
    private var transcriptionCallCount: Int = 0
    private var mockHasVisibleWindows: Bool = false

    override func setUp() {
        super.setUp()
        recorder = MockAudioRecorder()
        paster = MockPasteController()
        menuBar = MockMenuBarController()
        errors = []
        transcriptionResult = "Transcribed text"
        transcriptionError = nil
        transcriptionCallCount = 0

        sut = RecordingFlowCoordinator(
            audioRecorder: recorder,
            pasteController: paster,
            menuBarProvider: { [weak self] in self?.menuBar },
            transcriptionHandler: { [weak self] _ in
                self?.transcriptionCallCount += 1
                if let error = self?.transcriptionError {
                    throw error
                }
                return self?.transcriptionResult
            },
            errorHandler: { [weak self] error in
                self?.errors.append(error)
            },
            pasteTargetChecker: { [weak self] in
                self?.mockHasVisibleWindows ?? false
            }
        )
    }

    private func createTempAudioFile() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("murmur_test_\(UUID().uuidString).wav")
        FileManager.default.createFile(atPath: url.path, contents: Data(repeating: 0, count: 1024))
        return url
    }

    // MARK: - Start Recording

    func testToggleStartsRecording() {
        sut.toggleRecording()

        XCTAssertTrue(sut.isRecordingFlowActive)
        XCTAssertEqual(recorder.startRecordingCallCount, 1)
        XCTAssertEqual(menuBar.states, [.recording])
    }

    func testStartRecordingFailureSetsIdle() {
        recorder.startRecordingError = NSError(domain: "test", code: 1)

        sut.toggleRecording()

        XCTAssertFalse(sut.isRecordingFlowActive)
        XCTAssertEqual(menuBar.states, [.recording, .idle])
        XCTAssertEqual(errors.count, 1)
    }

    // MARK: - Stop Recording: audioURL nil

    func testStopWithNilAudioURLSetsErrorState() {
        recorder.stopRecordingURL = nil

        // Start then stop
        sut.toggleRecording()
        menuBar.states.removeAll()
        errors.removeAll()

        sut.toggleRecording()

        XCTAssertFalse(sut.isRecordingFlowActive)
        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(errors.first is TranscriptionError)

        // Key check: error state, NOT idle
        guard case .error = menuBar.states.last else {
            XCTFail("Expected .error state, got \(String(describing: menuBar.states.last))")
            return
        }
    }

    // MARK: - Stop Recording: no speech detected

    func testStopWithNoSpeechSetsIdle() {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        recorder.hasDetectedSpeech = false

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.toggleRecording()

        XCTAssertEqual(menuBar.states, [.processing, .idle])
        XCTAssertEqual(transcriptionCallCount, 0)
    }

    // MARK: - Happy path: transcription + paste

    func testSuccessfulTranscriptionPastesAndSetsIdle() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionResult = "Hello world"

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.toggleRecording()

        // Wait for async Task to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(paster.pastedTexts, ["Hello world"])
        XCTAssertEqual(menuBar.lastTranscripts, ["Hello world"])
        XCTAssertTrue(menuBar.states.contains(.idle))
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - Transcription error sets .error state

    func testTranscriptionErrorSetsErrorState() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionError = TranscriptionError.apiError("timeout")

        sut.toggleRecording()
        menuBar.states.removeAll()
        errors.removeAll()

        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(errors.count, 1)
        XCTAssertTrue(paster.pastedTexts.isEmpty)
        XCTAssertTrue(menuBar.lastTranscripts.isEmpty)

        guard case .error(let message) = menuBar.states.last else {
            XCTFail("Expected .error state, got \(String(describing: menuBar.states.last))")
            return
        }
        XCTAssertTrue(message.contains("API error"), "Error message was: \(message)")
    }

    // MARK: - Transcription returns nil

    func testTranscriptionReturnsNilSetsIdle() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionResult = nil

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(menuBar.states.last, .idle)
        XCTAssertTrue(paster.pastedTexts.isEmpty)
        XCTAssertTrue(menuBar.lastTranscripts.isEmpty)
    }

    // MARK: - Paste via clipboard sets idle (no popup)

    func testPasteViaClipboardSetsIdle() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionResult = "Hello world"
        paster.pasteResult = .clipboard

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(paster.pastedTexts, ["Hello world"])
        XCTAssertEqual(menuBar.states.last, .idle)
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - No focused element shows uncertain popup

    func testNoFocusedElementSetsUncertain() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionResult = "Hello world"
        paster.pasteResult = .noFocusedElement

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(paster.pastedTexts, ["Hello world"])
        XCTAssertEqual(menuBar.states.last, .uncertain)
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - No focused element but frontmost app has windows sets idle

    func testNoFocusedElementWithVisibleWindowsSetsIdle() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionResult = "Hello world"
        paster.pasteResult = .noFocusedElement
        mockHasVisibleWindows = true

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(paster.pastedTexts, ["Hello world"])
        XCTAssertEqual(menuBar.states.last, .idle)
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - Paste error: transcript saved, error state shown

    func testPasteErrorPreservesTranscriptAndSetsErrorState() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionResult = "Important text that must not be lost"
        paster.pasteError = PasteError.clipboardWriteFailed

        sut.toggleRecording()
        menuBar.states.removeAll()
        errors.removeAll()

        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        // Transcript was saved BEFORE paste was attempted
        XCTAssertEqual(menuBar.lastTranscripts, ["Important text that must not be lost"])

        // Error was reported
        XCTAssertEqual(errors.count, 1)

        // State is .error, not .idle
        guard case .error(let message) = menuBar.states.last else {
            XCTFail("Expected .error state, got \(String(describing: menuBar.states.last))")
            return
        }
        XCTAssertTrue(message.contains("Paste failed"), "Error message was: \(message)")
    }

    // MARK: - File too large error

    func testFileTooLargeErrorMessage() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionError = TranscriptionError.fileTooLarge(sizeMB: 30.0)

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        guard case .error(let message) = menuBar.states.last else {
            XCTFail("Expected .error state")
            return
        }
        XCTAssertTrue(message.contains("Too large"), "Error message was: \(message)")
        XCTAssertTrue(message.contains("30"), "Should include size in message: \(message)")
    }

    // MARK: - Cancel recording

    func testCancelRecordingSetsIdle() {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url

        sut.toggleRecording()
        menuBar.states.removeAll()

        sut.cancelRecording()

        XCTAssertFalse(sut.isRecordingFlowActive)
        XCTAssertEqual(menuBar.states, [.idle])
        XCTAssertEqual(recorder.stopRecordingCallCount, 1)
    }

    func testCancelWhenNotRecordingDoesNothing() {
        sut.cancelRecording()

        XCTAssertTrue(menuBar.states.isEmpty)
        XCTAssertEqual(recorder.stopRecordingCallCount, 0)
    }

    // MARK: - Temp file cleanup

    func testTempFileCleanedUpAfterSuccess() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url

        sut.toggleRecording()
        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testTempFileCleanedUpAfterError() async throws {
        let url = createTempAudioFile()
        recorder.stopRecordingURL = url
        transcriptionError = TranscriptionError.apiError("fail")

        sut.toggleRecording()
        sut.toggleRecording()

        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
