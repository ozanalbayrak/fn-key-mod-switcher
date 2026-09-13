# Security

FnSwitcher runs unsandboxed and talks to `IOHIDSystem` to flip the Fn key mode;
it does not read keystrokes, access the network, or persist anything beyond
the shortcut preference.

If you believe you have found a security issue, please report it privately via
[GitHub's private vulnerability reporting](https://github.com/ozanalbayrak/fn-key-mod-switcher/security/advisories/new)
rather than opening a public issue. You'll get a response within a week.
