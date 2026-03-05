import AppKit

@MainActor
final class MenuBarController: NSObject {
    private let statusItem: NSStatusItem

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()
        configureStatusItem()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Murmur")
        }

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
}
