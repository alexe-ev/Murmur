import Carbon.HIToolbox
import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SettingsModel.shared

    @State private var isCapturingHotkey = false
    @State private var hotkeyMonitor: Any?
    @State private var apiKeyInput = ""
    @State private var apiKeyMessage: String?
    @State private var apiKeySaveSucceeded = false
    @State private var hasSavedAPIKey = false

    var body: some View {
        Form {
            recordingSection
            transcriptionSection
            translationSection
            generalSection
        }
        .padding(16)
        .frame(width: 520, height: 440)
        .onAppear {
            refreshAPIKeyState()
        }
        .onDisappear {
            stopHotkeyCapture()
        }
    }

    private var recordingSection: some View {
        Section("Recording") {
            HStack {
                Text("Hotkey")
                Spacer()
                Text(isCapturingHotkey ? "Press a key combination..." : hotkeyDescription)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Button(isCapturingHotkey ? "Capturing…" : "Record") {
                    startHotkeyCapture()
                }
                .disabled(isCapturingHotkey)

                if isCapturingHotkey {
                    Button("Cancel") {
                        stopHotkeyCapture()
                    }
                }
            }
        }
    }

    private var transcriptionSection: some View {
        Section("Transcription") {
            Picker("Engine", selection: $settings.whisperBackend) {
                Text("On-Device (WhisperKit)").tag(SettingsModel.WhisperBackend.local)
                Text("OpenAI API").tag(SettingsModel.WhisperBackend.api)
            }
            .pickerStyle(.segmented)

            if settings.whisperBackend == .local {
                Picker("Model", selection: $settings.whisperModel) {
                    Text("tiny").tag(SettingsModel.WhisperModel.tiny)
                    Text("base").tag(SettingsModel.WhisperModel.base)
                    Text("small").tag(SettingsModel.WhisperModel.small)
                }
                .pickerStyle(.segmented)
            }

            if settings.whisperBackend == .api {
                SecureField("sk-...", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if let apiKeyMessage {
                        Text(apiKeyMessage)
                            .foregroundStyle(apiKeySaveSucceeded ? .green : .red)
                    }
                }

                if hasSavedAPIKey {
                    Text("API key is saved in Keychain.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var translationSection: some View {
        Section("Translation") {
            Toggle("Enable Translation", isOn: $settings.translationEnabled)

            Picker("Target Language", selection: $settings.targetLanguage) {
                ForEach(SettingsModel.TargetLanguage.allCases) { language in
                    Text(language.displayName).tag(language)
                }
            }
            .disabled(!settings.translationEnabled)

            Text("Target language is applied only when translation is enabled.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var generalSection: some View {
        Section("General") {
            Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            Toggle("Restore Clipboard After Paste", isOn: $settings.restoreClipboardAfterPaste)

            HStack {
                Text("Version")
                Spacer()
                Text(appVersionText)
                    .foregroundStyle(.secondary)
            }
        }
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
        hasSavedAPIKey = KeychainManager.hasValidAPIKey()
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
            apiKeyMessage = "Failed to save API key"
        }
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
