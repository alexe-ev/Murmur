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
    private let menu = NSMenu()
    private var toggleRecordingItem: NSMenuItem?
    private let settingsModel = SettingsModel.shared
    private let translationConfig = TranslationConfig.shared
    private var languageItem: NSMenuItem?
    private var translationOnIndicatorItem: NSMenuItem?
    private var languageSubmenu: NSMenu?
    private var cancellables = Set<AnyCancellable>()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        observeTranslationSettings()
        rebuildLanguageSubmenu()
        setState(.idle)
    }

    private func configureStatusItem() {
        let toggleItem = NSMenuItem(title: "Start Recording", action: #selector(AppDelegate.toggleRecordingFromMenu), keyEquivalent: "")
        toggleItem.target = AppDelegate.shared
        menu.addItem(toggleItem)
        toggleRecordingItem = toggleItem

        menu.addItem(.separator())

        let languageMenuItem = NSMenuItem(title: "Target Language: English", action: nil, keyEquivalent: "")
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

    private func observeTranslationSettings() {
        translationConfig.$targetLanguage
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.rebuildLanguageSubmenu()
            }
            .store(in: &cancellables)

        translationConfig.$isEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.rebuildLanguageSubmenu()
            }
            .store(in: &cancellables)
    }

    private func rebuildLanguageSubmenu() {
        let currentLanguage = settingsModel.targetLanguage
        languageItem?.title = "Target Language: \(currentLanguage.displayName)"

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
        settingsModel.targetLanguage = language
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

    func showIndicator() {
        if indicatorPanel == nil {
            let hostingView = NSHostingView(rootView: RecordingIndicatorView())
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 160, height: 44),
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            panel.contentView = hostingView
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
            panel.ignoresMouseEvents = true
            panel.hasShadow = false
            indicatorPanel = panel
        }

        guard let panel = indicatorPanel else { return }
        positionIndicator(panel)
        panel.orderFrontRegardless()
    }

    func hideIndicator() {
        indicatorPanel?.orderOut(nil)
    }

    private func positionIndicator(_ panel: NSPanel) {
        let margin: CGFloat = 20
        let targetScreen = NSScreen.main ?? NSScreen.screens.first
        guard let screen = targetScreen else { return }

        let frame = screen.visibleFrame
        let x = frame.maxX - panel.frame.width - margin
        let y = frame.minY + margin
        panel.setFrameOrigin(NSPoint(x: x, y: y))
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
            showIndicator()
        case .processing:
            iconName = "icon-processing"
            fallbackSymbol = "hourglass"
            isRecording = false
            hideIndicator()
        }

        let image = NSImage(named: iconName)
            ?? NSImage(systemSymbolName: fallbackSymbol, accessibilityDescription: "Murmur")
        image?.isTemplate = true
        statusItem.button?.image = image
        updateMenuItems(isRecording: isRecording)
    }
}
