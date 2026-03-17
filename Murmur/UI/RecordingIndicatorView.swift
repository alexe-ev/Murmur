import SwiftUI

final class IndicatorState: ObservableObject {
    @Published var menuBarState: MenuBarState = .idle
}

struct RecordingIndicatorView: View {
    @ObservedObject var indicatorState: IndicatorState
    let onCancel: () -> Void

    private let barCount = 16
    @State private var barHeights: [CGFloat] = Array(repeating: 1, count: 16)
    @State private var animationTimer: Timer?
    @State private var spinAngle: Double = 0

    private var isRecording: Bool { indicatorState.menuBarState == .recording }
    private var isProcessing: Bool { indicatorState.menuBarState == .processing }

    var body: some View {
        if indicatorState.menuBarState != .idle {
            pill
        }
    }

    private func barOpacity(for height: CGFloat) -> Double {
        let normalized = (height - 1) / 13
        return 0.25 + normalized * 0.75
    }

    private var pill: some View {
        HStack(spacing: isRecording ? 10 : 0) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(.white)
                .frame(width: 12, height: 12)
                .rotationEffect(.degrees(isProcessing ? spinAngle : 0))

            if isRecording {
                HStack(spacing: 2) {
                    ForEach(0..<barCount, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 0.5)
                            .fill(.white.opacity(barOpacity(for: barHeights[i])))
                            .frame(width: 1.5, height: barHeights[i])
                    }
                }
                .frame(height: 16)
                .transition(.opacity.combined(with: .scale(scale: 0.3, anchor: .leading)))

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
                .transition(.opacity.combined(with: .scale(scale: 0.3, anchor: .trailing)))
            }
        }
        .padding(.horizontal, isRecording ? 14 : 10)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.75))
        )
        .overlay(
            Capsule(style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.4), value: indicatorState.menuBarState)
        .onChange(of: indicatorState.menuBarState) { newState in
            if newState == .recording {
                spinAngle = 0
                startBarAnimation()
            } else if newState == .processing {
                stopBarAnimation()
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    spinAngle = 360
                }
            } else {
                stopBarAnimation()
            }
        }
        .onAppear {
            if isRecording {
                startBarAnimation()
            }
        }
        .onDisappear {
            stopBarAnimation()
        }
    }

    private func startBarAnimation() {
        stopBarAnimation()

        let interval: TimeInterval = 1.0 / 12
        animationTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 0.2)) {
                    for i in 0..<barCount {
                        barHeights[i] = CGFloat.random(in: 1...14)
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
