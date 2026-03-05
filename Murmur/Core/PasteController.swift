import AppKit
import Foundation

enum PasteError: Error {
    case accessibilityNotGranted
    case clipboardWriteFailed
}

@MainActor
final class PasteController {
    private let permissionsManager: PermissionsManager
    private let pasteboard: NSPasteboard

    init(
        permissionsManager: PermissionsManager = .shared,
        pasteboard: NSPasteboard = .general
    ) {
        self.permissionsManager = permissionsManager
        self.pasteboard = pasteboard
    }

    func paste(_ text: String) throws {
        guard permissionsManager.accessibilityGranted else {
            throw PasteError.accessibilityNotGranted
        }

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw PasteError.clipboardWriteFailed
        }

        usleep(50_000)

        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true),
            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        else {
            throw PasteError.clipboardWriteFailed
        }

        keyDown.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.flags = .maskCommand
        keyUp.post(tap: .cghidEventTap)
    }
}
