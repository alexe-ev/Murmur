import ApplicationServices
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
    private let axMessagingTimeout: Float = 0.15

    init(
        permissionsManager: PermissionsManager,
        pasteboard: NSPasteboard = .general,
        settingsModel: SettingsModel
    ) {
        self.permissionsManager = permissionsManager
        self.pasteboard = pasteboard
        self.settingsModel = settingsModel
    }

    convenience init(pasteboard: NSPasteboard = .general) {
        self.init(
            permissionsManager: .shared,
            pasteboard: pasteboard,
            settingsModel: .shared
        )
    }

    func paste(_ text: String) throws {
        permissionsManager.checkAccessibility()
        guard permissionsManager.accessibilityGranted else {
            throw PasteError.accessibilityNotGranted
        }

        // Prefer direct AX insertion to avoid layout-dependent Cmd+V behavior.
        if tryInsertTextViaAccessibility(text) {
            return
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

    private func tryInsertTextViaAccessibility(_ text: String) -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        _ = AXUIElementSetMessagingTimeout(systemWideElement, axMessagingTimeout)
        var focusedValue: CFTypeRef?
        let focusedStatus = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        )

        guard
            focusedStatus == .success,
            let focusedValue,
            CFGetTypeID(focusedValue) == AXUIElementGetTypeID()
        else {
            return false
        }

        let focusedElement = unsafeBitCast(focusedValue, to: AXUIElement.self)
        _ = AXUIElementSetMessagingTimeout(focusedElement, axMessagingTimeout)

        var focusedPid: pid_t = 0
        if AXUIElementGetPid(focusedElement, &focusedPid) == .success, focusedPid > 0 {
            let appElement = AXUIElementCreateApplication(focusedPid)
            _ = AXUIElementSetMessagingTimeout(appElement, axMessagingTimeout)
        }

        var selectedTextSettable = DarwinBoolean(false)
        let selectedTextSettableStatus = AXUIElementIsAttributeSettable(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextSettable
        )
        if selectedTextSettableStatus == .success, selectedTextSettable.boolValue {
            let selectedTextStatus = AXUIElementSetAttributeValue(
                focusedElement,
                kAXSelectedTextAttribute as CFString,
                text as CFTypeRef
            )
            if selectedTextStatus == .success {
                return true
            }
        }

        return false
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
