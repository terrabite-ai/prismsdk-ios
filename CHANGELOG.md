# Changelog

All notable changes to Prism SDK for iOS. This project follows
[Semantic Versioning](https://semver.org/spec/v2.0.0.html). Below 1.0.0, a
minor version may change the API.

## [0.1.0] — 2026-09-14

First release.

### Added

- `Prism`, the entry point: initialise with an API key, start and stop
  tracking, reset.
- Background location tracking with visit detection. `PrismLocation` carries
  the fix, the device and app state when it was taken, and, for visits, the
  arrival and departure times.
- Three tracking modes, `precise`, `standard` and `efficient`, and a
  configurable horizontal-accuracy threshold, set through `PrismConfig`.
- Delivery by `PrismLocationDelegate`, by closure (`onLocation`, `onError`),
  or by `AsyncStream` (`locations()`, `errors()`).
- Permission handling: foreground and background requests with closure and
  `async` forms, and `PrismPermissionStatus` for the full state without
  prompting, including Approximate Location.
- User identity and metadata attached to every location.
- Objective-C support: `Prism`, `PrismLocation`, `PrismConfig` and
  `PrismLocationDelegate`, plus `asDictionary` for bridged hosts.
- Swift Package Manager and CocoaPods installation. iOS 15 or later.

### Notes

- Tracking only. Locations are delivered to your app and nowhere else.
- `PrismLocationDelegate` and `setLocationDelegate` are `@MainActor`.
  Callbacks arrive on the main actor.
- Builds clean in Swift 5 with strict concurrency and in the Swift 6
  language mode.

[0.1.0]: https://github.com/terrabite-ai/prismsdk-ios/releases/tag/0.1.0
