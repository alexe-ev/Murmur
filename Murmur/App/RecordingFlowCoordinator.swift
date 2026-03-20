import AppKit
import Foundation

@MainActor
final class RecordingFlowCoordinator {
    typealias MenuBarProvider = () -> MenuBarControlling?
    typealias TranscriptionHandler = (URL) async throws -> String?
    typealias ErrorHandler = (Error) -> Void
    typealias PasteTargetChecker = () -> Bool

    private let audioRecorder: AudioRecording
    private let pasteController: TextPasting
    private let menuBarProvider: MenuBarProvider
    private let transcriptionHandler: TranscriptionHandler
    private let errorHandler: ErrorHandler
    private let pasteTargetChecker: PasteTargetChecker

    private(set) var isRecordingFlowActive = false

    init(
        audioRecorder: AudioRecording,
        pasteController: TextPasting,
        menuBarProvider: @escaping MenuBarProvider,
        transcriptionHandler: @escaping TranscriptionHandler,
        errorHandler: @escaping ErrorHandler,
        pasteTargetChecker: @escaping PasteTargetChecker = RecordingFlowCoordinator.frontmostAppHasVisibleWindows
    ) {
        self.audioRecorder = audioRecorder
        self.pasteController = pasteController
        self.menuBarProvider = menuBarProvider
        self.transcriptionHandler = transcriptionHandler
        self.errorHandler = errorHandler
        self.pasteTargetChecker = pasteTargetChecker
    }

    func toggleRecording() {
        if isRecordingFlowActive {
            stopRecordingFlow()
        } else {
            startRecordingFlow()
        }
    }

    func cancelRecording() {
        guard isRecordingFlowActive else { return }

        isRecordingFlowActive = false

        if let audioURL = audioRecorder.stopRecording() {
            cleanupTemporaryAudioFile(at: audioURL)
        }

        menuBarProvider()?.setState(.idle)
        print("[Murmur] cancelRecordingFlow")
    }

    private func startRecordingFlow() {
        guard !isRecordingFlowActive else { return }

        isRecordingFlowActive = true
        menuBarProvider()?.setState(.recording)

        do {
            try audioRecorder.startRecording()
            print("[Murmur] startRecordingFlow")
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
            errorHandler(TranscriptionError.audioFileNotFound)
            menuBarProvider()?.setState(.error(Self.shortErrorMessage(TranscriptionError.audioFileNotFound)))
            return
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int64) ?? 0
        let fileSizeMB = Double(fileSize) / 1_048_576
        let estimatedDuration = Double(fileSize) / 32_000
        print("[Murmur] Audio file: \(String(format: "%.1f", fileSizeMB)) MB, ~\(Int(estimatedDuration))s")

        // Skip transcription if no speech was detected (silence only)
        guard audioRecorder.hasDetectedSpeech else {
            cleanupTemporaryAudioFile(at: audioURL)
            menuBarProvider()?.setState(.idle)
            print("[Murmur] stopRecordingFlow: no speech detected, skipping transcription")
            return
        }

        Task { [weak self] in
            guard let self else { return }
            defer { cleanupTemporaryAudioFile(at: audioURL) }

            let text: String
            do {
                guard let result = try await transcriptionHandler(audioURL) else {
                    print("[Murmur] Transcription returned nil")
                    menuBarProvider()?.setState(.idle)
                    return
                }
                text = result
            } catch {
                print("[Murmur] Transcription error: \(error)")
                errorHandler(error)
                menuBarProvider()?.setState(.error(Self.shortErrorMessage(error)))
                return
            }

            menuBarProvider()?.setLastTranscript(text)
            print("[Murmur] Transcription complete, \(text.count) characters")

            do {
                let pasteResult = try pasteController.paste(text)
                switch pasteResult {
                case .directInsert:
                    menuBarProvider()?.setState(.idle)
                    print("[Murmur] Paste complete (AX direct)")
                case .clipboard:
                    menuBarProvider()?.setState(.idle)
                    print("[Murmur] Paste complete (Cmd+V fallback)")
                case .noFocusedElement:
                    if pasteTargetChecker() {
                        menuBarProvider()?.setState(.idle)
                        print("[Murmur] AX missed focus, but frontmost app has windows")
                    } else {
                        menuBarProvider()?.setState(.uncertain)
                        print("[Murmur] No focused element, no visible windows, showing popup")
                    }
                }
            } catch {
                print("[Murmur] Paste error: \(error)")
                errorHandler(error)
                menuBarProvider()?.setState(.error(Self.shortErrorMessage(error)))
            }
        }
    }

    private static func shortErrorMessage(_ error: Error) -> String {
        if let te = error as? TranscriptionError {
            switch te {
            case .audioFileNotFound:
                return "Recording file missing"
            case .apiError(let detail):
                return "API error: \(String(detail.prefix(80)))"
            case .cancelled:
                return "Cancelled"
            case .fileTooLarge(let sizeMB):
                return "Too large: \(String(format: "%.0f", sizeMB)) MB (max 25 MB)"
            }
        }
        if let pe = error as? PasteError {
            switch pe {
            case .accessibilityNotGranted:
                return "Accessibility permission needed"
            case .clipboardWriteFailed:
                return "Paste failed"
            }
        }
        return String(error.localizedDescription.prefix(60))
    }

    private static func frontmostAppHasVisibleWindows() -> Bool {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return false
        }
        let pid = frontApp.processIdentifier
        guard let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            return false
        }
        return windowList.contains { info in
            (info[kCGWindowOwnerPID as String] as? pid_t) == pid
                && (info[kCGWindowLayer as String] as? Int) == 0
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
