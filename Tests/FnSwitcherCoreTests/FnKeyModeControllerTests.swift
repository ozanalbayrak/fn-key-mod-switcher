import XCTest
@testable import FnSwitcherCore

/// In-memory backend. `failure` makes every call throw.
final class FakeBackend: FnKeyModeBackend, @unchecked Sendable {
    var mode: FnKeyMode = .mediaKeys
    var failure: FnKeyModeError?
    var writes: [FnKeyMode] = []

    func readMode() throws -> FnKeyMode {
        if let failure { throw failure }
        return mode
    }

    func writeMode(_ mode: FnKeyMode) throws {
        if let failure { throw failure }
        writes.append(mode)
        self.mode = mode
    }
}

@MainActor
final class FnKeyModeControllerTests: XCTestCase {
    private var backend: FakeBackend!
    private var center: NotificationCenter!
    private var controller: FnKeyModeController!
    private var observed: [FnKeyModeController.State] = []

    override func setUp() async throws {
        try await super.setUp()
        backend = FakeBackend()
        center = NotificationCenter()
        controller = FnKeyModeController(backend: backend, notificationCenter: center)
        observed = []
        controller.onStateChange = { [unowned self] in observed.append($0) }
    }

    func testInitialStateReadsBackend() {
        XCTAssertEqual(controller.state, .mode(.mediaKeys))
    }

    func testSetWritesBackendAndUpdatesState() {
        controller.set(.functionKeys)
        XCTAssertEqual(backend.writes, [.functionKeys])
        XCTAssertEqual(controller.state, .mode(.functionKeys))
        XCTAssertEqual(observed, [.mode(.functionKeys)])
    }

    func testToggleFlipsMode() {
        controller.toggle()
        XCTAssertEqual(controller.state, .mode(.functionKeys))
        controller.toggle()
        XCTAssertEqual(controller.state, .mode(.mediaKeys))
        XCTAssertEqual(backend.writes, [.functionKeys, .mediaKeys])
    }

    func testToggleWhileUnavailableRetriesReadFirst() {
        backend.failure = .readFailed(-1)
        controller.refresh()
        XCTAssertEqual(controller.state, .unavailable("Could not read the Fn key mode (error -1)."))

        backend.failure = nil
        backend.mode = .functionKeys
        controller.toggle()
        XCTAssertEqual(backend.writes, [.mediaKeys])
        XCTAssertEqual(controller.state, .mode(.mediaKeys))
    }

    func testWriteFailureBecomesUnavailable() {
        backend.failure = .writeFailed(-5)
        controller.set(.functionKeys)
        XCTAssertEqual(controller.state, .unavailable("Could not change the Fn key mode (error -5)."))
    }

    func testExternalChangeNotificationRefreshesState() {
        backend.mode = .functionKeys
        center.post(name: .fnStateDidChange, object: nil)
        XCTAssertEqual(controller.state, .mode(.functionKeys))
        XCTAssertEqual(observed, [.mode(.functionKeys)])
    }

    func testUnchangedRefreshDoesNotNotify() {
        controller.refresh()
        XCTAssertEqual(observed, [])
    }
}
