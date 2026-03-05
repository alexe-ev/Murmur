import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    let onAllGranted: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            permissionRow(
                icon: "mic.fill",
                title: "Microphone",
                description: "Needed to capture your voice for transcription.",
                granted: permissionsManager.microphoneGranted,
                buttonTitle: "Grant Access"
            ) {
                Task {
                    await permissionsManager.requestMicrophone()
                }
            }

            permissionRow(
                icon: "accessibility",
                title: "Accessibility",
                description: "Needed to paste text into the currently focused app.",
                granted: permissionsManager.accessibilityGranted,
                buttonTitle: "Open Settings"
            ) {
                permissionsManager.openAccessibilitySettings()
            }
        }
        .padding(24)
        .frame(width: 560)
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

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 48, height: 48)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Murmur")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Grant permissions to start voice-to-text flow.")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        granted: Bool,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                statusBadge(granted: granted)

                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statusBadge(granted: Bool) -> some View {
        Text(granted ? "Granted ✓" : "Required")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(granted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
            .foregroundStyle(granted ? Color.green : Color.orange)
            .clipShape(Capsule())
    }
}
