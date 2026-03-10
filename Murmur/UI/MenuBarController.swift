import AppKit
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
    private let menu = NSMenu()
    private var toggleRecordingItem: NSMenuItem?
    private let settingsModel = SettingsModel.shared
    private var languageItem: NSMenuItem?
    private var translationOnIndicatorItem: NSMenuItem?
    private var languageSubmenu: NSMenu?
    private var cancellables = Set<AnyCancellable>()

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

        let toggleItem = NSMenuItem(title: "Start Recording", action: #selector(AppDelegate.toggleRecordingFromMenu), keyEquivalent: "")
        toggleItem.target = AppDelegate.shared
        menu.addItem(toggleItem)
        toggleRecordingItem = toggleItem

        menu.addItem(.separator())

        let languageMenuItem = NSMenuItem(title: "Speech Language: English", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Language")
        languageMenuItem.submenu = submenu
        menu.addItem(languageMenuItem)
        languageItem = languageMenuItem
        languageSubmenu = submenu

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(AppDelegate.openSettings), keyEquivalent: "")
        settingsItem.target = AppDelegate.shared
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Murmur", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApplication.shared
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func observeSettings() {
        settingsModel.$speechLanguage
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.rebuildLanguageSubmenu()
            }
            .store(in: &cancellables)

        settingsModel.$translationEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.rebuildLanguageSubmenu()
            }
            .store(in: &cancellables)
    }

    private func rebuildLanguageSubmenu() {
        let currentLanguage = settingsModel.speechLanguage
        languageItem?.title = "Speech Language: \(currentLanguage.displayName)"

        guard let languageSubmenu else { return }
        languageSubmenu.removeAllItems()

        let indicatorTitle = settingsModel.translationEnabled ? "Translation On" : "Translation Off"
        let indicatorItem = NSMenuItem(title: indicatorTitle, action: nil, keyEquivalent: "")
        indicatorItem.isEnabled = false
        indicatorItem.isHidden = false
        languageSubmenu.addItem(indicatorItem)
        translationOnIndicatorItem = indicatorItem

        languageSubmenu.addItem(.separator())

        for language in SettingsModel.TargetLanguage.allCases {
            let item = NSMenuItem(title: language.displayName, action: #selector(selectLanguage(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = language.rawValue
            item.state = (language == currentLanguage) ? .on : .off
            languageSubmenu.addItem(item)
        }
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
        translationOnIndicatorItem?.title = settingsModel.translationEnabled ? "Translation On" : "Translation Off"
        translationOnIndicatorItem?.isHidden = false
    }

    func showIndicator(for state: MenuBarState) {
        if indicatorPanel == nil || indicatorHostingView == nil {
            let hostingView = NSHostingView(rootView: RecordingIndicatorView(state: state))
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 300, height: 44),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.contentView = hostingView
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .popUpMenu
            panel.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
            panel.ignoresMouseEvents = true
            panel.hasShadow = false
            panel.hidesOnDeactivate = false
            panel.animationBehavior = .utilityWindow
            indicatorPanel = panel
            indicatorHostingView = hostingView
        } else {
            indicatorHostingView?.rootView = RecordingIndicatorView(state: state)
        }

        guard let panel = indicatorPanel else { return }
        positionIndicator(panel)
        panel.orderFrontRegardless()
    }

    func hideIndicator() {
        indicatorPanel?.orderOut(nil)
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

    private func statusTitle(for state: MenuBarState) -> String {
        switch state {
        case .idle:
            return ""
        case .recording:
            return " REC"
        case .processing:
            return " ..."
        }
    }

    private func applyState(_ state: MenuBarState) {
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
        statusItem.button?.title = statusTitle(for: state)
        statusItem.button?.imagePosition = statusTitle(for: state).isEmpty ? .imageOnly : .imageLeading
        updateMenuItems(isRecording: isRecording)
    }
}
