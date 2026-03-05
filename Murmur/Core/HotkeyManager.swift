import Carbon.HIToolbox
import Foundation

final class HotkeyManager {
    enum HotkeyError: LocalizedError {
        case installHandlerFailed(OSStatus)
        case registerFailed(OSStatus)
        case unregisterFailed(OSStatus)
        case eventParameterReadFailed(OSStatus)

        var errorDescription: String? {
            switch self {
            case .installHandlerFailed(let status):
                return "Failed to install hotkey event handler (OSStatus: \(status))."
            case .registerFailed(let status):
                return "Failed to register hotkey (OSStatus: \(status))."
            case .unregisterFailed(let status):
                return "Failed to unregister hotkey (OSStatus: \(status))."
            case .eventParameterReadFailed(let status):
                return "Failed to read hotkey event payload (OSStatus: \(status))."
            }
        }
    }

    var onToggle: ((Bool) -> Void)?
    private(set) var isRecording = false
    private(set) var lastError: Error?

    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    private let hotKeySignature: OSType = 0x4D55524D // 'MURM'
    private let hotKeyID: UInt32 = 1

    func register(keyCode: UInt32, modifiers: UInt32) {
        unregister()

        let installStatus = installHandlerIfNeeded()
        guard installStatus == noErr else {
            setError(HotkeyError.installHandlerFailed(installStatus))
            return
        }

        let eventHotKeyID = EventHotKeyID(signature: hotKeySignature, id: hotKeyID)
        let registerStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            eventHotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        guard registerStatus == noErr else {
            hotKeyRef = nil
            setError(HotkeyError.registerFailed(registerStatus))
            return
        }

        lastError = nil
        isRecording = false
    }

    func unregister() {
        guard let hotKeyRef else { return }

        let status = UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
        isRecording = false

        if status != noErr {
            setError(HotkeyError.unregisterFailed(status))
        }
    }

    deinit {
        unregister()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func installHandlerIfNeeded() -> OSStatus {
        if eventHandlerRef != nil {
            return noErr
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        return InstallEventHandler(
            GetEventDispatcherTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            userData,
            &eventHandlerRef
        )
    }

    fileprivate func handleHotKeyEvent(_ event: EventRef) -> OSStatus {
        var pressedHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            OSType(kEventParamDirectObject),
            OSType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &pressedHotKeyID
        )

        guard status == noErr else {
            setError(HotkeyError.eventParameterReadFailed(status))
            return noErr
        }

        guard pressedHotKeyID.signature == hotKeySignature, pressedHotKeyID.id == hotKeyID else {
            return noErr
        }

        isRecording.toggle()
        onToggle?(isRecording)
        return noErr
    }

    private func setError(_ error: Error) {
        lastError = error
        print("HotkeyManager error: \(error.localizedDescription)")
    }
}

private let hotKeyEventHandler: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else { return noErr }

    let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
    return manager.handleHotKeyEvent(event)
}
