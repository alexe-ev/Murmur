import AppKit
import Combine
import ServiceManagement
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let permissionsManager = PermissionsManager.shared
    // TODO: Add MenuBarController in E5.
    private var menuBarController: AnyObject?
    // TODO: Add HotkeyManager in E3.
    private var hotkeyManager: AnyObject?
    // TODO: Add AudioRecorder in E4.
    private var audioRecorder: AnyObject?
    // TODO: Add TranscriptionService in E6/E8.
    private var transcriptionService: AnyObject?

    private let settingsModel = SettingsModel.shared
    private var onboardingWindow: NSWindow?
    private var didEnterMainFlow = false

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        // TODO: Continue startup pipeline in later epics (MenuBarController, HotkeyManager, etc.).
    }
}
