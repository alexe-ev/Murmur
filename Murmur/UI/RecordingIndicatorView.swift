import SwiftUI

struct RecordingIndicatorView: View {
    let state: MenuBarState
    let hotkeyHint: String
    @State private var pulse = false
    @State private var breathe = false

    private var title: String {
        switch state {
        case .recording:
            return "Recording"
        case .processing:
            return "Processing"
        case .idle:
            return "Ready"
        }
    }

    private var subtitle: String? {
        switch state {
        case .recording:
            return "Press \(hotkeyHint) to stop"
        case .processing:
            return "Transcribing and preparing text"
        case .idle:
            return nil
        }
    }

    private var accentColor: Color {
        switch state {
        case .recording:
            return Color(red: 1.0, green: 0.34, blue: 0.34)
        case .processing:
            return Color(red: 0.44, green: 0.76, blue: 1.0)
        case .idle:
            return Color(red: 0.48, green: 0.90, blue: 0.72)
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            indicator

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary.opacity(0.9))
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .background(
            Capsule(style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.30), lineWidth: 1)
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.44),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .shadow(color: .black.opacity(0.16), radius: 14, x: 0, y: 6)
        .onAppear {
            startAnimations()
        }
        .onChange(of: state) { _ in
            startAnimations()
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .recording:
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.28), lineWidth: 1.8)
                    .frame(width: 16, height: 16)
                    .scaleEffect(pulse ? 1.55 : 1)
                    .opacity(pulse ? 0 : 1)

                Circle()
                    .fill(accentColor)
                    .frame(width: 10, height: 10)
                    .scaleEffect(breathe ? 1.12 : 0.92)
            }
        case .processing:
            ProgressView()
                .controlSize(.small)
                .tint(accentColor)
                .frame(width: 16, height: 16)
        case .idle:
            Circle()
                .fill(accentColor)
                .frame(width: 10, height: 10)
        }
    }

    private func startAnimations() {
        pulse = false
        breathe = false

        guard state == .recording else { return }

        withAnimation(.easeOut(duration: 1.05).repeatForever(autoreverses: false)) {
            pulse = true
        }
        withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
            breathe = true
        }
    }
}
