import AppKit
import Carbon.HIToolbox
import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsModel.shared

    @State private var selectedSection: Section = .transcription
    @State private var isCapturingHotkey = false
    @State private var hotkeyMonitor: Any?
    @State private var apiKeyInput = ""
    @State private var apiKeyMessage: String?
    @State private var apiKeySaveSucceeded = false
    @State private var hasSavedAPIKey = false
    @State private var maskedAPIKeyPreview: String?

    private enum Section: String, CaseIterable, Identifiable {
        case transcription
        case settings

        var id: String { rawValue }

        var title: String {
            switch self {
            case .transcription: return "Transcription"
            case .settings: return "Settings"
            }
        }

        var subtitle: String {
            switch self {
            case .transcription:
                return "Output mode and language settings."
            case .settings:
                return "Hotkey, API key, and general preferences."
            }
        }

        var symbol: String {
            switch self {
            case .transcription: return "waveform"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Spacer for titlebar traffic lights
            Color.clear.frame(height: 8)

            HStack(alignment: .top, spacing: 0) {
                sidebar
                    .padding(.leading, 16)
                    .padding(.trailing, 8)
                    .padding(.top, 4)

                contentPanel
                    .padding(.trailing, 16)
                    .padding(.top, 4)
            }
            .padding(.bottom, 16)
        }
        .frame(width: 620, height: 440)
        .background(.ultraThinMaterial)
        .onAppear {
            refreshAPIKeyState()
        }
        .onDisappear {
            stopHotkeyCapture()
        }
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Section.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: section.symbol)
                            .font(.system(size: 12))
                            .frame(width: 16)
                        Text(section.title)
                            .font(.system(size: 13))
                        Spacer()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(selectedSection == section ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                    .foregroundStyle(selectedSection == section ? .primary : .secondary)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .onHover { hovering in
                    if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                }
            }

            Spacer()
        }
        .frame(width: 150)
    }

    // MARK: - Content Panel

    private var contentPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedSection.title)
                    .font(.system(size: 13, weight: .semibold))
                Text(selectedSection.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 12)

            // Section content
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    switch selectedSection {
                    case .transcription:
                        transcriptionSection
                    case .settings:
                        settingsSection
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    // MARK: - Transcription Tab

    private var transcriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            formRow(label: "Speech Language") {
                Picker("", selection: $settings.speechLanguage) {
                    ForEach(SettingsModel.TargetLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            Divider()

            formRow(label: "Output Mode") {
                Picker("", selection: $settings.outputMode) {
                    ForEach(SettingsModel.OutputMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .labelsHidden()
                .frame(width: 180)
            }

            if settings.outputMode == .translation {
                formRow(label: "Target Language") {
                    Picker("", selection: $settings.targetLanguage) {
                        ForEach(SettingsModel.TargetLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 180)
                }
            }

            outputModeDescription
        }
    }

    private var outputModeDescription: some View {
        let text: String = {
            switch settings.outputMode {
            case .transcription:
                return "Raw speech-to-text. Your words are transcribed as-is, no AI processing applied."
            case .cleanup:
                return "Transcribes your speech, then cleans up grammar, filler words, and formatting. Output stays in the same language."
            case .translation:
                return "Transcribes your speech, cleans up filler words and false starts, then translates into the target language."
            }
        }()

        return Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Settings Tab

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            hotkeySection

            Divider()

            apiKeySection

            Divider()

            generalSection
        }
    }

    private var hotkeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Global Hotkey")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Text(isCapturingHotkey ? "Press a key combination..." : hotkeyDescription)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
            }

            HStack(spacing: 8) {
                Button(isCapturingHotkey ? "Capturing\u{2026}" : "Record Shortcut") {
                    startHotkeyCapture()
                }
                .controlSize(.small)
                .disabled(isCapturingHotkey)

                if isCapturingHotkey {
                    Button("Cancel") {
                        stopHotkeyCapture()
                    }
                    .controlSize(.small)
                }
            }

            Text("Use at least one modifier key to avoid conflicts with regular typing.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("OpenAI API Key")
                    .font(.system(size: 13, weight: .medium))

                Spacer()

                Text(hasSavedAPIKey ? "Configured" : "Required")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(hasSavedAPIKey ? .green : .orange)
            }

            if hasSavedAPIKey {
                HStack(spacing: 8) {
                    Text(maskedAPIKeyPreview ?? "sk-\u{2022}\u{2022}\u{2022}\u{2022}")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Remove", role: .destructive) {
                        deleteAPIKey()
                    }
                    .controlSize(.small)
                }
            } else {
                HStack(spacing: 8) {
                    SecureField("sk-...", text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 12, design: .monospaced))

                    Button("Save") {
                        saveAPIKey()
                    }
                    .controlSize(.small)
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if let apiKeyMessage {
                Text(apiKeyMessage)
                    .font(.system(size: 11))
                    .foregroundStyle(apiKeySaveSucceeded ? .green : .red)
            }
        }
    }

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                .toggleStyle(.switch)
                .controlSize(.small)

            Toggle("Restore Clipboard After Paste", isOn: $settings.restoreClipboardAfterPaste)
                .toggleStyle(.switch)
                .controlSize(.small)

            HStack {
                Text("Version")
                    .font(.system(size: 11))
                Spacer()
                Text(appVersionText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Shared Components

    private func formRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .frame(width: 120, alignment: .leading)
            content()
            Spacer()
        }
    }

    // MARK: - Hotkey

    private var hotkeyDescription: String {
        hotkeyDisplayString(modifiers: UInt32(settings.hotkeyModifiers), keyCode: UInt32(settings.hotkeyKeyCode))
    }

    private var appVersionText: String {
        let info = Bundle.main.infoDictionary
        let shortVersion = (info?["CFBundleShortVersionString"] as? String) ?? "1.0"
        let build = (info?["CFBundleVersion"] as? String) ?? "1"
        return "\(shortVersion) (\(build))"
    }

    // MARK: - API Key

    private func refreshAPIKeyState() {
        hasSavedAPIKey = APIKeyStorage.hasStoredAPIKey()
        if let key = APIKeyStorage.load(), !key.isEmpty {
            maskedAPIKeyPreview = maskedPreview(for: key)
        } else {
            maskedAPIKeyPreview = nil
        }
    }

    private func maskedPreview(for key: String) -> String {
        guard key.count > 7 else { return "sk-\u{2022}\u{2022}\u{2022}\u{2022}" }
        let prefix = key.prefix(3)
        let suffix = key.suffix(4)
        return "\(prefix)\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\u{2022}\(suffix)"
    }

    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try APIKeyStorage.save(apiKey: trimmed)
            apiKeyInput = ""
            apiKeySaveSucceeded = true
            apiKeyMessage = "Saved"
            refreshAPIKeyState()
        } catch {
            apiKeySaveSucceeded = false
            apiKeyMessage = "Failed to save API key"
        }
    }

    private func deleteAPIKey() {
        do {
            try APIKeyStorage.delete()
            apiKeyInput = ""
            apiKeySaveSucceeded = true
            apiKeyMessage = "Deleted"
            refreshAPIKeyState()
        } catch {
            apiKeySaveSucceeded = false
            apiKeyMessage = "Failed to remove API key"
        }
    }

    // MARK: - Hotkey Capture

    private func startHotkeyCapture() {
        guard !isCapturingHotkey else { return }
        isCapturingHotkey = true

        hotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = Int(event.keyCode)
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let carbon = Int(carbonModifiers(from: modifiers))
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
        if normalized & UInt32(controlKey) != 0 { symbols.append("\u{2303}") }
        if normalized & UInt32(optionKey) != 0 { symbols.append("\u{2325}") }
        if normalized & UInt32(shiftKey) != 0 { symbols.append("\u{21E7}") }
        if normalized & UInt32(cmdKey) != 0 { symbols.append("\u{2318}") }
        return symbols + keyName(for: keyCode)
    }

    private func keyName(for keyCode: UInt32) -> String {
        switch keyCode {
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_ForwardDelete): return "Fwd Delete"
        case UInt32(kVK_Escape): return "Esc"
        case UInt32(kVK_LeftArrow): return "Left"
        case UInt32(kVK_RightArrow): return "Right"
        case UInt32(kVK_DownArrow): return "Down"
        case UInt32(kVK_UpArrow): return "Up"
        case UInt32(kVK_ANSI_A): return "A"
        case UInt32(kVK_ANSI_B): return "B"
        case UInt32(kVK_ANSI_C): return "C"
        case UInt32(kVK_ANSI_D): return "D"
        case UInt32(kVK_ANSI_E): return "E"
        case UInt32(kVK_ANSI_F): return "F"
        case UInt32(kVK_ANSI_G): return "G"
        case UInt32(kVK_ANSI_H): return "H"
        case UInt32(kVK_ANSI_I): return "I"
        case UInt32(kVK_ANSI_J): return "J"
        case UInt32(kVK_ANSI_K): return "K"
        case UInt32(kVK_ANSI_L): return "L"
        case UInt32(kVK_ANSI_M): return "M"
        case UInt32(kVK_ANSI_N): return "N"
        case UInt32(kVK_ANSI_O): return "O"
        case UInt32(kVK_ANSI_P): return "P"
        case UInt32(kVK_ANSI_Q): return "Q"
        case UInt32(kVK_ANSI_R): return "R"
        case UInt32(kVK_ANSI_S): return "S"
        case UInt32(kVK_ANSI_T): return "T"
        case UInt32(kVK_ANSI_U): return "U"
        case UInt32(kVK_ANSI_V): return "V"
        case UInt32(kVK_ANSI_W): return "W"
        case UInt32(kVK_ANSI_X): return "X"
        case UInt32(kVK_ANSI_Y): return "Y"
        case UInt32(kVK_ANSI_Z): return "Z"
        case UInt32(kVK_ANSI_0): return "0"
        case UInt32(kVK_ANSI_1): return "1"
        case UInt32(kVK_ANSI_2): return "2"
        case UInt32(kVK_ANSI_3): return "3"
        case UInt32(kVK_ANSI_4): return "4"
        case UInt32(kVK_ANSI_5): return "5"
        case UInt32(kVK_ANSI_6): return "6"
        case UInt32(kVK_ANSI_7): return "7"
        case UInt32(kVK_ANSI_8): return "8"
        case UInt32(kVK_ANSI_9): return "9"
        case UInt32(kVK_ANSI_Minus): return "-"
        case UInt32(kVK_ANSI_Equal): return "="
        case UInt32(kVK_ANSI_LeftBracket): return "["
        case UInt32(kVK_ANSI_RightBracket): return "]"
        case UInt32(kVK_ANSI_Backslash): return "\\"
        case UInt32(kVK_ANSI_Semicolon): return ";"
        case UInt32(kVK_ANSI_Quote): return "'"
        case UInt32(kVK_ANSI_Comma): return ","
        case UInt32(kVK_ANSI_Period): return "."
        case UInt32(kVK_ANSI_Slash): return "/"
        case UInt32(kVK_ANSI_Grave): return "`"
        default:
            return String(format: "Key %u", keyCode)
        }
    }
}
