import Foundation

/// Owns the current Fn key mode, applies changes through a backend and
/// follows changes made elsewhere (e.g. System Settings).
@MainActor
public final class FnKeyModeController {
    public enum State: Equatable {
        case mode(FnKeyMode)
        /// The backend failed; the associated value is a user-facing message.
        case unavailable(String)
    }

    public private(set) var state: State {
        didSet {
            guard state != oldValue else { return }
            onStateChange?(state)
        }
    }

    /// Called on the main actor whenever `state` changes.
    public var onStateChange: (@MainActor (State) -> Void)?

    private let backend: FnKeyModeBackend
    private let notificationCenter: NotificationCenter
    private nonisolated(unsafe) var observer: NSObjectProtocol?

    public init(
        backend: FnKeyModeBackend,
        notificationCenter: NotificationCenter = DistributedNotificationCenter.default()
    ) {
        self.backend = backend
        self.notificationCenter = notificationCenter
        self.state = Self.read(from: backend)

        // queue: nil → delivered synchronously on the posting thread. The
        // distributed center delivers on the main thread; tests post from main.
        observer = notificationCenter.addObserver(
            forName: .fnStateDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            if Thread.isMainThread {
                MainActor.assumeIsolated { self?.refresh() }
            } else {
                Task { @MainActor in self?.refresh() }
            }
        }
    }

    deinit {
        if let observer {
            notificationCenter.removeObserver(observer)
        }
    }

    /// Re-reads the mode from the backend.
    public func refresh() {
        state = Self.read(from: backend)
    }

    public func set(_ mode: FnKeyMode) {
        do {
            try backend.writeMode(mode)
            state = .mode(mode)
        } catch {
            state = .unavailable(Self.message(for: error, action: "change"))
        }
    }

    /// Flips the mode. If the last read failed, reads again first so a
    /// transient error doesn't leave the shortcut dead.
    public func toggle() {
        if case .unavailable = state {
            refresh()
        }
        guard case .mode(let current) = state else { return }
        set(current.toggled)
    }

    private static func read(from backend: FnKeyModeBackend) -> State {
        do {
            return .mode(try backend.readMode())
        } catch {
            return .unavailable(message(for: error, action: "read"))
        }
    }

    private static func message(for error: Error, action: String) -> String {
        switch error {
        case FnKeyModeError.hidSystemUnavailable(let code):
            "Could not connect to the keyboard system (error \(code))."
        case FnKeyModeError.readFailed(let code), FnKeyModeError.writeFailed(let code):
            "Could not \(action) the Fn key mode (error \(code))."
        default:
            "Could not \(action) the Fn key mode: \(error.localizedDescription)"
        }
    }
}
