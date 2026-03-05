import AppKit
import AVFoundation
import Foundation

@MainActor
final class PermissionsManager: ObservableObject {
    static let shared = PermissionsManager()

    @Published private(set) var microphoneStatus: AVAuthorizationStatus
    @Published private(set) var accessibilityGranted: Bool

    var microphoneGranted: Bool {
        microphoneStatus == .authorized
    }

    var allGranted: Bool {
        microphoneGranted && accessibilityGranted
    }

    private var accessibilityPollTimer: Timer?
    private let accessibilitySettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!

    private init() {
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        accessibilityGranted = AXIsProcessTrusted()
    }

    func requestMicrophone() async {
        let currentStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if currentStatus == .notDetermined {
            _ = await withCheckedContinuation { continuation in
                AVCaptureDevice.requestAccess(for: .audio) { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    }

    func checkAccessibility() {
        accessibilityGranted = AXIsProcessTrusted()
    }

    func openAccessibilitySettings() {
        NSWorkspace.shared.open(accessibilitySettingsURL)
    }

    func startAccessibilityPolling() {
        guard accessibilityPollTimer == nil else { return }

        accessibilityPollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAccessibility()
            }
        }
        if let accessibilityPollTimer {
            RunLoop.main.add(accessibilityPollTimer, forMode: .common)
        }
        checkAccessibility()
    }

    func stopAccessibilityPolling() {
        accessibilityPollTimer?.invalidate()
        accessibilityPollTimer = nil
    }

    deinit {
        accessibilityPollTimer?.invalidate()
    }
}
