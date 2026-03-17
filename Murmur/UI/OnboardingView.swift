import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    let onAllGranted: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(9)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Murmur")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                    Text("Grant permissions to start voice-to-text flow.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Microphone
            permissionRow(
                icon: "mic.fill",
                title: "Microphone",
                description: "Capture your voice for transcription.",
                granted: permissionsManager.microphoneGranted,
                buttonTitle: "Grant Access"
            ) {
                Task {
                    await permissionsManager.requestMicrophone()
                }
            }

            // Accessibility
            permissionRow(
                icon: "accessibility",
                title: "Accessibility",
                description: "Paste transcribed text into the focused app.",
                hint: "After clicking Open Settings, find Murmur in the list and enable it manually.",
                granted: permissionsManager.accessibilityGranted,
                buttonTitle: "Open Settings"
            ) {
                permissionsManager.openAccessibilitySettings()
            }

            Text("After granting access, return to this window. The app will continue automatically.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(width: 480, height: 340)
        .background(.ultraThinMaterial)
        .onAppear {
            permissionsManager.checkAccessibility()
            permissionsManager.startAccessibilityPolling()
        }
        .onDisappear {
            permissionsManager.stopAccessibilityPolling()
        }
        .onChange(of: permissionsManager.allGranted) { allGranted in
            if allGranted {
                onAllGranted()
            }
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        hint: String? = nil,
        granted: Bool,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .frame(width: 20, height: 20)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Spacer()

                    if granted {
                        Text("Granted")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.green)
                    } else {
                        Button(buttonTitle, action: action)
                            .controlSize(.small)
                    }
                }

                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                if let hint, !granted {
                    Text(hint)
                        .font(.system(size: 11))
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.04))
        )
    }
}
