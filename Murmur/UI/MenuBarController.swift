import AppKit
import Carbon.HIToolbox
import Combine
import SwiftUI

enum MenuBarState {
    case idle
    case recording
    case processing
}

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem
    private var indicatorPanel: NSPanel?
    private var indicatorHostingView: NSHostingView<RecordingIndicatorView>?
    private let indicatorState = IndicatorState()
    private let menu = NSMenu()
    private var statusSummaryItem: NSMenuItem?
    private var toggleRecordingItem: NSMenuItem?
    private var hotkeyHintItem: NSMenuItem?
    private let settingsModel = SettingsModel.shared
    private var languageItem: NSMenuItem?
    private var outputModeItem: NSMenuItem?
    private var outputModeSubmenu: NSMenu?
    private var languageSubmenu: NSMenu?
    private var cancellables = Set<AnyCancellable>()
    private var currentState: MenuBarState = .idle

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        observeSettings()
        rebuildLanguageSubmenu()
        setState(.idle)
    }

    private func configureStatusItem() {
        statusItem.button?.title = ""
        statusItem.button?.imagePosition = .imageOnly

        let stateItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
        stateItem.isEnabled = false
        stateItem.image = menuSymbol("waveform")
        menu.addItem(stateItem)
        statusSummaryItem = stateItem

        menu.addItem(.separator())

        let toggleItem = NSMenuItem(title: "Start Recording", action: #selector(AppDelegate.toggleRecordingFromMenu), keyEquivalent: "")
        toggleItem.target = AppDelegate.shared
        toggleItem.image = menuSymbol("mic.fill")
        menu.addItem(toggleItem)
        toggleRecordingItem = toggleItem

        let hotkeyItem = NSMenuItem(title: "Shortcut: \(menuHotkeyHint())", action: nil, keyEquivalent: "")
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)
        hotkeyHintItem = hotkeyItem

        menu.addItem(.separator())

        let languageMenuItem = NSMenuItem(title: "Speech Language", action: nil, keyEquivalent: "")
        languageMenuItem.image = menuSymbol("character.bubble")
        let submenu = NSMenu(title: "Language")
        languageMenuItem.submenu = submenu
        menu.addItem(languageMenuItem)
        languageItem = languageMenuItem
        languageSubmenu = submenu

        let modeMenuItem = NSMenuItem(title: "Output Mode", action: nil, keyEquivalent: "")
        modeMenuItem.image = menuSymbol("globe")
        let modeSubmenu = NSMenu(title: "Output Mode")
        modeMenuItem.submenu = modeSubmenu
        menu.addItem(modeMenuItem)
        outputModeItem = modeMenuItem
        outputModeSubmenu = modeSubmenu
        rebuildOutputModeSubmenu()

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(AppDelegate.openSettings), keyEquivalent: "")
        settingsItem.target = AppDelegate.shared
        settingsItem.image = menuSymbol("gearshape")
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Murmur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApplication.shared
        quitItem.image = menuSymbol("power")
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func observeSettings() {
        settingsModel.$speechLanguage
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.rebuildLanguageSubmenu()
            }
            .store(in: &cancellables)

        settingsModel.$outputMode
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.rebuildOutputModeSubmenu()
                self.updateMenuItems(isRecording: self.currentState == .recording)
            }
            .store(in: &cancellables)

        settingsModel.$targetLanguage
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.rebuildOutputModeSubmenu()
                self.updateMenuItems(isRecording: self.currentState == .recording)
            }
            .store(in: &cancellables)

        settingsModel.$hotkeyModifiers
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateMenuItems(isRecording: self.currentState == .recording)
            }
            .store(in: &cancellables)

        settingsModel.$hotkeyKeyCode
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                self.updateMenuItems(isRecording: self.currentState == .recording)
            }
            .store(in: &cancellables)
    }

    private func rebuildLanguageSubmenu() {
        let currentLanguage = settingsModel.speechLanguage
        languageItem?.title = "Speech Language: \(currentLanguage.displayName)"

        guard let languageSubmenu else { return }
        languageSubmenu.removeAllItems()

        let descriptionItem = NSMenuItem(title: "Used for speech recognition input", action: nil, keyEquivalent: "")
        descriptionItem.isEnabled = false
        languageSubmenu.addItem(descriptionItem)

        languageSubmenu.addItem(.separator())

        for language in SettingsModel.TargetLanguage.allCases {
            let item = NSMenuItem(title: language.displayName, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language.rawValue
            item.state = (language == currentLanguage) ? .on : .off
            languageSubmenu.addItem(item)
        }

        updateMenuItems(isRecording: currentState == .recording)
    }

    @objc
    private func selectLanguage(_ sender: NSMenuItem) {
        guard
            let languageCode = sender.representedObject as? String,
            let language = SettingsModel.TargetLanguage(rawValue: languageCode)
        else {
            return
        }
        settingsModel.speechLanguage = language
        rebuildLanguageSubmenu()
    }

    private func rebuildOutputModeSubmenu() {
        let currentMode = settingsModel.outputMode
        let suffix: String
        switch currentMode {
        case .transcription:
            suffix = "Transcription"
        case .cleanup:
            suffix = "Clean-up"
        case .translation:
            suffix = "Translation (\(settingsModel.targetLanguage.displayName))"
        }
        outputModeItem?.title = "Output: \(suffix)"

        guard let outputModeSubmenu else { return }
        outputModeSubmenu.removeAllItems()

        for mode in SettingsModel.OutputMode.allCases {
            let item = NSMenuItem(title: mode.displayName, action: #selector(selectOutputMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode.rawValue
            item.state = (mode == currentMode) ? .on : .off
            outputModeSubmenu.addItem(item)
        }

        if currentMode == .translation {
            outputModeSubmenu.addItem(.separator())

            let headerItem = NSMenuItem(title: "Target Language", action: nil, keyEquivalent: "")
            headerItem.isEnabled = false
            outputModeSubmenu.addItem(headerItem)

            let currentTarget = settingsModel.targetLanguage
            for language in SettingsModel.TargetLanguage.allCases {
                let item = NSMenuItem(title: language.displayName, action: #selector(selectTargetLanguage(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = language.rawValue
                item.state = (language == currentTarget) ? .on : .off
                outputModeSubmenu.addItem(item)
            }
        }
    }

    @objc
    private func selectOutputMode(_ sender: NSMenuItem) {
        guard
            let modeRaw = sender.representedObject as? String,
            let mode = SettingsModel.OutputMode(rawValue: modeRaw)
        else {
            return
        }
        settingsModel.outputMode = mode
        rebuildOutputModeSubmenu()
    }

    @objc
    private func selectTargetLanguage(_ sender: NSMenuItem) {
        guard
            let languageCode = sender.representedObject as? String,
            let language = SettingsModel.TargetLanguage(rawValue: languageCode)
        else {
            return
        }
        settingsModel.targetLanguage = language
        rebuildOutputModeSubmenu()
    }

    func setState(_ state: MenuBarState) {
        if Thread.isMainThread {
            applyState(state)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.applyState(state)
            }
        }
    }

    func updateMenuItems(isRecording: Bool) {
        toggleRecordingItem?.title = isRecording ? "Stop Recording" : "Start Recording"
        toggleRecordingItem?.image = menuSymbol(isRecording ? "stop.circle.fill" : "mic.fill")
        hotkeyHintItem?.title = "Shortcut: \(menuHotkeyHint())"
        hotkeyHintItem?.isHidden = isRecording

        rebuildOutputModeSubmenu()

        statusSummaryItem?.title = menuStateTitle(for: currentState)
        statusSummaryItem?.image = menuStateSymbol(for: currentState)
    }

    func showIndicator(for state: MenuBarState) {
        indicatorState.menuBarState = state
        let isInteractive = (state == .recording)

        if indicatorPanel == nil || indicatorHostingView == nil {
            let indicatorView = RecordingIndicatorView(
                indicatorState: indicatorState,
                onCancel: { [weak self] in
                    AppDelegate.shared?.cancelRecording()
                    self?.hideIndicator()
                }
            )
            let hostingView = NSHostingView(rootView: indicatorView)
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 200, height: 44),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.contentView = hostingView
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .popUpMenu
            panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
            panel.ignoresMouseEvents = false
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.animationBehavior = .utilityWindow
            indicatorPanel = panel
            indicatorHostingView = hostingView
        }

        guard let panel = indicatorPanel else { return }
        positionIndicator(panel)
        panel.orderFrontRegardless()
    }

    func hideIndicator() {
        indicatorState.menuBarState = .idle
        indicatorPanel?.orderOut(nil)
        indicatorPanel?.contentView = nil
        indicatorPanel = nil
        indicatorHostingView = nil
    }

    private func positionIndicator(_ panel: NSPanel) {
        let margin: CGFloat = 12
        let pointerOffsetX: CGFloat = 16
        let pointerOffsetY: CGFloat = 20
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens.first
        guard let screen = targetScreen else { return }

        let frame = screen.visibleFrame
        let maxX = frame.maxX - panel.frame.width - margin
        let minX = frame.minX + margin
        let minY = frame.minY + margin
        let maxY = frame.maxY - panel.frame.height - margin

        var x = mouseLocation.x + pointerOffsetX
        var y = mouseLocation.y + pointerOffsetY

        if y > maxY {
            y = mouseLocation.y - panel.frame.height - pointerOffsetY
        }

        x = min(max(x, minX), maxX)
        y = min(max(y, minY), maxY)
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func applyState(_ state: MenuBarState) {
        currentState = state
        let iconName: String
        let fallbackSymbol: String
        let isRecording: Bool

        switch state {
        case .idle:
            iconName = "icon-idle"
            fallbackSymbol = "waveform"
            isRecording = false
            hideIndicator()
        case .recording:
            iconName = "icon-recording"
            fallbackSymbol = "mic.fill"
            isRecording = true
            showIndicator(for: .recording)
        case .processing:
            iconName = "icon-processing"
            fallbackSymbol = "hourglass"
            isRecording = false
            showIndicator(for: .processing)
        }

        let image = NSImage(named: iconName)
            ?? NSImage(systemSymbolName: fallbackSymbol, accessibilityDescription: "Murmur")
        image?.isTemplate = true
        statusItem.button?.image = image
        statusItem.button?.toolTip = menuStateTitle(for: state)
        statusItem.button?.title = ""
        statusItem.button?.imagePosition = .imageOnly
        updateMenuItems(isRecording: isRecording)
    }

    private func menuStateTitle(for state: MenuBarState) -> String {
        switch state {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording in progress"
        case .processing:
            return "Processing audio"
        }
    }

    private func menuStateSymbol(for state: MenuBarState) -> NSImage? {
        switch state {
        case .idle:
            return menuSymbol("checkmark.circle.fill")
        case .recording:
            return menuSymbol("record.circle.fill")
        case .processing:
            return menuSymbol("hourglass.circle.fill")
        }
    }

    private func menuSymbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        image?.isTemplate = true
        return image
    }

    private func menuHotkeyHint() -> String {
        let modifiers = UInt32(settingsModel.hotkeyModifiers)
        let keyCode = UInt32(settingsModel.hotkeyKeyCode)
        return hotkeyDisplayString(modifiers: modifiers, keyCode: keyCode)
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
            return "Key \(keyCode)"
        }
    }
}
