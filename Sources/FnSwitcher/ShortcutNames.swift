import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    /// Toggles between standard function keys and media keys. Default ⌃⌥F.
    static let toggleFnMode = Self("toggleFnMode", initial: .init(.f, modifiers: [.control, .option]))
}
