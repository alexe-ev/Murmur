import Foundation

@MainActor
final class RecordingFlowCoordinator {
    typealias MenuBarProvider = () -> MenuBarController?
    typealias TranscriptionHandler = (URL) async throws -> String?
    typealias ErrorHandler = (Error) -> Void

    private let audioRecorder: AudioRecorder
    private let pasteController: PasteController
    private let menuBarProvider: MenuBarProvider
    private let transcriptionHandler: TranscriptionHandler
    private let errorHandler: ErrorHandler

    private var isRecordingFlowActive = false

    init(
        audioRecorder: AudioRecorder,
        pasteController: PasteController,
        menuBarProvider: @escaping MenuBarProvider,
        transcriptionHandler: @escaping TranscriptionHandler,
        errorHandler: @escaping ErrorHandler
    ) {
        self.audioRecorder = audioRecorder
        self.pasteController = pasteController
        self.menuBarProvider = menuBarProvider
        self.transcriptionHandler = transcriptionHandler
        self.errorHandler = errorHandler
    }

    func toggleRecording() {
        if isRecordingFlowActive {
            stopRecordingFlow()
        } else {
            startRecordingFlow()
        }
    }

    private func startRecordingFlow() {
        guard !isRecordingFlowActive else { return }

        isRecordingFlowActive = true
        menuBarProvider()?.setState(.recording)

        do {
            try audioRecorder.startRecording()
            print("startRecordingFlow")
        } catch {
            isRecordingFlowActive = false
            menuBarProvider()?.setState(.idle)
            errorHandler(error)
        }
    }

    private func stopRecordingFlow() {
        guard isRecordingFlowActive else { return }

        isRecordingFlowActive = false
        menuBarProvider()?.setState(.processing)

        guard let audioURL = audioRecorder.stopRecording() else {
            menuBarProvider()?.setState(.idle)
            errorHandler(TranscriptionError.audioFileNotFound)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            defer { cleanupTemporaryAudioFile(at: audioURL) }

            do {
                guard let text = try await transcriptionHandler(audioURL) else {
                    menuBarProvider()?.setState(.idle)
                    return
                }

                try pasteController.paste(text)
                menuBarProvider()?.setState(.idle)
                print("stopRecordingFlow")
            } catch {
                errorHandler(error)
                menuBarProvider()?.setState(.idle)
            }
        }
    }

    private func cleanupTemporaryAudioFile(at audioURL: URL) {
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            return
        }

        do {
            try FileManager.default.removeItem(at: audioURL)
        } catch {
            print("Failed to remove temporary audio file at \(audioURL.path): \(error.localizedDescription)")
        }
    }
}
