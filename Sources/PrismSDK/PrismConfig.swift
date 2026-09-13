import Foundation
import LocalSDKCore

/// How aggressively to track.
///
/// The mode controls *how often* a fix reaches you;
/// `PrismConfig.withHorizontalAccuracyThreshold(_:)` controls *how good* it has to
/// be. They are independent — a precise mode still discards inaccurate fixes.
public enum PrismTrackingMode: String, Codable, Sendable {

    /// Tightest distance filter, most frequent updates, highest battery cost.
    case precise = "PRECISE"

    /// Balanced. The usual choice.
    case standard = "STANDARD"

    /// Widest filter, fewest updates, lowest battery cost.
    case efficient = "EFFICIENT"

    init(_ mode: TrackingMode) {
        self = PrismTrackingMode(rawValue: mode.rawValue) ?? .standard
    }

    var core: TrackingMode {
        TrackingMode(rawValue: rawValue) ?? .standard
    }
}

/// Tracking configuration.
///
/// A value type with chainable setters, so a configuration reads as one
/// expression and nothing half-applied can be observed:
///
/// ```swift
/// Prism.setConfig(
///     PrismConfig()
///         .withTrackingMode(.standard)
///         .withHorizontalAccuracyThreshold(50)
/// )
/// ```
public struct PrismConfig: Equatable, Sendable {

    /// Default `.precise`.
    public var trackingMode: PrismTrackingMode = .precise

    /// Whether simulated locations are accepted. Default `false`, so they are
    /// discarded.
    public var allowMockLocation: Bool = false

    /// Fixes with a worse radius of uncertainty, in metres, are discarded.
    /// Default `200`.
    public var horizontalAccuracyThreshold: Double = 200

    /// Whether to keep tracking once the app leaves the foreground. Default
    /// `true` — but this only expresses intent. Delivery also needs the
    /// *Location updates* background mode and an "Always" grant.
    public var backgroundLocationEnabled: Bool = true

    public init() {}

    public init(
        trackingMode: PrismTrackingMode = .precise,
        allowMockLocation: Bool = false,
        horizontalAccuracyThreshold: Double = 200,
        backgroundLocationEnabled: Bool = true
    ) {
        self.trackingMode = trackingMode
        self.allowMockLocation = allowMockLocation
        self.horizontalAccuracyThreshold = horizontalAccuracyThreshold
        self.backgroundLocationEnabled = backgroundLocationEnabled
    }

    // MARK: - Builders

    public func withTrackingMode(_ mode: PrismTrackingMode) -> PrismConfig {
        var copy = self
        copy.trackingMode = mode
        return copy
    }

    public func withAllowMockLocation(_ allow: Bool) -> PrismConfig {
        var copy = self
        copy.allowMockLocation = allow
        return copy
    }

    public func withHorizontalAccuracyThreshold(_ metres: Double) -> PrismConfig {
        var copy = self
        copy.horizontalAccuracyThreshold = metres
        return copy
    }

    public func withBackgroundLocationEnabled(_ enabled: Bool) -> PrismConfig {
        var copy = self
        copy.backgroundLocationEnabled = enabled
        return copy
    }

    // MARK: - Mapping

    var core: Config {
        Config(
            trackingMode: trackingMode.core,
            allowMockLocation: allowMockLocation,
            horizontalAccuracyThreshold: horizontalAccuracyThreshold,
            backgroundLocationEnabled: backgroundLocationEnabled
        )
    }
}
