import LocalSDKCore

/// Engine values the mapping tests start from.
///
/// Every field is set to something that cannot be confused with any other field
/// or with that field's default, so a mapping that copies the wrong field, or
/// forgets one, changes an expected value rather than passing by coincidence.
enum LocationFixtures {

    /// A visit row: every optional populated.
    static let visit = Location(
        id: "loc-0001",
        timestamp: 1_757_000_000_123,
        isMock: true,
        speed: 3.5,
        horizontalAccuracy: 12.25,
        altitude: 88.5,
        bearing: 271.75,
        latitude: 52.2297,
        longitude: 21.0122,
        type: .visit,
        batteryLevel: 67,
        deviceId: "device-abc",
        userId: "user-xyz",
        timezoneOffset: "+02:00",
        verticalAccuracy: 4.5,
        networkStatus: true,
        trackingMode: .efficient,
        batteryStatus: "CHARGING",
        locationPermission: true,
        brand: "Fruit",
        model: "iPhone16,1",
        os: "iOS",
        osVersion: "18.4",
        sdkVersion: "1.0.0",
        appVersionName: "2.3.4",
        appVersionCode: "567",
        metadata: ["plan": "gold", "region": "eu"],
        arrivalDate: 1_756_999_000_000,
        departureDate: 1_757_000_500_000
    )

    /// A moving row with nothing optional set: no visit dates, no metadata.
    static let moving = Location(
        id: "loc-0002",
        timestamp: 1_757_000_100_000,
        latitude: 48.8566,
        longitude: 2.3522,
        type: .moving,
        batteryLevel: 12,
        deviceId: "device-def",
        timezoneOffset: "-05:00"
    )
}
