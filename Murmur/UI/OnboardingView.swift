import AppKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    let onAllGranted: () -> Void

    var body: some View {
        ZStack {
            liquidBackground

            VStack(alignment: .leading, spacing: 18) {
                header

                permissionRow(
                    icon: "mic.fill",
                    title: "Microphone",
                    description: "Needed to capture your voice so Murmur can transcribe speech into text.",
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
                    description: "Needed to paste transcribed text into the app or input field that is currently focused.",
                    granted: permissionsManager.accessibilityGranted,
                    buttonTitle: "Open Settings"
                ) {
                    permissionsManager.openAccessibilitySettings()
                }

                Text("After granting access, return to Murmur. The app will continue automatically.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .frame(width: 640)
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
                .frame(width: 50, height: 50)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                Text("Murmur")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                Text("Grant permissions to start voice-to-text flow.")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var liquidBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.24),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)

            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: 520, height: 520)
                .offset(x: -200, y: -220)
                .blur(radius: 44)

            Circle()
                .fill(Color.cyan.opacity(0.10))
                .frame(width: 420, height: 420)
                .offset(x: 220, y: 200)
                .blur(radius: 52)
        }
        .ignoresSafeArea()
    }

    private func permissionRow(
        icon: String,
        title: String,
        description: String,
        granted: Bool,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 10)

                statusBadge(granted: granted)
            }

            HStack {
                Spacer()

                Button(buttonTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.5),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
    }

    private func statusBadge(granted: Bool) -> some View {
        Text(granted ? "Granted ✓" : "Required")
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(granted ? Color.green.opacity(0.16) : Color.orange.opacity(0.16))
            .foregroundStyle(granted ? Color.green : Color.orange)
            .clipShape(Capsule())
    }
}
