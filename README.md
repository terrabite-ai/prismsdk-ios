# Prism SDK for iOS

Background location tracking for iOS apps. Add Prism, ask for permission once,
and receive your users' locations in the foreground and the background, with
the battery cost you choose.

Requires iOS 15 or later. Swift and Objective-C.

## Install

**Swift Package Manager.** In Xcode, File → Add Package Dependencies, and enter:

```
https://github.com/terrabite-ai/prismsdk-ios
```

Or in `Package.swift`:

```swift
.package(url: "https://github.com/terrabite-ai/prismsdk-ios", branch: "main")
```

Add the `PrismSDK` product to your target.

**CocoaPods.**

```ruby
pod 'PrismSDK', :git => 'https://github.com/terrabite-ai/prismsdk-ios.git', :tag => '0.1.0'
```

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

## Development

```
make test    # mapping tests on a simulator
make lint    # validate the podspec
```

The tracking engine ships as `Frameworks/LocalSDKCore.xcframework`. Refresh it
with `make xcframework ENGINE=/path/to/localsdk-ios-core`.

## License

MIT. See [LICENSE](LICENSE).
