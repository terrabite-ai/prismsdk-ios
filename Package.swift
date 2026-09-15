// swift-tools-version: 5.9
import PackageDescription

// Prism SDK for iOS.
//
// Two targets: `PrismSDK` is the source wrapper and the only thing an integrator
// is meant to import; `LocalSDKCore` is the tracking engine, shipped as a binary
// XCFramework and referenced by path. An integrator adds this package, writes
// `import PrismSDK`, and works with `Prism`, `PrismLocation`, `PrismConfig` and
// the rest — none of which mention the engine's types.
//
// The XCFramework is committed under `Frameworks/` and referenced by `path`
// rather than by `url` + `checksum`. A release-asset URL would keep the binary
// out of git history, but it would also put an engine-named zip on every
// release page, and the release page is meant to show only Prism. 2.7 MB per
// engine bump is the price of that. Rebuild the framework with the engine's
// `Scripts/build-xcframework.sh` and copy the result here.
//
// The package is named after the repository and the product after the module,
// as the engine does (`localsdk-ios-core` / `LocalSDKCore`). SwiftPM identifies
// a dependency by the last path component of its URL, so `prismsdk-ios` is the
// identity integrators get anyway; `PrismSDK` is what they type after `import`.
//
// Tests run through the shared scheme committed at
// .swiftpm/xcode/xcshareddata/xcschemes/PrismSDK.xcscheme — Xcode's
// auto-generated product scheme carries no test action.
//
// Tools version 5.9 matches the engine and the podspec's `swift_versions`.
let package = Package(
    name: "prismsdk-ios",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "PrismSDK",
            targets: ["PrismSDK"]
        )
    ],
    targets: [
        .target(
            name: "PrismSDK",
            dependencies: ["LocalSDKCore"],
            path: "Sources/PrismSDK",
            swiftSettings: [
                // Surfaces every data-race diagnostic the Swift 6 language mode
                // would turn into an error, while still building as Swift 5.
                // This is what catches an unguarded `static var` before a
                // Swift 6 host does.
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .binaryTarget(
            name: "LocalSDKCore",
            path: "Frameworks/LocalSDKCore.xcframework"
        ),
        // Mapping round-trips. The wrapper is three hand-written copies of a
        // 29-field model, and a mistyped field in any of them is silent, so this
        // is the one place tests genuinely earn their keep. Depends on
        // `LocalSDKCore` directly because fixtures are engine values.
        .testTarget(
            name: "PrismSDKTests",
            dependencies: ["PrismSDK", "LocalSDKCore"],
            path: "Tests/PrismSDKTests"
        ),
    ]
)
