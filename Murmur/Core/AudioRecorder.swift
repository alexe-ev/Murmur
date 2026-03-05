import AVFoundation
import Combine
import Foundation

final class AudioRecorder {
    enum RecordingState {
        case idle
        case recording
        case ready(URL)
    }

    enum AudioRecorderError: LocalizedError {
        case microphonePermissionDenied
        case alreadyRecording
        case converterCreationFailed
        case outputFileCreationFailed(Error)
        case engineStartFailed(Error)

        var errorDescription: String? {
            switch self {
            case .microphonePermissionDenied:
                return "Microphone permission is not granted."
            case .alreadyRecording:
                return "AudioRecorder is already recording."
            case .converterCreationFailed:
                return "Failed to create audio converter for 16kHz mono PCM."
            case .outputFileCreationFailed(let error):
                return "Failed to create output WAV file: \(error.localizedDescription)"
            case .engineStartFailed(let error):
                return "Failed to start audio engine: \(error.localizedDescription)"
            }
        }
    }

    private let audioEngine = AVAudioEngine()
    private let ioLock = NSLock()

    @Published private(set) var state: RecordingState = .idle

    var statePublisher: AnyPublisher<RecordingState, Never> {
        $state
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private var converter: AVAudioConverter?
    private var outputFile: AVAudioFile?
    private var currentTempURL: URL?
    private var lastCompletedURL: URL?
    private var isRecording = false

    private var outputFormat: AVAudioFormat {
        AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16_000, channels: 1, interleaved: true)!
    }

    @MainActor
    func startRecording() throws {
        guard PermissionsManager.shared.microphoneGranted else {
            throw AudioRecorderError.microphonePermissionDenied
        }

        guard !isRecording else {
            throw AudioRecorderError.alreadyRecording
        }

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw AudioRecorderError.converterCreationFailed
        }

        deleteCurrentRecording()

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("murmur_\(UUID().uuidString).wav")

        let file: AVAudioFile
        do {
            file = try AVAudioFile(
                forWriting: tempURL,
                settings: outputFormat.settings,
                commonFormat: outputFormat.commonFormat,
                interleaved: outputFormat.isInterleaved
            )
        } catch {
            throw AudioRecorderError.outputFileCreationFailed(error)
        }

        ioLock.lock()
        self.converter = converter
        self.outputFile = file
        self.currentTempURL = tempURL
        ioLock.unlock()

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processInputBuffer(buffer, inputFormat: inputFormat)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            isRecording = true
            state = .recording
        } catch {
            cleanupAfterFailedStart(inputNode: inputNode)
            throw AudioRecorderError.engineStartFailed(error)
        }
    }

    @MainActor
    func stopRecording() -> URL? {
        guard isRecording else {
            return nil
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        ioLock.lock()
        let completedURL = currentTempURL
        outputFile = nil
        lastCompletedURL = completedURL
        currentTempURL = nil
        converter = nil
        ioLock.unlock()

        isRecording = false
        if let completedURL {
            state = .ready(completedURL)
        } else {
            state = .idle
        }
        return completedURL
    }

    @MainActor
    func deleteCurrentRecording() {
        guard !isRecording else {
            return
        }

        ioLock.lock()
        let urlToDelete = currentTempURL
        currentTempURL = nil
        let completedURLToDelete = lastCompletedURL
        lastCompletedURL = nil
        ioLock.unlock()

        do {
            if let urlToDelete, FileManager.default.fileExists(atPath: urlToDelete.path) {
                try FileManager.default.removeItem(at: urlToDelete)
            }
            if let completedURLToDelete, FileManager.default.fileExists(atPath: completedURLToDelete.path) {
                try FileManager.default.removeItem(at: completedURLToDelete)
            }
        } catch {
            print("AudioRecorder delete error: \(error.localizedDescription)")
        }

        state = .idle
    }

    private func processInputBuffer(_ buffer: AVAudioPCMBuffer, inputFormat: AVAudioFormat) {
        ioLock.lock()
        defer { ioLock.unlock() }

        guard let converter, let outputFile else {
            return
        }

        let ratio = outputFormat.sampleRate / inputFormat.sampleRate
        let outputCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio + 1)

        guard let convertedBuffer = AVAudioPCMBuffer(
            pcmFormat: outputFormat,
            frameCapacity: max(1, outputCapacity)
        ) else {
            return
        }

        var hasConsumedInput = false
        var conversionError: NSError?

        let status = converter.convert(to: convertedBuffer, error: &conversionError) { _, outStatus in
            if hasConsumedInput {
                outStatus.pointee = .noDataNow
                return nil
            }

            hasConsumedInput = true
            outStatus.pointee = .haveData
            return buffer
        }

        guard conversionError == nil, status != .error, convertedBuffer.frameLength > 0 else {
            if let conversionError {
                print("AudioRecorder conversion error: \(conversionError.localizedDescription)")
            }
            handleRuntimeRecordingError()
            return
        }

        do {
            try outputFile.write(from: convertedBuffer)
        } catch {
            print("AudioRecorder write error: \(error.localizedDescription)")
            handleRuntimeRecordingError()
        }
    }

    private func handleRuntimeRecordingError() {
        DispatchQueue.main.async { [weak self] in
            self?.stopRecordingDueToError()
        }
    }

    @MainActor
    private func stopRecordingDueToError() {
        guard isRecording else {
            state = .idle
            return
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        ioLock.lock()
        outputFile = nil
        currentTempURL = nil
        lastCompletedURL = nil
        converter = nil
        ioLock.unlock()

        isRecording = false
        state = .idle
    }

    private func cleanupAfterFailedStart(inputNode: AVAudioInputNode) {
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()

        ioLock.lock()
        if let currentTempURL {
            try? FileManager.default.removeItem(at: currentTempURL)
        }
        outputFile = nil
        currentTempURL = nil
        lastCompletedURL = nil
        converter = nil
        ioLock.unlock()

        isRecording = false
        state = .idle
    }
}
