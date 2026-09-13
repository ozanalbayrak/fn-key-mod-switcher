import XCTest
@testable import FnSwitcherCore

final class FnKeyModeTests: XCTestCase {
    func testHidValueRoundTrip() {
        XCTAssertEqual(FnKeyMode.functionKeys.hidValue, 1)
        XCTAssertEqual(FnKeyMode.mediaKeys.hidValue, 0)
        XCTAssertEqual(FnKeyMode(hidValue: 1), .functionKeys)
        XCTAssertEqual(FnKeyMode(hidValue: 0), .mediaKeys)
    }

    func testUnknownHidValueFallsBackToMediaKeys() {
        XCTAssertEqual(FnKeyMode(hidValue: 42), .mediaKeys)
    }

    func testToggled() {
        XCTAssertEqual(FnKeyMode.functionKeys.toggled, .mediaKeys)
        XCTAssertEqual(FnKeyMode.mediaKeys.toggled, .functionKeys)
    }

    func testTitlesAndSymbols() {
        XCTAssertEqual(FnKeyMode.functionKeys.title, "Standard F1–F12")
        XCTAssertEqual(FnKeyMode.mediaKeys.title, "Media Keys")
        XCTAssertEqual(FnKeyMode.functionKeys.switchActionTitle, "Switch to Media Keys")
        XCTAssertEqual(FnKeyMode.mediaKeys.switchActionTitle, "Switch to Standard F1–F12")
        XCTAssertEqual(FnKeyMode.functionKeys.menuBarSymbolName, "keyboard")
        XCTAssertEqual(FnKeyMode.mediaKeys.menuBarSymbolName, "sun.max")
    }
}
