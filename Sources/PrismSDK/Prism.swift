import Foundation
import LocalSDKCore

/// Prism SDK — background location tracking for iOS.
///
/// ```swift
/// import PrismSDK
///
/// Prism.initialize(apiKey: "your-sdk-key")
/// Prism.setLocationDelegate(self)
/// Prism.requestLocationPermission { granted in
///     if granted { Prism.startTracking() }
/// }
/// ```
///
/// Every value crossing this API is Prism's own — `PrismLocation`,
/// `PrismConfig`, `PrismPermissionStatus`. The tracking engine underneath is a
/// separate module, and nothing here exposes it.
public enum Prism {

    // MARK: - Lifecycle

    /// Start the SDK. Required before anything else; every other call is a no-op
    /// until this has run.
    ///
    /// If tracking was on when the app was last terminated, this resumes it —
    /// so locations can arrive before you call `startTracking()`. Set your
    /// delegate first if you do not want to miss them.
    public static func initialize(apiKey: String) {
        LocalSDK.initialize(apiKey: apiKey)
    }

    /// Apply a configuration. Optional; the defaults are sensible.
    public static func setConfig(_ config: PrismConfig) {
        LocalSDK.setConfig(config.core)
    }

    public static func startTracking() {
        LocalSDK.startTracking()
    }

    /// Apply a configuration and start tracking, in one call.
    ///
    /// Exactly `setConfig(_:)` followed by `startTracking()` — a convenience for
    /// the common case, not a different code path.
    ///
    /// One caveat worth knowing: `initialize(apiKey:)` resumes tracking on its own
    /// if it was running when the app was last terminated, and that resumed session
    /// starts with the configuration from **last** launch. If your configuration
    /// can change between launches, apply it with `setConfig(_:)` straight after
    /// `initialize(apiKey:)` rather than waiting until you start.
    public static func startTracking(config: PrismConfig) {
        setConfig(config)
        startTracking()
    }

    public static func stopTracking() {
        LocalSDK.stopTracking()
    }

    public static func isTracking() -> Bool {
        LocalSDK.isTracking()
    }

    /// Stop tracking and clear identity and configuration. Call
    /// `initialize(apiKey:)` again before anything else afterwards.
    public static func reset() {
        LocalSDK.reset()
        setLocationDelegate(nil)
    }

    // MARK: - Permissions

    /// Whether foreground location is granted, without prompting.
    public static func checkLocationPermission() -> Bool {
        LocalSDK.checkLocationPermission()
    }

    /// Whether background ("Always") location is granted, without prompting.
    public static func checkBackgroundLocationPermission() -> Bool {
        LocalSDK.checkBackgroundLocationPermission()
    }

    /// The current state in full, without prompting.
    @MainActor
    public static func locationPermissionStatus() -> PrismPermissionStatus {
        PrismPermissionStatus(LocalSDK.locationPermissionStatus())
    }

    /// Ask for foreground location. Presents a system prompt, so call it on the
    /// main thread.
    @MainActor
    public static func requestLocationPermission(completion: ((Bool) -> Void)? = nil) {
        LocalSDK.requestLocationPermission(completion: completion)
    }

    /// Ask to extend the grant to the background.
    ///
    /// iOS never grants "Always" directly — it grants when-in-use first and offers
    /// the upgrade later, sometimes days later. Ask for foreground first.
    @MainActor
    public static func requestBackgroundLocationPermission(completion: ((Bool) -> Void)? = nil) {
        LocalSDK.requestBackgroundLocationPermission(completion: completion)
    }

    /// Ask for foreground location, returning the full resulting state.
    @MainActor
    public static func requestLocationPermission() async -> PrismPermissionStatus {
        PrismPermissionStatus(await LocalSDK.requestLocationPermission())
    }

    /// Ask for background location, returning the full resulting state.
    @MainActor
    public static func requestBackgroundLocationPermission() async -> PrismPermissionStatus {
        PrismPermissionStatus(await LocalSDK.requestBackgroundLocationPermission())
    }

    // MARK: - Receiving locations

    /// Set the receiver for locations and errors. Pass `nil` to clear.
    ///
    /// Held weakly — keep your own strong reference.
    public static func setLocationDelegate(_ delegate: PrismLocationDelegate?) {
        guard let delegate else {
            adapter.set(nil)
            LocalSDK.setLocationDelegate(nil)
            return
        }
        // Retained here because the engine holds its delegate weakly; without this
        // the adapter would be deallocated before the first location arrived.
        let bridge = PrismDelegateAdapter(delegate)
        adapter.set(bridge)
        LocalSDK.setLocationDelegate(bridge)
    }

    /// Receive locations through a closure. Additive — it does not replace a
    /// delegate.
    public static func onLocation(_ listener: @escaping (PrismLocation) -> Void) {
        LocalSDK.onLocation { listener(PrismLocation($0)) }
    }

    /// Receive errors through a closure.
    public static func onError(_ listener: @escaping (String) -> Void) {
        LocalSDK.onError(listener)
    }

    /// Locations as an async sequence.
    ///
    /// Each call returns an independent stream buffering only the newest value, so
    /// a slow consumer drops older fixes rather than growing a queue. The mapping
    /// runs in a task that finishes when the underlying stream does.
    public static func locations() -> AsyncStream<PrismLocation> {
        // `.bufferingNewest(1)` is what makes the doc above true. The default
        // policy is `.unbounded`, and the mapping task below drains the engine's
        // (already bounded) stream eagerly, so an unbounded outer buffer would
        // grow for as long as tracking ran and the consumer did not keep up.
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let task = Task {
                for await location in LocalSDK.locations() {
                    continuation.yield(PrismLocation(location))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Errors as an async sequence.
    public static func errors() -> AsyncStream<String> {
        LocalSDK.errors()
    }

    // MARK: - Identity and context

    /// The SDK's own identifier for this install.
    public static func getDeviceId() -> String {
        LocalSDK.getDeviceId()
    }

    /// Attach your own user identifier to every subsequent location.
    public static func setUserId(_ userId: String) {
        LocalSDK.setUserId(userId)
    }

    /// Attach arbitrary key-value context to every subsequent location.
    public static func setMetadata(_ metadata: [String: String]) {
        LocalSDK.setMetadata(metadata)
    }

    // MARK: - System information

    /// Whether Background App Refresh is enabled — a battery-optimisation
    /// indicator, not a permission.
    public static func isBackgroundRefreshEnabled() -> Bool {
        LocalSDK.isBackgroundRefreshEnabled()
    }

    // MARK: - Internals

    /// Keeps the delegate adapter alive; see `setLocationDelegate(_:)`.
    ///
    /// A lock-guarded box rather than a bare `static var`. A mutable static is
    /// shared mutable state with no isolation: the Swift 6 language mode rejects
    /// it outright, and two threads setting a delegate at once could race on it.
    /// The box is a `let` of a `Sendable` type, so it is accepted in both modes.
    private static let adapter = Retained<PrismDelegateAdapter>()
}
