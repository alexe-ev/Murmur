import SwiftUI

final class IndicatorState: ObservableObject {
    @Published var menuBarState: MenuBarState = .idle
    @Published var lastTranscript: String?
    @Published var errorMessage: String?
    @Published var isExpanded: Bool = false
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
        switch indicatorState.menuBarState {
        case .idle:
            EmptyView()
        case .recording, .processing:
            pill
        case .error:
            if indicatorState.isExpanded {
                expandedErrorView
            } else {
                collapsedErrorPill
            }
        case .uncertain:
            if indicatorState.isExpanded {
                expandedUncertainView
            } else {
                uncertainPill
            }
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

    private let orangeColor = Color(red: 1.0, green: 0.7, blue: 0.2)

    private var uncertainPill: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(orangeColor)
                .frame(width: 12, height: 12)

            Text("Oops! Click me")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

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
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                indicatorState.isExpanded = true
            }
        }
    }

    private var collapsedErrorPill: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color(red: 0.95, green: 0.3, blue: 0.3))
                .frame(width: 12, height: 12)

            Text("Error. Show details")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))

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
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
                indicatorState.isExpanded = true
            }
        }
    }

    private var uncertainDisplayText: String {
        indicatorState.lastTranscript ?? "(text unavailable)"
    }

    private var expandedUncertainView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(orangeColor)
                    .frame(width: 12, height: 12)

                Text("Could not paste the text")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            ScrollView {
                Text(uncertainDisplayText)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: 360, minHeight: 40, maxHeight: 200)

            HStack {
                Spacer()

                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(uncertainDisplayText, forType: .string)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.15))
                )
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                Button("Close") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
        .padding(16)
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var expandedErrorView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(red: 0.95, green: 0.3, blue: 0.3))
                    .frame(width: 12, height: 12)

                Text(indicatorState.errorMessage ?? "Error")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }

            if let displayText = indicatorState.lastTranscript ?? indicatorState.errorMessage {
                ScrollView {
                    Text(displayText)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: 360, minHeight: 40, maxHeight: 200)
            }

            HStack {
                Spacer()

                Button("Copy") {
                    let text = indicatorState.lastTranscript ?? indicatorState.errorMessage ?? ""
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.15))
                )
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }

                Button("Close") {
                    onCancel()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }
        }
        .padding(16)
        .frame(width: 400)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
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
