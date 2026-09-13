import Foundation
import LocalSDKCore
import Testing

@testable import PrismSDK

/// `PrismLocation`, `PrismLocationObjC` and `asDictionary` are three copies of
/// the same 29 fields, written by hand. These tests pin each copy against the
/// engine value it was built from.
@Suite("PrismLocation mapping")
struct PrismLocationMappingTests {

    // MARK: - Swift value

    @Test("every engine field reaches PrismLocation unchanged")
    func swiftMapping() {
        let location = PrismLocation(LocationFixtures.visit)

        #expect(location.id == "loc-0001")
        #expect(location.timestamp == 1_757_000_000_123)
        #expect(location.timezoneOffset == "+02:00")
        #expect(location.latitude == 52.2297)
        #expect(location.longitude == 21.0122)
        #expect(location.altitude == 88.5)
        #expect(location.horizontalAccuracy == 12.25)
        #expect(location.verticalAccuracy == 4.5)
        #expect(location.speed == 3.5)
        #expect(location.bearing == 271.75)
        #expect(location.type == .visit)
        #expect(location.isMock == true)
        #expect(location.arrivalDate == 1_756_999_000_000)
        #expect(location.departureDate == 1_757_000_500_000)
        #expect(location.deviceId == "device-abc")
        #expect(location.userId == "user-xyz")
        #expect(location.metadata == ["plan": "gold", "region": "eu"])
        #expect(location.batteryLevel == 67)
        #expect(location.batteryStatus == "CHARGING")
        #expect(location.networkStatus == true)
        #expect(location.locationPermission == true)
        #expect(location.trackingMode == .efficient)
        #expect(location.brand == "Fruit")
        #expect(location.model == "iPhone16,1")
        #expect(location.os == "iOS")
        #expect(location.osVersion == "18.4")
        #expect(location.sdkVersion == "1.0.0")
        #expect(location.appVersionName == "2.3.4")
        #expect(location.appVersionCode == "567")
    }

    @Test("absent optionals stay absent")
    func swiftMappingOfMovingRow() {
        let location = PrismLocation(LocationFixtures.moving)

        #expect(location.type == .moving)
        #expect(location.arrivalDate == nil)
        #expect(location.departureDate == nil)
        #expect(location.metadata == nil)
        #expect(location.userId == "")
    }

    /// The engine model has 29 stored properties. If it grows, this fails first,
    /// before a field is silently dropped by the copy below.
    @Test("PrismLocation carries exactly the engine's 29 fields")
    func swiftFieldCount() {
        #expect(Mirror(reflecting: LocationFixtures.visit).children.count == 29)
        #expect(Mirror(reflecting: PrismLocation(LocationFixtures.visit)).children.count == 29)
    }

    // MARK: - Objective-C view

    @Test("the Objective-C view carries the same values")
    func objcMapping() {
        let location = PrismLocationObjC(PrismLocation(LocationFixtures.visit))

        #expect(location.identifier == "loc-0001")
        #expect(location.timestamp == 1_757_000_000_123)
        #expect(location.timezoneOffset == "+02:00")
        #expect(location.latitude == 52.2297)
        #expect(location.longitude == 21.0122)
        #expect(location.altitude == 88.5)
        #expect(location.horizontalAccuracy == 12.25)
        #expect(location.verticalAccuracy == 4.5)
        #expect(location.speed == 3.5)
        #expect(location.bearing == 271.75)
        #expect(location.type == "VISIT")
        #expect(location.isMock == true)
        #expect(location.arrivalDate?.int64Value == 1_756_999_000_000)
        #expect(location.departureDate?.int64Value == 1_757_000_500_000)
        #expect(location.deviceIdentifier == "device-abc")
        #expect(location.userIdentifier == "user-xyz")
        #expect(location.metadata == ["plan": "gold", "region": "eu"])
        #expect(location.batteryLevel == 67)
        #expect(location.batteryStatus == "CHARGING")
        #expect(location.networkStatus == true)
        #expect(location.locationPermission == true)
        #expect(location.trackingMode == "EFFICIENT")
        #expect(location.brand == "Fruit")
        #expect(location.model == "iPhone16,1")
        #expect(location.os == "iOS")
        #expect(location.osVersion == "18.4")
        #expect(location.sdkVersion == "1.0.0")
        #expect(location.appVersionName == "2.3.4")
        #expect(location.appVersionCode == "567")
    }

    @Test("the Objective-C view carries exactly 29 fields")
    func objcFieldCount() {
        let location = PrismLocationObjC(PrismLocation(LocationFixtures.visit))
        #expect(Mirror(reflecting: location).children.count == 29)
    }

    // MARK: - Dictionary form

    /// The keys are wire names: a row seen in JavaScript must match the columns
    /// of an exported CSV. They are API, so they are pinned by name.
    @Test("asDictionary uses wire names and carries every field")
    func dictionary() {
        let dictionary = PrismLocationObjC(PrismLocation(LocationFixtures.visit)).asDictionary

        #expect(dictionary.count == 29)
        #expect(dictionary["id"] as? String == "loc-0001")
        #expect(dictionary["timestamp"] as? Int64 == 1_757_000_000_123)
        #expect(dictionary["tz_offset"] as? String == "+02:00")
        #expect(dictionary["latitude"] as? Double == 52.2297)
        #expect(dictionary["longitude"] as? Double == 21.0122)
        #expect(dictionary["altitude"] as? Double == 88.5)
        #expect(dictionary["horizontal_accuracy"] as? Double == 12.25)
        #expect(dictionary["vertical_accuracy"] as? Double == 4.5)
        #expect(dictionary["speed"] as? Double == 3.5)
        #expect(dictionary["bearing"] as? Double == 271.75)
        #expect(dictionary["type"] as? String == "VISIT")
        #expect(dictionary["is_mock"] as? Bool == true)
        #expect((dictionary["arrival_date"] as? NSNumber)?.int64Value == 1_756_999_000_000)
        #expect((dictionary["departure_date"] as? NSNumber)?.int64Value == 1_757_000_500_000)
        #expect(dictionary["device_id"] as? String == "device-abc")
        #expect(dictionary["user_id"] as? String == "user-xyz")
        #expect(dictionary["metadata"] as? [String: String] == ["plan": "gold", "region": "eu"])
        #expect(dictionary["battery_level"] as? Int == 67)
        #expect(dictionary["battery_status"] as? String == "CHARGING")
        #expect(dictionary["network_status"] as? Bool == true)
        #expect(dictionary["location_permission"] as? Bool == true)
        #expect(dictionary["tracking_mode"] as? String == "EFFICIENT")
        #expect(dictionary["brand"] as? String == "Fruit")
        #expect(dictionary["model"] as? String == "iPhone16,1")
        #expect(dictionary["os"] as? String == "iOS")
        #expect(dictionary["os_version"] as? String == "18.4")
        #expect(dictionary["sdk_version"] as? String == "1.0.0")
        #expect(dictionary["app_version_name"] as? String == "2.3.4")
        #expect(dictionary["app_version_code"] as? String == "567")
    }

    @Test("asDictionary omits the keys that do not apply, rather than writing null")
    func dictionaryOmitsAbsentKeys() {
        let dictionary = PrismLocationObjC(PrismLocation(LocationFixtures.moving)).asDictionary

        #expect(dictionary.count == 26)
        #expect(dictionary["arrival_date"] == nil)
        #expect(dictionary["departure_date"] == nil)
        #expect(dictionary["metadata"] == nil)
        #expect(dictionary["type"] as? String == "MOVING")
    }
}
