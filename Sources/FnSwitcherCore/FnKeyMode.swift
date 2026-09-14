/// The two behaviours of the F1–F12 row on Apple keyboards.
public enum FnKeyMode: Sendable, Equatable, CaseIterable {
    /// F1–F12 act as standard function keys; media actions need the Fn key.
    case functionKeys
    /// F1–F12 perform brightness/volume/etc.; function keys need the Fn key.
    case mediaKeys

    /// Value of the `HIDFKeyMode` IOHIDSystem parameter. 1 = function keys, 0 = media keys.
    public var hidValue: UInt32 {
        switch self {
        case .functionKeys: 1
        case .mediaKeys: 0
        }
    }

    public init(hidValue: UInt32) {
        self = hidValue == 1 ? .functionKeys : .mediaKeys
    }

    public var toggled: FnKeyMode {
        self == .functionKeys ? .mediaKeys : .functionKeys
    }

    /// Human-readable name of this mode.
    public var title: String {
        switch self {
        case .functionKeys: "Standard F1–F12"
        case .mediaKeys: "Media Keys"
        }
    }

    /// Menu item title for switching *away* from this mode.
    public var switchActionTitle: String {
        "Switch to \(toggled.title)"
    }

    /// Name of the template image (bundled PDF) shown in the menu bar while
    /// this mode is active.
    public var menuBarImageName: String {
        switch self {
        case .functionKeys: "menubar-fkey"
        case .mediaKeys: "menubar-media"
        }
    }
}
