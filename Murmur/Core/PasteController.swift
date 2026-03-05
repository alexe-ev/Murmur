import AppKit
import Foundation

enum PasteError: Error {
    case accessibilityNotGranted
    case clipboardWriteFailed
}

@MainActor
final class PasteController {
    private struct ClipboardSnapshot {
        let items: [NSPasteboardItem]
        let wasEmpty: Bool
    }

    private let permissionsManager: PermissionsManager
    private let pasteboard: NSPasteboard
    private let settingsModel: SettingsModel

    init(
        permissionsManager: PermissionsManager = .shared,
        pasteboard: NSPasteboard = .general,
        settingsModel: SettingsModel = .shared
    ) {
        self.permissionsManager = permissionsManager
        self.pasteboard = pasteboard
        self.settingsModel = settingsModel
    }

    func paste(_ text: String) throws {
        guard permissionsManager.accessibilityGranted else {
            throw PasteError.accessibilityNotGranted
        }

        let clipboardSnapshot = settingsModel.restoreClipboardAfterPaste ? captureClipboardSnapshot() : nil

        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw PasteError.clipboardWriteFailed
        }
        let murmurClipboardChangeCount = pasteboard.changeCount

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

        if let clipboardSnapshot {
            scheduleClipboardRestore(clipboardSnapshot, expectedChangeCount: murmurClipboardChangeCount)
        }
    }

    private func captureClipboardSnapshot() -> ClipboardSnapshot? {
        let existingItems = pasteboard.pasteboardItems ?? []
        guard !existingItems.isEmpty else {
            return ClipboardSnapshot(items: [], wasEmpty: true)
        }

        let copiedItems = existingItems.compactMap { $0.copy() as? NSPasteboardItem }
        guard copiedItems.count == existingItems.count else {
            return nil
        }

        return ClipboardSnapshot(items: copiedItems, wasEmpty: false)
    }

    private func scheduleClipboardRestore(_ snapshot: ClipboardSnapshot, expectedChangeCount: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            Task { @MainActor in
                guard let self else { return }
                self.restoreClipboardIfUnchanged(snapshot, expectedChangeCount: expectedChangeCount)
            }
        }
    }

    private func restoreClipboardIfUnchanged(_ snapshot: ClipboardSnapshot, expectedChangeCount: Int) {
        guard pasteboard.changeCount == expectedChangeCount else {
            return
        }

        pasteboard.clearContents()
        guard !snapshot.wasEmpty else {
            return
        }

        _ = pasteboard.writeObjects(snapshot.items)
    }
}
