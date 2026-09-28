# Prism SDK for iOS

Background location tracking for iOS apps. Add Prism, ask for permission once,
and receive your users' locations in the foreground and the background, with
the battery cost you choose.

Requires iOS 15 or later. Swift and Objective-C.

## Install

<!-- Remove this block when 0.2.0 is released. -->
> **0.2.0 is not released yet.** It is on the `release/0.2.0` branch for
> testing. Until it is tagged, install from the branch as shown under
> [Testing 0.2.0 before release](#testing-020-before-release). The latest
> released version is 0.1.0, which has no Places API.

**Swift Package Manager.** In Xcode, File → Add Package Dependencies, and enter:

```
https://github.com/terrabite-ai/prismsdk-ios
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/terrabite-ai/prismsdk-ios", from: "0.2.0")
```

Add the `PrismSDK` product to your target.

**CocoaPods.**

```ruby
pod 'PrismSDK', :git => 'https://github.com/terrabite-ai/prismsdk-ios.git', :tag => '0.2.0'
```

Prism brings two binary frameworks with it, the tracking engine and place
inference. Both are inside the package; there is nothing else to add.

<!-- Remove this section when 0.2.0 is released. -->
### Testing 0.2.0 before release

Swift Package Manager, in Xcode: add the package as above and set
Dependency Rule to Branch, `release/0.2.0`. In `Package.swift`:

```swift
.package(url: "https://github.com/terrabite-ai/prismsdk-ios", branch: "release/0.2.0")
```

CocoaPods:

```ruby
pod 'PrismSDK', :git => 'https://github.com/terrabite-ai/prismsdk-ios.git', :branch => 'release/0.2.0'
```

A branch moves. After the branch is updated, use File → Packages → Update to
Latest Package Versions, or `pod update PrismSDK`. The API can still change
before the release.

## Set up your app

Add these to your target's Info.plist. iOS shows the two strings in its
permission dialogs, so say what you do with location.

| Key | Value |
|---|---|
| `NSLocationWhenInUseUsageDescription` | Why you need location while the app is open |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Why you need it in the background |
| `UIBackgroundModes` | `location` |

Without the background mode, iOS suspends your app when it leaves the
foreground and tracking stops with it.

## Quick start

### Swift

```swift
import PrismSDK

// @MainActor because requesting permission presents a system prompt, and the
// compiler enforces that it happens on the main actor.
@MainActor
final class Tracking: PrismLocationDelegate {

    func start() {
        Prism.initialize(apiKey: "your-sdk-key")
        Prism.setLocationDelegate(self)
        Prism.requestLocationPermission { granted in
            if granted { Prism.startTracking() }
        }
    }

    func locationDidUpdate(_ location: PrismLocation) {
        print(location.latitude, location.longitude)
    }

    func locationDidFail(_ error: String) {
        print("Prism:", error)
    }
}
```

Prism holds the delegate weakly, so keep your own reference to it. Delegate
callbacks arrive on the main thread.

If you prefer `async`:

```swift
Task {
    for await location in Prism.locations() {
        print(location.latitude, location.longitude)
    }
}
```

### Objective-C

```objc
@import PrismSDK;

@interface Tracking : NSObject <PrismLocationDelegate>
@end

@implementation Tracking

- (void)start {
    [Prism initializeWithApiKey:@"your-sdk-key"];
    [Prism setLocationDelegate:self];
    [Prism requestLocationPermissionWithCompletion:^(BOOL granted) {
        if (granted) { [Prism startTracking]; }
    }];
}

- (void)locationDidUpdate:(PrismLocation *)location {
    NSLog(@"%f, %f", location.latitude, location.longitude);
}

- (void)locationDidFail:(NSString *)error {
    NSLog(@"Prism: %@", error);
}

@end
```

## Configure

Optional. The defaults are sensible.

```swift
Prism.setConfig(
    PrismConfig()
        .withTrackingMode(.standard)            // .precise, .standard or .efficient
        .withHorizontalAccuracyThreshold(50)    // discard fixes worse than 50 m
)
```

`.precise` updates most often and costs the most battery. `.efficient` is the
opposite. `.standard` is the usual choice.

## Background permission

iOS never grants "Always" directly. Ask for foreground permission first, start
tracking, then ask to extend it:

```swift
Prism.requestBackgroundLocationPermission { granted in
    // granted is true only once the user has chosen "Always"
}
```

`Prism.locationPermissionStatus()` tells you the current state without
prompting, including whether the user chose Approximate Location.

## Identify the user

```swift
Prism.setUserId("user-123")
Prism.setMetadata(["plan": "gold"])
```

Both are attached to every location that follows.

## Places

New in 0.2.0. Prism can infer where the user lives and which places they
return to, from the locations it already delivers. Everything runs on the
device; Prism never sends places anywhere. It is off by default.

### Turn it on

Add an `enrich` block to the configuration:

```swift
Prism.initialize(apiKey: "your-sdk-key")
Prism.setConfig(
    PrismConfig().withEnrich(PrismEnrichConfig(retention: .threeMonths))
)
Prism.startTracking()
```

- Places are built from the locations Prism delivers, so they only grow
  while tracking is running.
- Include the `enrich` block **every time** you call `setConfig` or
  `startTracking(config:)`. A configuration without it turns places off.
- The choice is remembered across launches.

Retention is how much history the result rests on. Older stays are forgotten.

| Retention | Use it when |
|---|---|
| `.oneMonth` | The user's routine changes often, or you want to keep the least |
| `.threeMonths` | Default |
| `.sixMonths` | You want the steadiest result |

Changing retention takes effect straight away; shortening it drops the older
history.

### Read the places

```swift
let places = Prism.places()          // synchronous, any thread, never nil

if let home = places.home {
    print("home near", home.latitude, home.longitude, home.confidence as Any)
}
for place in places.frequent {
    print("frequent:", place.latitude, place.longitude, place.visitCount, "visits")
}
```

Before places are turned on, and until the first stay has been observed,
`home` is nil and `frequent` is empty.

### Follow changes

```swift
Task {
    for await places in Prism.placesUpdates() {
        // the current value first, then each change
    }
}
```

Call it after `initialize`. An update arrives when a place appears or
disappears or when its counts change, not on every location. Results also
refresh when the app returns to the foreground. Cancelling the task stops the
updates.

### Turn it off, delete

```swift
Prism.setConfig(PrismConfig())   // off. What was learned is kept.
Prism.clearPlaces()              // deletes everything. Stays on if it was on.
Prism.reset()                    // deletes and turns off, along with the rest of Prism's state.
```

Give your users a way to reach `clearPlaces()`.

### What you get

`PrismPlaces`:

| Field | Type | Meaning |
|---|---|---|
| `home` | `PrismPlace?` | Where the user spends their nights, or nil |
| `frequent` | `[PrismPlace]` | Other places they return to, most time spent first |
| `computedAtMs` | `Int64` | When this result was computed, epoch milliseconds. 0 before the first computation |
| `retention` | `PrismPlaceRetention` | The retention in force |
| `stayCount` | `Int` | Stays inside the retention window |
| `observedFromMs` | `Int64?` | Earliest stay inside the window. Tells you how much history the result rests on |

`PrismPlace`:

| Field | Type | Meaning |
|---|---|---|
| `kind` | `PrismPlaceKind` | `.home` or `.frequent`. More kinds may be added, so switch with `@unknown default` |
| `latitude`, `longitude` | `Double` | Centre of the stays that make up the place |
| `visitCount` | `Int` | Separate stays observed here |
| `totalDwellMs` | `Int64` | Total time spent here, milliseconds |
| `distinctNights` | `Int` | Distinct nights spent here |
| `firstSeenMs`, `lastSeenMs` | `Int64` | First and latest stay, epoch milliseconds |
| `confidence` | `PrismConfidence?` | Set for home only |

Confidence says how much evidence stands behind the home label. It grows with
the number of distinct nights: `.provisional`, `.low`, `.moderate`, `.high`,
`.confirmed`. A home appears early and starts as `.provisional`; treat the
first two levels as a guess and decide in your app which level is good enough
to show.

### JSON

`PrismPlaces` and `PrismPlace` are `Codable`. The keys are snake_case and
identical to the Android SDK's `toMap()` and to `asDictionary` in Objective-C.

```json
{
  "home": {
    "kind": "HOME", "latitude": 52.2297, "longitude": 21.0122,
    "visit_count": 58, "total_dwell_ms": 2217600000, "distinct_nights": 44,
    "first_seen_ms": 1751328000000, "last_seen_ms": 1758931200000,
    "confidence": "CONFIRMED"
  },
  "frequent": [
    {
      "kind": "FREQUENT", "latitude": 52.2319, "longitude": 20.9841,
      "visit_count": 31, "total_dwell_ms": 892800000, "distinct_nights": 0,
      "first_seen_ms": 1751360400000, "last_seen_ms": 1758880800000
    }
  ],
  "computed_at_ms": 1758931500000,
  "retention": "THREE_MONTHS",
  "stay_count": 164,
  "observed_from_ms": 1751328000000
}
```

`home`, `confidence` and `observed_from_ms` are left out when they have no
value.

### Objective-C

```objc
PrismConfig *config = [PrismConfig new];
config.enrichEnabled = YES;
config.enrichRetention = @"THREE_MONTHS";     // @"ONE_MONTH", @"THREE_MONTHS" or @"SIX_MONTHS"
[Prism setConfig:config];

PrismPlaces *places = [Prism places];         // never nil
if (places.home) {
    NSLog(@"home near %f, %f (%@)", places.home.latitude, places.home.longitude, places.home.confidence);
}

[Prism setPlacesListener:^(PrismPlaces *places) {
    // main thread. The current value first, then each change.
}];
[Prism setPlacesListener:nil];                // stop

[Prism clearPlaces];
```

`kind`, `confidence` and `retention` are strings in Objective-C, with the same
values as the JSON above. An unrecognised `enrichRetention` falls back to
three months.

### Storage and privacy

- Stays and places are kept in the app's private storage, excluded from
  device backups, and removed when the app is uninstalled.
- Nothing is sent over the network. Place inference has no network code.
- The package includes a privacy manifest (`PrivacyInfo.xcprivacy`). It
  declares no tracking and no data collection by the SDK.
- Inferring a home address is sensitive. Ask for consent and disclose it in
  your privacy policy and App Store privacy details. Prism only computes; your
  app decides what to do with the result.

## API summary

Everything is a static call on `Prism`.

| Call | What it does |
|---|---|
| `initialize(apiKey:)` | Set up the SDK. Call first, once per launch |
| `setConfig(_:)` | Apply a `PrismConfig`, including the `enrich` block for places |
| `startTracking()`, `startTracking(config:)` | Start delivering locations |
| `stopTracking()`, `isTracking()` | Stop, and ask whether tracking is running |
| `reset()` | Stop tracking and clear identity, configuration and places |
| `requestLocationPermission`, `requestBackgroundLocationPermission` | Prompt the user. Completion-handler and `async` forms |
| `checkLocationPermission()`, `checkBackgroundLocationPermission()`, `locationPermissionStatus()` | Read permission state without prompting |
| `setLocationDelegate(_:)`, `onLocation(_:)`, `onError(_:)` | Receive locations and errors by delegate or closure |
| `locations()`, `errors()` | The same as `AsyncStream`s |
| `places()` | **New in 0.2.0.** The current home and frequent places |
| `placesUpdates()` | **New in 0.2.0.** Places as an `AsyncStream` |
| `clearPlaces()` | **New in 0.2.0.** Delete every stored stay and place |
| `setUserId(_:)`, `setMetadata(_:)`, `getDeviceId()` | Identify the user and the device |
| `isBackgroundRefreshEnabled()` | Whether Background App Refresh is on |

Objective-C adds `+[Prism setPlacesListener:]` in place of the stream.

### Changed in 0.2.0

`Prism.onLocation` and `Prism.onError` behave as before: one closure each, the
last call wins. They now work alongside a delegate without either replacing
the other, and `reset()` clears them.

## Development

```
make test    # mapping tests on a simulator
make lint    # validate the podspec
```

The tracking engine ships as `Frameworks/LocalSDKCore.xcframework`; refresh it
with `make xcframework ENGINE=/path/to/localsdk-ios-core`. Place inference ships as
`Frameworks/PrismEnrich.xcframework`; refresh it with `make enrich ENRICH=/path/to/prism-enrich-ios`.

## License

MIT. See [LICENSE](LICENSE).
