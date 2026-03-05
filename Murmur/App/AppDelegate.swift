import AppKit
import Combine
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    // TODO: Add PermissionsManager in E2.
    private var permissionsManager: AnyObject?
    // TODO: Add MenuBarController in E5.
    private var menuBarController: AnyObject?
    // TODO: Add HotkeyManager in E3.
    private var hotkeyManager: AnyObject?
    // TODO: Add AudioRecorder in E4.
    private var audioRecorder: AnyObject?
    // TODO: Add TranscriptionService in E6/E8.
    private var transcriptionService: AnyObject?

    private let settingsModel = SettingsModel.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        print("Murmur started")

        settingsModel.launchAtLoginDidChange = { [weak self] enabled in
            self?.applyLaunchAtLogin(enabled)
        }
        applyLaunchAtLogin(settingsModel.launchAtLogin)
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
}
