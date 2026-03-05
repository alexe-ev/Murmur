import AppKit
import Carbon.HIToolbox
import Combine
import ServiceManagement
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private let permissionsManager = PermissionsManager.shared
    var menuBarController: MenuBarController?
    private let hotkeyManager = HotkeyManager()
    private let audioRecorder = AudioRecorder()
    private let pasteController = PasteController()
    var transcriptionService: TranscriptionService = LocalWhisperService()

    private let settingsModel = SettingsModel.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private var cancellables = Set<AnyCancellable>()
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var didEnterMainFlow = false
    private var isRecordingFlowActive = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        NSApp.setActivationPolicy(.accessory)
        print("Murmur started")

        settingsModel.launchAtLoginDidChange = { [weak self] enabled in
            self?.applyLaunchAtLogin(enabled)
        }
        observeBackendChanges()
        applyTranscriptionBackend()
        applyLaunchAtLogin(settingsModel.launchAtLogin)
        requestNotificationAuthorization()

        permissionsManager.checkAccessibility()
        if permissionsManager.allGranted {
            enterMainFlowIfNeeded()
        } else {
            presentOnboardingWindow()
        }
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        permissionsManager.checkAccessibility()
    }

    private func applyLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login state (enabled: \(enabled)): \(error)")
        }
    }

    func applyTranscriptionBackend() {
        let backend = settingsModel.whisperBackend
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch backend {
        case "api":
            transcriptionService = OpenAIWhisperService()
            if !transcriptionService.isAvailable {
                print("OpenAI API backend selected, but API key is missing in Keychain.")
            }
        case "local":
            fallthrough
        default:
            if backend != "local" {
                print("Unknown backend '\(settingsModel.whisperBackend)'; falling back to local.")
            }
            transcriptionService = LocalWhisperService()
            Task {
                do {
                    try await ModelManager.shared.loadModel()
                } catch is CancellationError {
                    return
                } catch {
                    print("Failed to load local Whisper model: \(error.localizedDescription)")
                }
            }
        }
    }

    private func observeBackendChanges() {
        settingsModel.$whisperBackend
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] _ in
                self?.applyTranscriptionBackend()
            }
            .store(in: &cancellables)
    }

    private func presentOnboardingWindow() {
        guard onboardingWindow == nil else { return }

        let onboardingView = OnboardingView { [weak self] in
            self?.completePermissionGatedStartup()
        }
        let hostingController = NSHostingController(rootView: onboardingView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 320),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "Murmur Permissions"
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .normal
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        onboardingWindow = window
    }

    private func completePermissionGatedStartup() {
        guard permissionsManager.allGranted else { return }
        closeOnboardingWindow()
        enterMainFlowIfNeeded()
    }

    private func closeOnboardingWindow() {
        onboardingWindow?.orderOut(nil)
        onboardingWindow?.close()
        onboardingWindow = nil
    }

    private func enterMainFlowIfNeeded() {
        guard !didEnterMainFlow else { return }
        didEnterMainFlow = true
        menuBarController = MenuBarController()

        hotkeyManager.onToggle = { [weak self] isRecording in
            if isRecording {
                self?.startRecordingFlow()
            } else {
                self?.stopRecordingFlow()
            }
        }

        reregisterHotkey()
    }

    func reregisterHotkey() {
        guard didEnterMainFlow else { return }

        let keyCode = UInt32(settingsModel.hotkeyKeyCode)
        let modifiers = UInt32(settingsModel.hotkeyModifiers)

        if isPotentiallyReservedHotkey(keyCode: keyCode, modifiers: modifiers) {
            print("Hotkey warning: selected shortcut may conflict with a reserved macOS shortcut.")
        }

        hotkeyManager.unregister()
        hotkeyManager.register(keyCode: keyCode, modifiers: modifiers)
    }

    private func startRecordingFlow() {
        guard !isRecordingFlowActive else { return }

        isRecordingFlowActive = true
        menuBarController?.setState(.recording)
        menuBarController?.showIndicator()
        menuBarController?.updateMenuItems(isRecording: true)

        do {
            try audioRecorder.startRecording()
            print("startRecordingFlow")
        } catch {
            isRecordingFlowActive = false
            menuBarController?.setState(.idle)
            menuBarController?.hideIndicator()
            menuBarController?.updateMenuItems(isRecording: false)
            showErrorNotification(error)
        }
    }

    private func stopRecordingFlow() {
        guard isRecordingFlowActive else { return }

        isRecordingFlowActive = false
        menuBarController?.setState(.processing)
        menuBarController?.hideIndicator()
        menuBarController?.updateMenuItems(isRecording: false)

        guard let audioURL = audioRecorder.stopRecording() else {
            menuBarController?.setState(.idle)
            showErrorNotification(TranscriptionError.audioFileNotFound)
            return
        }

        Task { [weak self] in
            guard let self else { return }

            do {
                let text = try await transcriptionService.transcribe(audioURL: audioURL, targetLanguage: nil)
                try pasteController.paste(text)
                menuBarController?.setState(.idle)
                print("stopRecordingFlow")
            } catch {
                showErrorNotification(error)
                menuBarController?.setState(.idle)
            }
        }
    }

    @objc
    func toggleRecordingFromMenu() {
        if isRecordingFlowActive {
            stopRecordingFlow()
        } else {
            startRecordingFlow()
        }
    }

    @objc
    func openSettings() {
        if settingsWindow == nil {
            let hostingController = NSHostingController(rootView: SettingsView())
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 520, height: 440),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.contentViewController = hostingController
            window.title = "Murmur Settings"
            window.isReleasedWhenClosed = false
            window.center()
            window.setContentSize(NSSize(width: 520, height: 440))
            window.minSize = NSSize(width: 520, height: 440)
            window.maxSize = NSSize(width: 520, height: 440)
            settingsWindow = window
        }

        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func isPotentiallyReservedHotkey(keyCode: UInt32, modifiers: UInt32) -> Bool {
        let normalizedModifiers = modifiers & UInt32(cmdKey | optionKey | controlKey | shiftKey)

        switch (keyCode, normalizedModifiers) {
        case (UInt32(kVK_Space), UInt32(cmdKey)),
             (UInt32(kVK_Space), UInt32(cmdKey | optionKey)),
             (UInt32(kVK_Space), UInt32(controlKey)),
             (UInt32(kVK_Tab), UInt32(cmdKey)),
             (UInt32(kVK_ANSI_Grave), UInt32(cmdKey)),
             (UInt32(kVK_ANSI_Grave), UInt32(cmdKey | shiftKey)):
            return true
        default:
            return false
        }
    }

    private func showErrorNotification(_ error: Error) {
        let content = UNMutableNotificationContent()
        content.title = "Murmur"
        content.sound = .default
        content.body = notificationMessage(for: error)

        let identifier = "murmur.error.\(UUID().uuidString)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        notificationCenter.add(request) { [weak self] addError in
            if let addError {
                print("Failed to show error notification: \(addError.localizedDescription)")
                return
            }

            // Keep error notifications short-lived and unobtrusive.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self?.notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
            }
        }

        print("Core flow error: \(content.body)")
    }

    private func requestNotificationAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error {
                print("Notification permission request failed: \(error.localizedDescription)")
                return
            }
            if !granted {
                print("Notification permission was denied.")
            }
        }
    }

    private func notificationMessage(for error: Error) -> String {
        if let transcriptionError = error as? TranscriptionError {
            switch transcriptionError {
            case .modelNotLoaded:
                return "Whisper model is not ready yet. Please wait."
            case .audioFileNotFound:
                return "Recording file was missing. Please try again."
            case .apiError:
                return "Transcription failed. Check your API key in Settings."
            case .cancelled:
                return "Transcription was cancelled. Please try again."
            }
        }

        if let pasteError = error as? PasteError {
            switch pasteError {
            case .accessibilityNotGranted:
                return "Accessibility permission needed. Open Settings."
            case .clipboardWriteFailed:
                return "Failed to paste into the focused app. Please try again."
            }
        }

        return "Something went wrong. Please try again."
    }

}
