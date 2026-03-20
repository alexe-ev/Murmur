import XCTest
@testable import Murmur

final class MenuBarStateTests: XCTestCase {
    func testErrorStateEquatable() {
        let a = MenuBarState.error("API error: timeout")
        let b = MenuBarState.error("API error: timeout")
        let c = MenuBarState.error("Different error")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testErrorStateNotEqualToIdle() {
        XCTAssertNotEqual(MenuBarState.error("something"), MenuBarState.idle)
    }

    func testBasicStatesStillEqual() {
        XCTAssertEqual(MenuBarState.idle, .idle)
        XCTAssertEqual(MenuBarState.recording, .recording)
        XCTAssertEqual(MenuBarState.processing, .processing)
        XCTAssertNotEqual(MenuBarState.idle, .recording)
    }
}

@MainActor
final class IndicatorStateTests: XCTestCase {
    func testInitialState() {
        let state = IndicatorState()

        XCTAssertEqual(state.menuBarState, .idle)
        XCTAssertNil(state.lastTranscript)
        XCTAssertNil(state.errorMessage)
        XCTAssertFalse(state.isExpanded)
    }

    func testLastTranscriptPreservedAcrossStates() {
        let state = IndicatorState()

        state.lastTranscript = "Some transcribed text"
        state.menuBarState = .error("Paste failed")
        state.errorMessage = "Paste failed"

        XCTAssertEqual(state.lastTranscript, "Some transcribed text")
        XCTAssertEqual(state.errorMessage, "Paste failed")
    }
}
