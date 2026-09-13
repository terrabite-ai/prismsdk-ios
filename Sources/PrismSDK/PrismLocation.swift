import Foundation
import LocalSDKCore

/// How a location was produced.
public enum PrismLocationType: String, Codable, Sendable {

    /// The device was moving when the fix was taken.
    case moving = "MOVING"

    /// The device was stationary, or its speed could not be determined.
    case stationary = "STATIONARY"

    /// A stay at a place, reported by the platform's visit detection. Carries
    /// `arrivalDate` and, once the stay ends, `departureDate`.
    case visit = "VISIT"

    init(_ type: LocationType) {
        // Falls back rather than trapping: a location that arrives with a type
        // this build does not know is still a usable location.
        self = PrismLocationType(rawValue: type.rawValue) ?? .moving
    }
}

/// A single location produced by the SDK.
///
/// Delivered through `PrismLocationDelegate`, `Prism.onLocation(_:)` or
/// `Prism.locations()`. Values only — construct nothing; the SDK produces these.
public struct PrismLocation: Codable, Equatable, Sendable {

    // MARK: - Identity and time

    /// Unique identifier for this location.
    public let id: String

    /// Epoch milliseconds, UTC — the instant the position was **fixed**, not the
    /// instant the SDK processed it.
    public let timestamp: Int64

    /// UTC offset in force at `timestamp`, as `±HH:MM`. Resolved against the fix's
    /// own instant, so a fix taken either side of a daylight-saving change carries
    /// the offset that applied when it was taken.
    public let timezoneOffset: String

    // MARK: - Position

    public let latitude: Double
    public let longitude: Double
    public let altitude: Double

    /// Radius of uncertainty in metres. Compare against the threshold you set with
    /// `PrismConfig.withHorizontalAccuracyThreshold(_:)`.
    public let horizontalAccuracy: Double
    public let verticalAccuracy: Double

    /// Metres per second. **`0` means either stationary or unknown** — iOS reports
    /// an unknown speed as negative and the SDK normalises it, so zero is not
    /// evidence of standing still.
    public let speed: Double

    /// Degrees clockwise from true north. `0` when the course is unknown, which is
    /// common at walking pace.
    public let bearing: Double

    public let type: PrismLocationType

    /// `true` when the platform reported the location as simulated. Whether these
    /// reach you at all depends on `PrismConfig.withAllowMockLocation(_:)`.
    public let isMock: Bool

    // MARK: - Visits

    /// When the stay began, in epoch milliseconds. Non-nil only for `.visit`.
    public let arrivalDate: Int64?

    /// When the stay ended, in epoch milliseconds. Non-nil only for `.visit`, and
    /// `nil` while the stay is still in progress.
    public let departureDate: Int64?

    // MARK: - Identity you set

    /// The SDK's own identifier for this install.
    public let deviceId: String

    /// Whatever you last passed to `Prism.setUserId(_:)`; empty if you have not.
    public let userId: String

    /// Whatever you last passed to `Prism.setMetadata(_:)`.
    public let metadata: [String: String]?

    // MARK: - Device and app state when the fix was taken

    public let batteryLevel: Int
    public let batteryStatus: String
    public let networkStatus: Bool
    public let locationPermission: Bool
    public let trackingMode: PrismTrackingMode
    public let brand: String
    public let model: String
    public let os: String
    public let osVersion: String
    public let sdkVersion: String
    public let appVersionName: String
    public let appVersionCode: String

    // MARK: - Mapping

    /// Maps the engine's model onto Prism's.
    ///
    /// `internal`, and the only place the two models meet. Everything Prism exposes
    /// is declared here, so the engine's type never appears in Prism's public API.
    init(_ location: Location) {
        id = location.id
        timestamp = location.timestamp
        timezoneOffset = location.timezoneOffset

        latitude = location.latitude
        longitude = location.longitude
        altitude = location.altitude
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy
        speed = location.speed
        bearing = location.bearing
        type = PrismLocationType(location.type)
        isMock = location.isMock

        arrivalDate = location.arrivalDate
        departureDate = location.departureDate

        deviceId = location.deviceId
        userId = location.userId
        metadata = location.metadata

        batteryLevel = location.batteryLevel
        batteryStatus = location.batteryStatus
        networkStatus = location.networkStatus
        locationPermission = location.locationPermission
        trackingMode = PrismTrackingMode(location.trackingMode)
        brand = location.brand
        model = location.model
        os = location.os
        osVersion = location.osVersion
        sdkVersion = location.sdkVersion
        appVersionName = location.appVersionName
        appVersionCode = location.appVersionCode
    }
}
