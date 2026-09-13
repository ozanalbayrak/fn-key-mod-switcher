import Foundation
import FnSwitcherCore

// Temporary CLI (replaced in Task 4): `FnSwitcher [toggle]`
let backend = IOHIDSystemBackend()
let before = try backend.readMode()
print("before:", before)
if CommandLine.arguments.contains("toggle") {
    try backend.writeMode(before.toggled)
    print("after:", try backend.readMode())
}
