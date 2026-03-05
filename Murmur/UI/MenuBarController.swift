import AppKit
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

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
        setState(.idle)
    }

    private func configureStatusItem() {
        let menu = NSMenu()

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(AppDelegate.openSettings), keyEquivalent: "")
        settingsItem.target = AppDelegate.shared
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quitItem.target = NSApplication.shared
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func setState(_ state: MenuBarState) {
        let applyState = { [weak self] in
            guard let self else { return }

            let iconName: String
            let fallbackSymbol: String

            switch state {
            case .idle:
                iconName = "icon-idle"
                fallbackSymbol = "waveform"
                self.hideIndicator()
            case .recording:
                iconName = "icon-recording"
                fallbackSymbol = "mic.fill"
                self.showIndicator()
            case .processing:
                iconName = "icon-processing"
                fallbackSymbol = "hourglass"
                self.hideIndicator()
            }

            let image = NSImage(named: iconName)
                ?? NSImage(systemSymbolName: fallbackSymbol, accessibilityDescription: "Murmur")
            image?.isTemplate = true
            self.statusItem.button?.image = image
        }

        if Thread.isMainThread {
            applyState()
        } else {
            DispatchQueue.main.async(execute: applyState)
        }
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
}
