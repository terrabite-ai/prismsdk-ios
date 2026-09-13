# prismsdk-ios

## Project Overview

Prism SDK for iOS: a Swift wrapper over the LocalSDKCore tracking engine. The
wrapper is source; the engine is a binary XCFramework. Integrators
`import PrismSDK` and see only Prism's types. The engine's own repository is
`localsdk/localsdk-ios-core`; its source is not here and is not public.

## Project Structure

```
Sources/PrismSDK/       # The wrapper. Every public type is Prism's own.
Sources/PrismSDK/ObjC/  # Objective-C facade over the Swift API.
Frameworks/             # LocalSDKCore.xcframework, the engine. Build output, not source.
Tests/PrismSDKTests/    # Mapping tests. Swift Testing (@Suite / @Test / #expect).
Package.swift           # Package `prismsdk-ios`, product `PrismSDK`, binaryTarget by path.
PrismSDK.podspec        # Same two modules for CocoaPods. Not published to trunk.
prismsdk-ios.xcworkspace
.swiftpm/xcode/xcshareddata/xcschemes/PrismSDK.xcscheme
```

## Rules

**Prism's public API never names an engine type.** `Location`, `Config`,
`TrackingMode`, `PermissionStatus`, `LocationDelegate` and `LocalSDK` appear only
inside `internal` mapping initialisers and `core` accessors. Check with:

```bash
grep -rn "public" Sources/PrismSDK | grep -E "\b(Location|Config|TrackingMode|PermissionStatus|LocationDelegate|LocalSDK)\b"
```

**Every `switch` over an engine enum needs `@unknown default`.** The engine is
built with library evolution, so its enums are not frozen. Without it the
build warns in Swift 5 and fails in Swift 6.

**No `static var` in `Prism` or `PrismObjC`.** Static mutable state is rejected
by the Swift 6 language mode. Use the `Retained` box in
`PrismLocationDelegate.swift` or a `let` of a `Sendable` type.

**Objective-C names are API.** `@objc(...)` names, `bridgedName` strings, the
raw values of `PrismTrackingMode` and `PrismLocationType`, and the keys of
`asDictionary` are branched on by Objective-C and React Native hosts. Add to
them; never rename.

**Adding a field to `PrismLocation` means four edits**: `PrismLocation`,
`PrismLocationObjC`, `asDictionary`, and the 29-field count in
`PrismLocationMappingTests`. The count test fails first if the engine grows.

## Build & Test

```bash
make build   # wrapper against the vendored engine
make test    # mapping tests on a simulator (default: iPhone 17 Pro)
make lint    # pod lib lint
```

Always run `make test` before committing. It takes under a minute.

Override the simulator with `make test DESTINATION="platform=iOS Simulator,name=iPhone 16"`.

`xcodebuild test` needs the shared scheme in `.swiftpm/xcode/xcshareddata/`.
Xcode's auto-generated product scheme has no test action. Do not delete it.

Plain `swift build` does not work: it cannot find UIKit. Use `xcodebuild` via
the Makefile.

## Refreshing the engine

```bash
make xcframework ENGINE=/path/to/localsdk-ios-core
```

This exports the engine's HEAD to a temporary directory and runs the engine's
own `Scripts/build-xcframework.sh`, so what ships is what is committed there.
After a refresh, run `make test` and check the swiftinterface still has every
`LocalSDK` static the wrapper calls.

## Concurrency

The engine dispatches delegate and closure callbacks on the main queue.
`AsyncStream` consumers receive values on whatever executor they run on. The
`@MainActor` entry points are those that present a system prompt or read
CoreLocation authorisation state.

## Decided

**Prism is tracking-only.** It links `LocalSDKCore` and nothing else. The
engine's `LocalSDKSync` product (offline buffering, MQTT publishing) is
deliberately not linked and not exposed; locations go to the host app and
nowhere else. Do not add it. Decided 2026-09-13.

## Open decisions

Do not resolve these silently; ask.

- **Objective-C naming.** The design note says `PRSM`-prefixed classes. The
  code uses `@objc(Prism)`, `@objc(PrismLocation)`, `@objc(PrismConfig)`,
  `@objc(PrismLocationDelegate)`. The comment in `PrismObjC.swift` argues for
  the unprefixed form and then claims the value types use `PRSM`, which they
  do not.
- **`PrismLocation` coding keys** are synthesized camelCase; the engine's
  `Location` and `asDictionary` use snake_case wire names.

## Not yet in the repository

`Example/PrismDemo`, `docs/`, `PrivacyInfo.xcprivacy`, CHANGELOG, CI.
