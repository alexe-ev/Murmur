import AppKit
import Carbon.HIToolbox
import ServiceManagement
import SwiftUI
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private let permissionsManager = PermissionsManager.shared
    var menuBarController: MenuBarController?
    private let hotkeyManager = HotkeyManager()

    private let settingsModel = SettingsModel.shared
    private let translationConfig = TranslationConfig.shared
    private let notificationCenter = UNUserNotificationCenter.current()
    private lazy var transcriptionCoordinator = TranscriptionCoordinator(
        settingsModel: settingsModel,
        translationConfig: translationConfig
    )
    private var recordingFlowCoordinator: RecordingFlowCoordinator?
    private var onboardingWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var didEnterMainFlow = false
    private var isMissingAPIKeyAlertPresented = false
    private var hasPresentedHotkeyIssueAlert = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        NSApp.setActivationPolicy(.accessory)
        print("Murmur started")

        settingsModel.launchAtLoginDidChange = { [weak self] enabled in
            self?.applyLaunchAtLogin(enabled)
        }
        transcriptionCoordinator.onMissingAPIKey = { [weak self] in
            self?.promptForMissingAPIKey()
        }
        transcriptionCoordinator.start()
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
        configureRecordingFlowCoordinator()

        hotkeyManager.onToggleRequest = { [weak self] in
            self?.toggleRecordingFromHotkey()
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
        if hotkeyManager.register(keyCode: keyCode, modifiers: modifiers) {
            return
        }

        for candidate in fallbackHotkeyCandidates(primaryKeyCode: keyCode, primaryModifiers: modifiers) {
            if hotkeyManager.register(keyCode: candidate.keyCode, modifiers: candidate.modifiers) {
                let fallbackDisplay = hotkeyDisplayString(keyCode: candidate.keyCode, modifiers: candidate.modifiers)
                presentHotkeyIssueAlert(
                    title: "Selected hotkey is unavailable.",
                    message: "Murmur temporarily switched to \(fallbackDisplay). Open Settings to choose another shortcut."
                )
                return
            }
        }

        presentHotkeyIssueAlert(
            title: "Failed to register global hotkey.",
            message: "Open Settings and choose a different hotkey."
        )
    }

    private func configureRecordingFlowCoordinator() {
        recordingFlowCoordinator = RecordingFlowCoordinator(
            audioRecorder: AudioRecorder(),
            pasteController: PasteController(),
            menuBarProvider: { [weak self] in
                self?.menuBarController
            },
            transcriptionHandler: { [weak self] audioURL in
                guard let self else { return nil }
                return try await self.transcriptionCoordinator.transcribe(audioURL: audioURL)
            },
            errorHandler: { [weak self] error in
                self?.showErrorNotification(error)
            }
        )
    }

    private func toggleRecordingFromHotkey() {
        recordingFlowCoordinator?.toggleRecording()
    }

    @objc
    func toggleRecordingFromMenu() {
        toggleRecordingFromHotkey()
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

    private func fallbackHotkeyCandidates(primaryKeyCode: UInt32, primaryModifiers: UInt32) -> [(keyCode: UInt32, modifiers: UInt32)] {
        let optionControl = UInt32(optionKey | controlKey)
        let optionControlCommand = UInt32(optionKey | controlKey | cmdKey)

        let preferred: [(UInt32, UInt32)] = [
            (primaryKeyCode, optionControl),
            (primaryKeyCode, optionControlCommand),
            (UInt32(kVK_Space), optionControl),
            (UInt32(kVK_ANSI_Grave), optionControl)
        ]

        var unique: [(UInt32, UInt32)] = []
        for candidate in preferred {
            if candidate.0 == primaryKeyCode && candidate.1 == primaryModifiers {
                continue
            }
            if unique.contains(where: { $0.0 == candidate.0 && $0.1 == candidate.1 }) {
                continue
            }
            unique.append(candidate)
        }
        return unique
    }

    private func hotkeyDisplayString(keyCode: UInt32, modifiers: UInt32) -> String {
        let normalized = modifiers & UInt32(cmdKey | optionKey | controlKey | shiftKey)
        var symbols = ""

        if normalized & UInt32(controlKey) != 0 { symbols.append("⌃") }
        if normalized & UInt32(optionKey) != 0 { symbols.append("⌥") }
        if normalized & UInt32(shiftKey) != 0 { symbols.append("⇧") }
        if normalized & UInt32(cmdKey) != 0 { symbols.append("⌘") }

        let keyName: String
        switch keyCode {
        case UInt32(kVK_Space):
            keyName = "Space"
        case UInt32(kVK_ANSI_Grave):
            keyName = "`"
        case UInt32(kVK_Tab):
            keyName = "Tab"
        default:
            keyName = "Key \(keyCode)"
        }

        return symbols + keyName
    }

    private func presentHotkeyIssueAlert(title: String, message: String) {
        guard !hasPresentedHotkeyIssueAlert else { return }
        hasPresentedHotkeyIssueAlert = true

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openSettings()
        }
    }

    private func promptForMissingAPIKey() {
        if settingsWindow?.isVisible == true {
            return
        }

        guard !isMissingAPIKeyAlertPresented else { return }
        isMissingAPIKeyAlertPresented = true
        defer { isMissingAPIKeyAlertPresented = false }

        let alert = NSAlert()
        alert.messageText = "Translation requires an OpenAI API key."
        alert.informativeText = "Open Settings?"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            openSettings()
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
