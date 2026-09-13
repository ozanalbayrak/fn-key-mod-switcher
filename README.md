# FnSwitcher

A tiny macOS menu bar app that toggles the F1–F12 keys between
**standard function keys** and **media keys** (brightness, volume, …) with a
global keyboard shortcut — no more digging through System Settings.

- Menu bar icon shows the current mode (`⌨` = standard F1–F12, `☀` = media keys)
- Configurable global shortcut (default **⌃⌥F**)
- Launch at Login
- No Accessibility / Input Monitoring permission required

## Install

Runs on macOS 13+.

### Homebrew (recommended)

```bash
brew install --cask ozanalbayrak/tap/fnswitcher
```

Homebrew 6+ asks you to trust third-party taps the first time:
`brew trust ozanalbayrak/tap`. The cask clears the quarantine flag for you,
so the app opens without the Gatekeeper dialog.

### Download

1. Grab `FnSwitcher-<version>.zip` from the
   [latest release](https://github.com/ozanalbayrak/fn-key-mod-switcher/releases/latest)
   and unzip it.
2. Move `FnSwitcher.app` to `/Applications`.
3. The app is ad-hoc signed (not notarized), so macOS will refuse to open it
   until you clear the quarantine flag once:
   ```bash
   xattr -d com.apple.quarantine /Applications/FnSwitcher.app
   ```
   (or open it once via System Settings → Privacy & Security → *Open Anyway*).
4. `open /Applications/FnSwitcher.app`

Apple Silicon only for now.

### Build from source

Requires Xcode 26 (Swift 6.2) or later.

```bash
git clone https://github.com/ozanalbayrak/fn-key-mod-switcher.git
cd fn-key-mod-switcher
scripts/build.sh --install
open /Applications/FnSwitcher.app
```

`scripts/build.sh` without `--install` leaves the bundle at `build/FnSwitcher.app`;
`--zip` produces `build/FnSwitcher-<VERSION>.zip` (used by the release workflow).
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

CI runs `swift test` and `scripts/build.sh` on every push and pull request.

### Releasing

Push a `v*` tag; the release workflow builds, zips and publishes a GitHub
release with the SHA-256 in the notes, then bumps the Homebrew cask in
[ozanalbayrak/homebrew-tap](https://github.com/ozanalbayrak/homebrew-tap):

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Security issues: [SECURITY.md](SECURITY.md).

## License

MIT
