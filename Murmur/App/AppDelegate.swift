import AppKit
import Carbon.HIToolbox
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    static weak var shared: AppDelegate?

    private let permissionsManager = PermissionsManager.shared
    // TODO: Add MenuBarController in E5.
    private var menuBarController: AnyObject?
    private let hotkeyManager = HotkeyManager()
    // TODO: Add AudioRecorder in E4.
    private var audioRecorder: AnyObject?
    // TODO: Add TranscriptionService in E6/E8.
    private var transcriptionService: AnyObject?

    private let settingsModel = SettingsModel.shared
    private var onboardingWindow: NSWindow?
    private var didEnterMainFlow = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        NSApp.setActivationPolicy(.accessory)
        print("Murmur started")

        settingsModel.launchAtLoginDidChange = { [weak self] enabled in
            self?.applyLaunchAtLogin(enabled)
        }
        applyLaunchAtLogin(settingsModel.launchAtLogin)

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
        print("startRecordingFlow")
    }

    private func stopRecordingFlow() {
        print("stopRecordingFlow")
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
}
