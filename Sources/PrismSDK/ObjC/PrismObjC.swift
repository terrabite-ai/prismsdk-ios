import Foundation

/// Receives locations, for Objective-C callers.
///
/// Class-bound so an Objective-C class can adopt it. Held weakly, as the Swift
/// delegate is — keep your own strong reference.
@objc(PrismLocationDelegate)
public protocol PrismLocationDelegateObjC: AnyObject {
    @objc func locationDidUpdate(_ location: PrismLocationObjC)
    @objc func locationDidFail(_ error: String)
}

/// Configuration, for Objective-C callers.
///
/// A mutable class rather than the Swift `struct`: `PrismConfig`'s builders return
/// a value, which is not a shape Objective-C can use.
@objc(PrismConfig)
public final class PrismConfigObjC: NSObject {

    /// `"PRECISE"`, `"STANDARD"` or `"EFFICIENT"`. An unrecognised value leaves the
    /// mode unchanged rather than throwing — Objective-C has no typed enum to
    /// constrain it, and a typo should not be a crash at configuration time.
    @objc public var trackingMode: String = "PRECISE"
    @objc public var allowMockLocation: Bool = false
    @objc public var horizontalAccuracyThreshold: Double = 200
    @objc public var backgroundLocationEnabled: Bool = true

    @objc public override init() { super.init() }

    var config: PrismConfig {
        PrismConfig(
            trackingMode: PrismTrackingMode(rawValue: trackingMode) ?? .precise,
            allowMockLocation: allowMockLocation,
            horizontalAccuracyThreshold: horizontalAccuracyThreshold,
            backgroundLocationEnabled: backgroundLocationEnabled
        )
    }
}

/// Prism SDK, for Objective-C callers.
///
/// `Prism` is a Swift `enum`, invisible to Objective-C, so this is a class facade
/// over it. It adds no behaviour — every method forwards.
///
/// Two things are absent because they cannot be represented, not because they
/// were forgotten: `locations()` and `errors()` return `AsyncStream`, which has no
/// Objective-C form — use the delegate; and `onLocation:`/`onError:` are closure
/// registration, which the delegate already covers.
/// Exposed to Objective-C as `Prism`, matching the Swift entry point and the
/// brand — `[Prism startTracking]`. Unprefixed on purpose: Objective-C has no
/// namespaces, so the name is the whole identity, and `PrismObjC` would have read
/// as an abbreviation of something rather than as the product. The value types
/// keep the `PRSM` prefix because `PrismLocation` and `PrismConfig` are already
/// taken by the Swift types in this module.
@objc(Prism)
public final class PrismObjC: NSObject {

    /// Not instantiable — every member is a class method, mirroring the Swift
    /// enum's static shape.
    @available(*, unavailable)
    override init() { fatalError("Prism is not instantiable") }

    // MARK: - Lifecycle

    @objc public static func initialize(apiKey: String) {
        Prism.initialize(apiKey: apiKey)
    }

    @objc public static func setConfig(_ config: PrismConfigObjC) {
        Prism.setConfig(config.config)
    }

    @objc public static func startTracking() {
        Prism.startTracking()
    }

    /// Apply a configuration and start tracking, in one call —
    /// `[Prism startTrackingWithConfig:config]`.
    ///
    /// See the Swift `startTracking(config:)` for the one caveat: a session resumed
    /// by `initialize` carries last launch's configuration until you replace it.
    @objc public static func startTracking(config: PrismConfigObjC) {
        Prism.startTracking(config: config.config)
    }

    @objc public static func stopTracking() {
        Prism.stopTracking()
    }

    @objc public static var isTracking: Bool {
        Prism.isTracking()
    }

    @objc public static func reset() {
        Prism.reset()
        // `Prism.reset()` drops its own adapter; this one is ours to drop.
        adapter.set(nil)
    }

    // MARK: - Permissions

    @objc public static func checkLocationPermission() -> Bool {
        Prism.checkLocationPermission()
    }

    @objc public static func checkBackgroundLocationPermission() -> Bool {
        Prism.checkBackgroundLocationPermission()
    }

    /// One of `"notDetermined"`, `"denied"`, `"restricted"`, `"whenInUse"` or
    /// `"always"`.
    ///
    /// The two `check…` methods answer "can I track?"; this answers "why not, and
    /// what should I show the user?" — a `BOOL` collapses *not asked yet*,
    /// *declined* and *blocked by policy*, which need three different responses.
    ///
    /// `@MainActor`. Objective-C does not enforce that, so a bridged host calling
    /// from a background queue must hop to main first.
    @MainActor
    @objc public static var locationPermissionStatus: String {
        Prism.locationPermissionStatus().bridgedName
    }

    /// Whether full-accuracy location is available. `false` for Approximate
    /// Location and also when nothing is granted, so read it with
    /// `locationPermissionStatus` rather than alone.
    @MainActor
    @objc public static var hasPreciseLocation: Bool {
        Prism.locationPermissionStatus().isPrecise
    }

    /// Presents a system prompt, so it must run on the main thread.
    @MainActor
    @objc public static func requestLocationPermission(completion: ((Bool) -> Void)?) {
        Prism.requestLocationPermission(completion: completion)
    }

    @MainActor
    @objc public static func requestBackgroundLocationPermission(completion: ((Bool) -> Void)?) {
        Prism.requestBackgroundLocationPermission(completion: completion)
    }

    // MARK: - Identity

    @objc public static func deviceIdentifier() -> String {
        Prism.getDeviceId()
    }

    @objc public static func setUserIdentifier(_ userId: String) {
        Prism.setUserId(userId)
    }

    @objc public static func setMetadata(_ metadata: [String: String]) {
        Prism.setMetadata(metadata)
    }

    // MARK: - System information

    @objc public static func isBackgroundRefreshEnabled() -> Bool {
        Prism.isBackgroundRefreshEnabled()
    }

    // MARK: - Delegate

    /// Set the receiver for locations and errors. Pass `nil` to clear.
    ///
    /// The Objective-C delegate is retained by an adapter held here, because the
    /// Swift delegate is weak and the adapter would otherwise be deallocated the
    /// moment this returned. Your object is still held weakly by that adapter, so
    /// setting a delegate does not create a retain cycle.
    /// `@MainActor`, as the Swift API is. Objective-C does not enforce that, so
    /// a bridged host must call this from the main thread.
    @MainActor
    @objc public static func setLocationDelegate(_ delegate: PrismLocationDelegateObjC?) {
        guard let delegate else {
            adapter.set(nil)
            Prism.clearLocationDelegate()
            return
        }
        let bridge = ObjCDelegateAdapter(delegate)
        adapter.set(bridge)
        Prism.setLocationDelegate(bridge)
    }

    /// Lock-guarded for the same reason as `Prism.adapter`.
    private static let adapter = Retained<ObjCDelegateAdapter>()
}

/// Forwards Prism's Swift delegate to an Objective-C one, converting on the way.
private final class ObjCDelegateAdapter: PrismLocationDelegate {

    private weak var target: PrismLocationDelegateObjC?

    init(_ target: PrismLocationDelegateObjC) {
        self.target = target
    }

    func locationDidUpdate(_ location: PrismLocation) {
        target?.locationDidUpdate(PrismLocationObjC(location))
    }

    func locationDidFail(_ error: String) {
        target?.locationDidFail(error)
    }
}
