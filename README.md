# FnSwitcher

A tiny macOS menu bar app that toggles the F1–F12 keys between
**standard function keys** and **media keys** (brightness, volume, …) with a
global keyboard shortcut — no more digging through System Settings.

- Menu bar icon shows the current mode (`⌨` = standard F1–F12, `☀` = media keys)
- Configurable global shortcut (default **⌃⌥F**)
- Launch at Login
- No Accessibility / Input Monitoring permission required

## Install

Runs on macOS 13+. Building requires Xcode 26 (Swift 6.2) or later.

```bash
git clone https://github.com/ozanalbayrak/fn-key-mod-switcher.git
cd fn-key-mod-switcher
scripts/build.sh --install
open /Applications/FnSwitcher.app
```

`scripts/build.sh` without `--install` leaves the bundle at `build/FnSwitcher.app`.
After installing, always launch the copy in `/Applications` (not the one in
`build/`) so that Launch at Login points at the installed app.

## Usage

Press the shortcut (default ⌃⌥F) to toggle. Click the menu bar icon to see the
mode, toggle, change the shortcut (**Settings…**), or enable **Launch at Login**.

## How it works

The mode is the `HIDFKeyMode` parameter of the `IOHIDSystem` service. FnSwitcher
sets it via `IOHIDSetParameter`, mirrors it into the
`com.apple.keyboard.fnState` user default and posts
`com.apple.keyboard.fnstatedidchange` so System Settings stays in sync. It also
listens for that notification, so changes made in System Settings show up in
the menu bar immediately.

## Development

```bash
swift test            # unit tests (pure logic, fake HID backend)
swift build           # debug build
open Package.swift    # open in Xcode
```

## License

MIT
