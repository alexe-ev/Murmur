import SwiftUI

struct RecordingIndicatorView: View {
    let state: MenuBarState
    @State private var pulse = false

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

    var body: some View {
        HStack(spacing: 8) {
            indicator

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(.white)

            if state == .recording {
                Text("Press hotkey to stop")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.black.opacity(0.8))
        )
        .onAppear {
            guard state == .recording else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .recording:
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .scaleEffect(pulse ? 1.25 : 0.9)
                .opacity(pulse ? 1 : 0.7)
        case .processing:
            ProgressView()
                .controlSize(.small)
                .tint(.yellow)
                .frame(width: 10, height: 10)
        case .idle:
            Circle()
                .fill(Color.green)
                .frame(width: 10, height: 10)
        }
    }
}
