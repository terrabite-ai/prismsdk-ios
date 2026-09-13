import Foundation

/// A location, for Objective-C callers.
///
/// `PrismLocation` is a Swift `struct`, which does not cross the bridge, so this
/// is a reference-type view of the same values. Conversion happens once, when the
/// SDK hands a location out.
///
/// `arrivalDate` and `departureDate` are `NSNumber *` rather than `int64_t`
/// because they are genuinely absent on non-visit rows, and a primitive has no
/// nil.
@objc(PrismLocation)
public final class PrismLocationObjC: NSObject {

    @objc public let identifier: String

    /// Epoch milliseconds, UTC — when the position was fixed, not when it was
    /// processed.
    @objc public let timestamp: Int64

    /// UTC offset in force at `timestamp`, as `±HH:MM`.
    @objc public let timezoneOffset: String

    @objc public let latitude: Double
    @objc public let longitude: Double
    @objc public let altitude: Double
    @objc public let horizontalAccuracy: Double
    @objc public let verticalAccuracy: Double

    /// Metres per second. `0` means stationary **or** unknown.
    @objc public let speed: Double

    /// Degrees from true north; `0` when unknown.
    @objc public let bearing: Double

    /// `"MOVING"`, `"STATIONARY"` or `"VISIT"`.
    @objc public let type: String

    @objc public let isMock: Bool

    /// Non-nil only on a visit.
    @objc public let arrivalDate: NSNumber?

    /// Non-nil only on a visit, and nil while the stay is in progress.
    @objc public let departureDate: NSNumber?

    @objc public let deviceIdentifier: String
    @objc public let userIdentifier: String
    @objc public let metadata: [String: String]?

    @objc public let batteryLevel: Int
    @objc public let batteryStatus: String
    @objc public let networkStatus: Bool
    @objc public let locationPermission: Bool

    /// `"PRECISE"`, `"STANDARD"` or `"EFFICIENT"`.
    @objc public let trackingMode: String

    @objc public let brand: String
    @objc public let model: String
    @objc public let os: String
    @objc public let osVersion: String
    @objc public let sdkVersion: String
    @objc public let appVersionName: String
    @objc public let appVersionCode: String

    init(_ location: PrismLocation) {
        identifier = location.id
        timestamp = location.timestamp
        timezoneOffset = location.timezoneOffset
        latitude = location.latitude
        longitude = location.longitude
        altitude = location.altitude
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy
        speed = location.speed
        bearing = location.bearing
        type = location.type.rawValue
        isMock = location.isMock
        arrivalDate = location.arrivalDate.map(NSNumber.init(value:))
        departureDate = location.departureDate.map(NSNumber.init(value:))
        deviceIdentifier = location.deviceId
        userIdentifier = location.userId
        metadata = location.metadata
        batteryLevel = location.batteryLevel
        batteryStatus = location.batteryStatus
        networkStatus = location.networkStatus
        locationPermission = location.locationPermission
        trackingMode = location.trackingMode.rawValue
        brand = location.brand
        model = location.model
        os = location.os
        osVersion = location.osVersion
        sdkVersion = location.sdkVersion
        appVersionName = location.appVersionName
        appVersionCode = location.appVersionCode
        super.init()
    }

    /// This location as Foundation types only.
    ///
    /// For hosts that cannot see Objective-C properties — React Native's bridge
    /// marshals `NSString`, `NSNumber`, `NSDictionary`, `NSArray` and `BOOL` and
    /// nothing else, so a `PrismLocationObjC` would otherwise reach JavaScript as an
    /// opaque handle.
    ///
    /// Keys are snake_case wire names, so a row seen in JavaScript matches the
    /// columns of an exported CSV. `arrival_date`, `departure_date` and `metadata`
    /// are absent rather than null when they do not apply.
    @objc public var asDictionary: [String: Any] {
        var dictionary: [String: Any] = [
            "id": identifier,
            "timestamp": timestamp,
            "tz_offset": timezoneOffset,
            "latitude": latitude,
            "longitude": longitude,
            "altitude": altitude,
            "horizontal_accuracy": horizontalAccuracy,
            "vertical_accuracy": verticalAccuracy,
            "speed": speed,
            "bearing": bearing,
            "type": type,
            "is_mock": isMock,
            "device_id": deviceIdentifier,
            "user_id": userIdentifier,
            "battery_level": batteryLevel,
            "battery_status": batteryStatus,
            "network_status": networkStatus,
            "location_permission": locationPermission,
            "tracking_mode": trackingMode,
            "brand": brand,
            "model": model,
            "os": os,
            "os_version": osVersion,
            "sdk_version": sdkVersion,
            "app_version_name": appVersionName,
            "app_version_code": appVersionCode
        ]
        if let arrivalDate { dictionary["arrival_date"] = arrivalDate }
        if let departureDate { dictionary["departure_date"] = departureDate }
        if let metadata { dictionary["metadata"] = metadata }
        return dictionary
    }
}
