import AppKit

enum MenuBarState {
    case idle
    case recording
    case processing
}

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem

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
            case .recording:
                iconName = "icon-recording"
                fallbackSymbol = "mic.fill"
            case .processing:
                iconName = "icon-processing"
                fallbackSymbol = "hourglass"
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
}
