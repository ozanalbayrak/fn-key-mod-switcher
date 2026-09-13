import Foundation
import IOKit
import IOKit.hidsystem

/// Talks to the `IOHIDSystem` kernel service. `IOHIDGetParameter` /
/// `IOHIDSetParameter` are deprecated since 10.12 but still work (verified on
/// macOS 26.6) and need no TCC permission. Writing the user default and posting
/// the distributed notification keeps System Settings in sync; on their own
/// they do *not* change the live mode.
public struct IOHIDSystemBackend: FnKeyModeBackend {
    private static var fnStateDefaultsKey: CFString { "com.apple.keyboard.fnState" as CFString }

    public init() {}

    public func readMode() throws -> FnKeyMode {
        let connection = try openConnection()
        defer { IOServiceClose(connection) }

        var value: UInt32 = 0
        var actualSize: IOByteCount = 0
        let result = IOHIDGetParameter(
            connection,
            kIOHIDFKeyModeKey as CFString,
            IOByteCount(MemoryLayout<UInt32>.size),
            &value,
            &actualSize
        )
        guard result == KERN_SUCCESS else { throw FnKeyModeError.readFailed(result) }
        return FnKeyMode(hidValue: value)
    }

    public func writeMode(_ mode: FnKeyMode) throws {
        let connection = try openConnection()
        defer { IOServiceClose(connection) }

        var value = mode.hidValue
        let result = IOHIDSetParameter(
            connection,
            kIOHIDFKeyModeKey as CFString,
            &value,
            IOByteCount(MemoryLayout<UInt32>.size)
        )
        guard result == KERN_SUCCESS else { throw FnKeyModeError.writeFailed(result) }

        CFPreferencesSetValue(
            Self.fnStateDefaultsKey,
            (mode == .functionKeys) as CFBoolean,
            kCFPreferencesAnyApplication,
            kCFPreferencesCurrentUser,
            kCFPreferencesAnyHost
        )
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)

        DistributedNotificationCenter.default().postNotificationName(
            .fnStateDidChange,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private func openConnection() throws -> io_connect_t {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOHIDSystem"))
        guard service != IO_OBJECT_NULL else { throw FnKeyModeError.hidSystemUnavailable(KERN_FAILURE) }
        defer { IOObjectRelease(service) }

        var connection: io_connect_t = IO_OBJECT_NULL
        let result = IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connection)
        guard result == KERN_SUCCESS else { throw FnKeyModeError.hidSystemUnavailable(result) }
        return connection
    }
}
