import AppKit
import Carbon.HIToolbox
import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsModel.shared

    @State private var selectedSection: Section = .recording
    @State private var isCapturingHotkey = false
    @State private var hotkeyMonitor: Any?
    @State private var apiKeyInput = ""
    @State private var apiKeyMessage: String?
    @State private var apiKeySaveSucceeded = false
    @State private var hasSavedAPIKey = false
    @State private var maskedAPIKeyPreview: String?

    private enum Section: String, CaseIterable, Identifiable {
        case recording
        case transcription
        case translation
        case general

        var id: String { rawValue }

        var title: String {
            switch self {
            case .recording: return "Recording"
            case .transcription: return "Transcription"
            case .translation: return "Translation"
            case .general: return "General"
            }
        }

        var subtitle: String {
            switch self {
            case .recording:
                return "Choose a global shortcut to start and stop capture."
            case .transcription:
                return "Select engine, model, speech language, and OpenAI API key."
            case .translation:
                return "Translate transcription output into the selected language."
            case .general:
                return "Configure startup and clipboard behavior."
            }
        }

        var symbol: String {
            switch self {
            case .recording: return "mic.circle"
            case .transcription: return "waveform"
            case .translation: return "globe"
            case .general: return "gearshape"
            }
        }
    }

    var body: some View {
        ZStack {
            liquidBackground

            VStack(alignment: .leading, spacing: 16) {
                header

                HStack(alignment: .top, spacing: 14) {
                    sidebar
                    contentPanel
                }
            }
            .padding(20)
        }
        .frame(width: 760, height: 580)
        .onAppear {
            refreshAPIKeyState()
        }
        .onDisappear {
            stopHotkeyCapture()
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 40, height: 40)
                .cornerRadius(9)

            VStack(alignment: .leading, spacing: 2) {
                Text("Murmur Settings")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("Configure voice capture, transcription, and translation.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Section.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: section.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(width: 16)
                        Text(section.title)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(selectedSection == section ? Color.white.opacity(0.18) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(
                                selectedSection == section ? Color.white.opacity(0.32) : Color.clear,
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(10)
        .frame(width: 190)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.24), lineWidth: 1)
        )
    }

    private var contentPanel: some View {
        settingsCard(
            title: selectedSection.title,
            subtitle: selectedSection.subtitle,
            symbol: selectedSection.symbol
        ) {
            switch selectedSection {
            case .recording:
                recordingSection
            case .transcription:
                transcriptionSection
            case .translation:
                translationSection
            case .general:
                generalSection
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private var recordingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Current Shortcut", systemImage: "keyboard")
                    .font(.subheadline)

                Spacer()

                Text(isCapturingHotkey ? "Press a key combination" : hotkeyDescription)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
            }

            HStack(spacing: 8) {
                Button(isCapturingHotkey ? "Capturing…" : "Record Shortcut") {
                    startHotkeyCapture()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCapturingHotkey)

                if isCapturingHotkey {
                    Button("Cancel") {
                        stopHotkeyCapture()
                    }
                    .buttonStyle(.bordered)
                }
            }

            Text("Use at least one modifier key to avoid conflicts with regular typing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            pickerRow(title: "Engine") {
                Picker("Engine", selection: $settings.whisperBackend) {
                    Text("On-Device").tag(SettingsModel.WhisperBackend.local)
                    Text("OpenAI API").tag(SettingsModel.WhisperBackend.api)
                }
            }

            if settings.whisperBackend == .local {
                pickerRow(title: "Model") {
                    Picker("Model", selection: $settings.whisperModel) {
                        Text("tiny").tag(SettingsModel.WhisperModel.tiny)
                        Text("base").tag(SettingsModel.WhisperModel.base)
                        Text("small").tag(SettingsModel.WhisperModel.small)
                    }
                }
            }

            pickerRow(title: "Speech Language") {
                Picker("Speech Language", selection: $settings.speechLanguage) {
                    ForEach(SettingsModel.TargetLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            }

            if settings.translationEnabled && settings.whisperBackend == .local {
                Label("Translation still uses OpenAI API key.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            apiKeySection
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("OpenAI API Key")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                statusPill(
                    title: hasSavedAPIKey ? "Configured" : "Required",
                    tint: hasSavedAPIKey ? .green : .orange
                )
            }

            glassField {
                SecureField("sk-...", text: $apiKeyInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
            }

            HStack(spacing: 8) {
                Button("Save") {
                    saveAPIKey()
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if hasSavedAPIKey {
                    Button("Remove", role: .destructive) {
                        deleteAPIKey()
                    }
                    .buttonStyle(.bordered)
                }

                if let apiKeyMessage {
                    Text(apiKeyMessage)
                        .font(.caption)
                        .foregroundStyle(apiKeySaveSucceeded ? .green : .red)
                }
            }

            if hasSavedAPIKey {
                Text("Stored in Keychain as \(maskedAPIKeyPreview ?? "hidden").")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("API key is stored securely in macOS Keychain.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Enable Translation", isOn: $settings.translationEnabled)
                .toggleStyle(.switch)

            if settings.translationEnabled && !hasSavedAPIKey {
                Label("Add OpenAI API key in the Transcription tab to continue.", systemImage: "key.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }

            pickerRow(title: "Output Language") {
                Picker("Output Language", selection: $settings.targetLanguage) {
                    ForEach(SettingsModel.TargetLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .disabled(!settings.translationEnabled)
            }

            Text("Murmur recognizes your speech in Speech Language and translates final text only when translation is enabled.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .toggleStyle(.switch)

            Toggle("Restore Clipboard After Paste", isOn: $settings.restoreClipboardAfterPaste)
                .toggleStyle(.switch)

            HStack {
                Text("Version")
                Spacer()
                Text(appVersionText)
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
    }

    private var liquidBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.30),
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.22)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.overlay)

            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 620, height: 620)
                .offset(x: -260, y: -300)
                .blur(radius: 46)

            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 520, height: 520)
                .offset(x: 240, y: 240)
                .blur(radius: 60)
        }
        .ignoresSafeArea()
    }

    private func settingsCard<Content: View>(
        title: String,
        subtitle: String,
        symbol: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            content()

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.26), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.55),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.9
                )
        )
        .shadow(color: Color.black.opacity(0.16), radius: 14, x: 0, y: 6)
    }

    private func pickerRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .frame(width: 130, alignment: .leading)

            glassField {
                content()
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func glassField<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.11))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.23), lineWidth: 1)
            )
    }

    private func statusPill(title: String, tint: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(Capsule().fill(tint.opacity(0.14)))
            .foregroundStyle(tint)
    }

    private var hotkeyDescription: String {
        let modifiers = UInt32(settings.hotkeyModifiers)
        let keyCode = UInt32(settings.hotkeyKeyCode)
        return hotkeyDisplayString(modifiers: modifiers, keyCode: keyCode)
    }

    private var appVersionText: String {
        let info = Bundle.main.infoDictionary
        let shortVersion = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        return "\(shortVersion) (\(build))"
    }

    private func refreshAPIKeyState() {
        hasSavedAPIKey = KeychainManager.hasStoredAPIKey()
        if let key = KeychainManager.load(allowAuthenticationUI: false), !key.isEmpty {
            maskedAPIKeyPreview = maskedPreview(for: key)
        } else {
            maskedAPIKeyPreview = hasSavedAPIKey ? "sk-••••" : nil
        }
    }

    private func maskedPreview(for key: String) -> String {
        guard key.count > 7 else { return "sk-••••" }
        let prefix = key.prefix(3)
        let suffix = key.suffix(4)
        return "\(prefix)••••••\(suffix)"
    }

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            try KeychainManager.save(apiKey: trimmed)
            apiKeyInput = ""
            apiKeySaveSucceeded = true
            apiKeyMessage = "Saved"
            refreshAPIKeyState()
        } catch {
            apiKeySaveSucceeded = false
            apiKeyMessage = saveFailureMessage(for: error)
        }
    }

    private func deleteAPIKey() {
        do {
            try KeychainManager.delete()
            apiKeyInput = ""
            apiKeySaveSucceeded = true
            apiKeyMessage = "Deleted"
            refreshAPIKeyState()
        } catch {
            apiKeySaveSucceeded = false
            apiKeyMessage = "Failed to remove API key"
        }
    }

    private func saveFailureMessage(for error: Error) -> String {
        if case let KeychainError.saveFailed(status) = error {
            return "Failed to save API key (\(status))"
        }
        return "Failed to save API key"
    }

    private func startHotkeyCapture() {
        guard !isCapturingHotkey else { return }
        isCapturingHotkey = true

        hotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = Int(event.keyCode)
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let carbon = Int(carbonModifiers(from: modifiers))

            // Require at least one modifier to avoid hijacking regular typing (e.g. plain Space).
            guard carbon != 0 else { return nil }
            settings.hotkeyKeyCode = keyCode
            settings.hotkeyModifiers = carbon

            stopHotkeyCapture()
            return nil
        }
    }

    private func stopHotkeyCapture() {
        isCapturingHotkey = false
        if let hotkeyMonitor {
            NSEvent.removeMonitor(hotkeyMonitor)
            self.hotkeyMonitor = nil
        }
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0

        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }

        return result
    }

    private func hotkeyDisplayString(modifiers: UInt32, keyCode: UInt32) -> String {
        let normalized = modifiers & UInt32(cmdKey | optionKey | controlKey | shiftKey)
        var symbols = ""

        if normalized & UInt32(controlKey) != 0 { symbols.append("⌃") }
        if normalized & UInt32(optionKey) != 0 { symbols.append("⌥") }
        if normalized & UInt32(shiftKey) != 0 { symbols.append("⇧") }
        if normalized & UInt32(cmdKey) != 0 { symbols.append("⌘") }

        let keyName = keyName(for: keyCode)
        return symbols + keyName
    }

    private func keyName(for keyCode: UInt32) -> String {
        switch keyCode {
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_Escape): return "Esc"
        case UInt32(kVK_LeftArrow): return "Left"
        case UInt32(kVK_RightArrow): return "Right"
        case UInt32(kVK_DownArrow): return "Down"
        case UInt32(kVK_UpArrow): return "Up"
        default:
            return String(format: "Key %u", keyCode)
        }
    }
}
