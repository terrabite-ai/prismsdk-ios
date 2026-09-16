import Foundation

/// A place, for Objective-C callers. Reference-type view of `PrismPlace`.
@objc(PrismPlace)
public final class PrismPlaceObjC: NSObject {
    /// `"HOME"` or `"FREQUENT"`.
    @objc public let kind: String
    @objc public let latitude: Double
    @objc public let longitude: Double
    @objc public let visitCount: Int
    @objc public let totalDwellMs: Int64
    @objc public let distinctNights: Int
    @objc public let firstSeenMs: Int64
    @objc public let lastSeenMs: Int64
    /// `"PROVISIONAL"`, `"LOW"`, `"MODERATE"`, `"HIGH"`, `"CONFIRMED"`, or nil for non-home places.
    @objc public let confidence: String?

    init(_ p: PrismPlace) {
        kind = p.kind.rawValue
        latitude = p.latitude
        longitude = p.longitude
        visitCount = p.visitCount
        totalDwellMs = p.totalDwellMs
        distinctNights = p.distinctNights
        firstSeenMs = p.firstSeenMs
        lastSeenMs = p.lastSeenMs
        confidence = p.confidence?.rawValue
        super.init()
    }

    /// Foundation types only, snake_case keys, for bridged hosts.
    @objc public var asDictionary: [String: Any] {
        var d: [String: Any] = [
            "kind": kind, "latitude": latitude, "longitude": longitude, "visit_count": visitCount,
            "total_dwell_ms": totalDwellMs, "distinct_nights": distinctNights, "first_seen_ms": firstSeenMs, "last_seen_ms": lastSeenMs,
        ]
        if let confidence { d["confidence"] = confidence }
        return d
    }
}

/// The current inference, for Objective-C callers.
@objc(PrismPlaces)
public final class PrismPlacesObjC: NSObject {
    @objc public let home: PrismPlaceObjC?
    @objc public let frequent: [PrismPlaceObjC]
    @objc public let computedAtMs: Int64
    /// `"ONE_MONTH"`, `"THREE_MONTHS"` or `"SIX_MONTHS"`.
    @objc public let retention: String
    @objc public let stayCount: Int
    @objc public let observedFromMs: NSNumber?

    init(_ p: PrismPlaces) {
        home = p.home.map(PrismPlaceObjC.init)
        frequent = p.frequent.map(PrismPlaceObjC.init)
        computedAtMs = p.computedAtMs
        retention = p.retention.rawValue
        stayCount = p.stayCount
        observedFromMs = p.observedFromMs.map(NSNumber.init(value:))
        super.init()
    }

    @objc public var asDictionary: [String: Any] {
        var d: [String: Any] = [
            "frequent": frequent.map(\.asDictionary), "computed_at_ms": computedAtMs, "retention": retention, "stay_count": stayCount,
        ]
        if let home { d["home"] = home.asDictionary }
        if let observedFromMs { d["observed_from_ms"] = observedFromMs }
        return d
    }
}
