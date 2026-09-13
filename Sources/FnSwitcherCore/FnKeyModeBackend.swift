import Foundation

/// Reads and writes the system-wide Fn key mode.
public protocol FnKeyModeBackend: Sendable {
    func readMode() throws -> FnKeyMode
    func writeMode(_ mode: FnKeyMode) throws
}

public enum FnKeyModeError: Error, Equatable {
    case hidSystemUnavailable(kern_return_t)
    case readFailed(kern_return_t)
    case writeFailed(kern_return_t)
}

public extension Notification.Name {
    /// Posted (distributed) by System Settings and by us whenever the Fn key mode changes.
    static let fnStateDidChange = Notification.Name("com.apple.keyboard.fnstatedidchange")
}
