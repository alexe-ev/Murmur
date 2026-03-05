import Combine
import Foundation

#if arch(arm64)
import WhisperKit
#endif

@MainActor
final class ModelManager: ObservableObject {
    static let shared = ModelManager()

    @Published private(set) var isModelLoaded = false
    @Published private(set) var isDownloading = false
    @Published private(set) var downloadProgress: Double = 0

#if arch(arm64)
    private(set) var whisperKit: WhisperKit?
#else
    private(set) var whisperKit: AnyObject?
#endif

    private let settings: SettingsModel
    private let fileManager: FileManager
    private var cancellables = Set<AnyCancellable>()
    private var currentModelVariant: String?
    private var reloadTask: Task<Void, Never>?

    private init(settings: SettingsModel = .shared, fileManager: FileManager = .default) {
        self.settings = settings
        self.fileManager = fileManager
        observeModelSelectionChanges()
    }

    func loadModel() async throws {
#if arch(arm64)
        let selectedVariant = settings.whisperModel.rawValue

        if isModelLoaded, currentModelVariant == selectedVariant, whisperKit != nil {
            return
        }

        isModelLoaded = false
        downloadProgress = 0

        let modelsRootURL = try modelsDirectoryURL()
        let modelFolderURL: URL

        if let existingFolder = existingModelFolder(for: selectedVariant, in: modelsRootURL) {
            modelFolderURL = existingFolder
            isDownloading = false
        } else {
            isDownloading = true
            modelFolderURL = try await WhisperKit.download(
                variant: selectedVariant,
                downloadBase: modelsRootURL,
                useBackgroundSession: false,
                progressCallback: { [weak self] progress in
                    Task { @MainActor in
                        self?.downloadProgress = progress.fractionCompleted
                    }
                }
            )
            isDownloading = false
            downloadProgress = 1
        }

        let loadedWhisperKit = try await WhisperKit(
            model: selectedVariant,
            modelFolder: modelFolderURL.path,
            load: true,
            download: false,
            useBackgroundDownloadSession: false
        )

        whisperKit = loadedWhisperKit
        currentModelVariant = selectedVariant
        isModelLoaded = loadedWhisperKit.modelState == .loaded
#else
        throw ModelManagerError.unsupportedArchitecture
#endif
    }

    private func observeModelSelectionChanges() {
        settings.$whisperModel
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }

                self.reloadTask?.cancel()
                self.isModelLoaded = false

                self.reloadTask = Task { [weak self] in
                    guard let self else { return }

                    do {
                        try await self.loadModel()
                    } catch is CancellationError {
                        return
                    } catch {
                        self.whisperKit = nil
                        self.currentModelVariant = nil
                        self.isDownloading = false
                        self.downloadProgress = 0
                        self.isModelLoaded = false
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func modelsDirectoryURL() throws -> URL {
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )

        let modelsURL = appSupportURL
            .appendingPathComponent("Murmur", isDirectory: true)
            .appendingPathComponent("models", isDirectory: true)

        if !fileManager.fileExists(atPath: modelsURL.path) {
            try fileManager.createDirectory(at: modelsURL, withIntermediateDirectories: true)
        }

        return modelsURL
    }

    private func existingModelFolder(for variant: String, in modelsRootURL: URL) -> URL? {
        guard let enumerator = fileManager.enumerator(
            at: modelsRootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return nil
        }

        for case let candidateURL as URL in enumerator {
            var isDirectory = ObjCBool(false)
            guard fileManager.fileExists(atPath: candidateURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }

            if !candidateURL.lastPathComponent.lowercased().contains(variant) {
                continue
            }

            if modelArtifactsExist(in: candidateURL) {
                return candidateURL
            }
        }

        return nil
    }

    private func modelArtifactsExist(in folderURL: URL) -> Bool {
        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return false
        }

        var modelBundleCount = 0

        for case let itemURL as URL in enumerator where itemURL.pathExtension == "mlmodelc" {
            modelBundleCount += 1
            if modelBundleCount >= 3 {
                return true
            }
        }

        return false
    }

}

enum ModelManagerError: LocalizedError {
    case unsupportedArchitecture

    var errorDescription: String? {
        switch self {
        case .unsupportedArchitecture:
            return "WhisperKit is available only on arm64 builds."
        }
    }
}
