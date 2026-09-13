// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "FnSwitcher",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "3.1.0"),
    ],
    targets: [
        .target(
            name: "FnSwitcherCore",
            path: "Sources/FnSwitcherCore"
        ),
        .executableTarget(
            name: "FnSwitcher",
            dependencies: [
                "FnSwitcherCore",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts"),
            ],
            path: "Sources/FnSwitcher",
            swiftSettings: [.defaultIsolation(MainActor.self)]
        ),
        .testTarget(
            name: "FnSwitcherCoreTests",
            dependencies: ["FnSwitcherCore"],
            path: "Tests/FnSwitcherCoreTests"
        ),
    ]
)
