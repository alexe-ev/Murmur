import SwiftUI

struct RecordingIndicatorView: View {
    let state: MenuBarState
    let hotkeyHint: String
    let onStop: () -> Void
    let onCancel: () -> Void

    @State private var barHeights: [CGFloat] = Array(repeating: 2, count: 12)
    @State private var animationTimer: Timer?

    var body: some View {
        switch state {
        case .recording:
            recordingPill
        case .processing:
            processingPill
        case .idle:
            EmptyView()
        }
    }

    private var recordingPill: some View {
        HStack(spacing: 10) {
            // Stop button (stop + transcribe)
            Button {
                onStop()
            } label: {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(.white)
                    .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .frame(width: 24, height: 24)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }

            // Frequency bars
            HStack(spacing: 1.5) {
                ForEach(0..<12, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(.white.opacity(0.6))
                        .frame(width: 2, height: barHeights[i])
                }
            }
            .frame(height: 16)
            .onAppear { startBarAnimation() }
            .onDisappear { stopBarAnimation() }

            // Cancel button (discard)
            Button {
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
            .frame(width: 20, height: 20)
            .onHover { hovering in
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.75))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var processingPill: some View {
        HStack(spacing: 8) {
            ProgressView()
                .controlSize(.small)
                .tint(.white.opacity(0.7))

            Text("Transcribing\u{2026}")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.75))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private func startBarAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.12, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.12)) {
                    for i in 0..<12 {
                        barHeights[i] = CGFloat.random(in: 2...14)
                    }
                }
            }
        }
    }

    private func stopBarAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
    }
}
