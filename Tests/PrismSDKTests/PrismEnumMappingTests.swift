import LocalSDKCore
import Testing

@testable import PrismSDK

/// The three enums Prism mirrors, case by case and in both directions where
/// both directions exist.
@Suite("Enum mapping")
struct PrismEnumMappingTests {

    // MARK: - Tracking mode

    static let trackingModes: [(TrackingMode, PrismTrackingMode)] = [
        (.precise, .precise),
        (.standard, .standard),
        (.efficient, .efficient),
    ]

    @Test("tracking mode maps engine → Prism", arguments: trackingModes)
    func trackingModeIn(engine: TrackingMode, prism: PrismTrackingMode) {
        #expect(PrismTrackingMode(engine) == prism)
    }

    @Test("tracking mode maps Prism → engine", arguments: trackingModes)
    func trackingModeOut(engine: TrackingMode, prism: PrismTrackingMode) {
        #expect(prism.core == engine)
    }

    /// The raw strings cross into Objective-C and out through `asDictionary`,
    /// so they are API.
    @Test("tracking mode raw values are the engine's", arguments: trackingModes)
    func trackingModeRawValue(engine: TrackingMode, prism: PrismTrackingMode) {
        #expect(prism.rawValue == engine.rawValue)
    }

    // MARK: - Location type

    static let locationTypes: [(LocationType, PrismLocationType)] = [
        (.moving, .moving),
        (.stationary, .stationary),
        (.visit, .visit),
    ]

    @Test("location type maps engine → Prism", arguments: locationTypes)
    func locationType(engine: LocationType, prism: PrismLocationType) {
        #expect(PrismLocationType(engine) == prism)
        #expect(prism.rawValue == engine.rawValue)
    }

    // MARK: - Permission status

    static let permissionStatuses: [(PermissionStatus, PrismPermissionStatus, String)] = [
        (.notDetermined, .notDetermined, "notDetermined"),
        (.denied, .denied, "denied"),
        (.restricted, .restricted, "restricted"),
        (.authorizedWhenInUse(precise: true), .authorizedWhenInUse(precise: true), "whenInUse"),
        (.authorizedWhenInUse(precise: false), .authorizedWhenInUse(precise: false), "whenInUse"),
        (.authorizedAlways(precise: true), .authorizedAlways(precise: true), "always"),
        (.authorizedAlways(precise: false), .authorizedAlways(precise: false), "always"),
    ]

    @Test("permission status maps case for case", arguments: permissionStatuses)
    func permissionStatus(engine: PermissionStatus, prism: PrismPermissionStatus, name: String) {
        let mapped = PrismPermissionStatus(engine)

        #expect(mapped == prism)
        #expect(mapped.isGranted == engine.isGranted)
        #expect(mapped.isBackgroundGranted == engine.isBackgroundGranted)
        #expect(mapped.isPrecise == engine.isPrecise)
    }

    /// Bridged callers branch on these strings. Renaming one compiles cleanly
    /// and breaks every Objective-C and React Native integrator at runtime.
    @Test("bridged names are pinned", arguments: permissionStatuses)
    func bridgedName(engine: PermissionStatus, prism: PrismPermissionStatus, name: String) {
        #expect(prism.bridgedName == name)
    }

    @Test("precision never leaks into the bridged name")
    func bridgedNameIgnoresPrecision() {
        #expect(
            PrismPermissionStatus.authorizedWhenInUse(precise: true).bridgedName
                == PrismPermissionStatus.authorizedWhenInUse(precise: false).bridgedName
        )
        #expect(
            PrismPermissionStatus.authorizedAlways(precise: true).bridgedName
                == PrismPermissionStatus.authorizedAlways(precise: false).bridgedName
        )
    }

    @Test("the three ungranted states stay distinguishable")
    func ungrantedStatesAreDistinct() {
        let ungranted: [PrismPermissionStatus] = [.notDetermined, .denied, .restricted]

        for status in ungranted {
            #expect(status.isGranted == false)
            #expect(status.isBackgroundGranted == false)
            #expect(status.isPrecise == false)
        }
        #expect(Set(ungranted.map(\.bridgedName)).count == 3)
    }
}
