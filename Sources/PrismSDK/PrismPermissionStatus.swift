import Foundation
import LocalSDKCore

/// What the user has granted.
///
/// Finer-grained than a `Bool`, because the three ungranted states need different
/// responses: *not asked yet* means show your primer, *denied* means deep-link to
/// Settings, and *restricted* means the choice is not the user's to make and no
/// amount of asking will change it.
public enum PrismPermissionStatus: Equatable, Sendable {

    /// Not yet asked, or the system has not resolved the request.
    case notDetermined

    /// The user declined.
    case denied

    /// Blocked by parental controls, MDM or another policy. Cannot be granted from
    /// inside the app.
    case restricted

    /// Granted while the app is in the foreground. `precise` is `false` when the
    /// user chose Approximate Location.
    case authorizedWhenInUse(precise: Bool)

    /// Granted in the foreground and the background. `precise` as above.
    case authorizedAlways(precise: Bool)

    /// Granted at any level.
    public var isGranted: Bool {
        switch self {
        case .authorizedWhenInUse, .authorizedAlways: return true
        case .notDetermined, .denied, .restricted: return false
        }
    }

    /// Granted for background use specifically.
    public var isBackgroundGranted: Bool {
        if case .authorizedAlways = self { return true }
        return false
    }

    /// Full-accuracy location is available. `false` both for Approximate Location
    /// and when nothing is granted, so read it alongside the case rather than
    /// alone.
    public var isPrecise: Bool {
        switch self {
        case .authorizedWhenInUse(let precise), .authorizedAlways(let precise):
            return precise
        case .notDetermined, .denied, .restricted:
            return false
        }
    }

    init(_ status: PermissionStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        case .authorizedWhenInUse(let precise):
            self = .authorizedWhenInUse(precise: precise)
        case .authorizedAlways(let precise):
            self = .authorizedAlways(precise: precise)
        @unknown default:
            // The engine ships as a binary built with library evolution, so its
            // enum is not frozen and a newer engine can add a case this build
            // has never seen. Treat it as ungranted — the engine makes the same
            // choice for an unknown CoreLocation status — so nothing starts
            // tracking on the strength of a state it cannot interpret.
            self = .denied
        }
    }

    /// The case name, for hosts with no Swift enums — the Objective-C facade, and
    /// through it React Native and anything else bridged.
    ///
    /// **These strings are API.** Bridged callers branch on them, so they may be
    /// added to but not renamed. Precision is deliberately absent:
    /// `authorizedWhenInUse(precise: false)` is still `"whenInUse"`, and accuracy
    /// is reported separately, so a consumer never has to parse one value to
    /// recover two facts.
    var bridgedName: String {
        switch self {
        case .notDetermined:       return "notDetermined"
        case .denied:              return "denied"
        case .restricted:          return "restricted"
        case .authorizedWhenInUse: return "whenInUse"
        case .authorizedAlways:    return "always"
        }
    }
}
