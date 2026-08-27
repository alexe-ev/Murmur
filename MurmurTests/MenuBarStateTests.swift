import XCTest
@testable import Murmur

final class MenuBarStateTests: XCTestCase {
    func testErrorStateEquatable() {
        let a = MenuBarState.error(headline: "API error: timeout", detail: nil)
        let b = MenuBarState.error(headline: "API error: timeout", detail: nil)
        let c = MenuBarState.error(headline: "Different error", detail: nil)
        let d = MenuBarState.error(headline: "API error: timeout", detail: "body")

        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
        XCTAssertNotEqual(a, d)
    }

    func testErrorStateNotEqualToIdle() {
        XCTAssertNotEqual(MenuBarState.error(headline: "something", detail: nil), MenuBarState.idle)
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
        XCTAssertNil(state.errorDetail)
        XCTAssertFalse(state.isExpanded)
    }

    func testLastTranscriptPreservedAcrossStates() {
        let state = IndicatorState()

        state.lastTranscript = "Some transcribed text"
        state.menuBarState = .error(headline: "Paste failed", detail: "Some transcribed text")
        state.errorMessage = "Paste failed"

        XCTAssertEqual(state.lastTranscript, "Some transcribed text")
        XCTAssertEqual(state.errorMessage, "Paste failed")
    }
}
