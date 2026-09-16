import Foundation
import PrismEnrich

/// What a place is to the user. More kinds may be added; switch with `@unknown default`.
public enum PrismPlaceKind: String, Codable, Sendable {
    case home = "HOME"
    case frequent = "FREQUENT"

    init(_ kind: EnrichPlaceKind) {
        switch kind {
        case .home: self = .home
        case .frequent: self = .frequent
        @unknown default: self = .frequent
        }
    }
}

/// How much evidence stands behind the home label. Grows with distinct nights.
public enum PrismConfidence: String, Codable, Sendable {
    case provisional = "PROVISIONAL", low = "LOW", moderate = "MODERATE", high = "HIGH", confirmed = "CONFIRMED"

    init(_ c: EnrichConfidence) {
        switch c {
        case .provisional: self = .provisional
        case .low: self = .low
        case .moderate: self = .moderate
        case .high: self = .high
        case .confirmed: self = .confirmed
        @unknown default: self = .confirmed
        }
    }
}

/// A place the user returns to. Values only — the SDK produces these.
/// Coordinates are the centre of the stays that make up the place.
public struct PrismPlace: Codable, Equatable, Sendable {
    public let kind: PrismPlaceKind
    public let latitude: Double
    public let longitude: Double
    /// Separate stays observed at this place.
    public let visitCount: Int
    /// Total time spent here, in milliseconds.
    public let totalDwellMs: Int64
    /// Distinct nights spent here. What the home label is based on.
    public let distinctNights: Int
    public let firstSeenMs: Int64
    public let lastSeenMs: Int64
    /// Set for `.home`; nil for other kinds.
    public let confidence: PrismConfidence?

    /// Wire names, matching `asDictionary` on the Objective-C view and the Android SDK.
    enum CodingKeys: String, CodingKey {
        case kind, latitude, longitude
        case visitCount = "visit_count"
        case totalDwellMs = "total_dwell_ms"
        case distinctNights = "distinct_nights"
        case firstSeenMs = "first_seen_ms"
        case lastSeenMs = "last_seen_ms"
        case confidence
    }

    init(_ p: EnrichPlace) {
        kind = PrismPlaceKind(p.kind)
        latitude = p.latitude
        longitude = p.longitude
        visitCount = p.visitCount
        totalDwellMs = p.totalDwellMs
        distinctNights = p.distinctNights
        firstSeenMs = p.firstSeenMs
        lastSeenMs = p.lastSeenMs
        confidence = p.confidence.map(PrismConfidence.init)
    }
}

/// The current inference. `home` is nil until at least one stay exists.
public struct PrismPlaces: Codable, Equatable, Sendable {
    public let home: PrismPlace?
    /// Other places, most time spent first.
    public let frequent: [PrismPlace]
    /// When this result was computed, epoch milliseconds; 0 before the first computation.
    public let computedAtMs: Int64
    public let retention: PrismPlaceRetention
    /// Stays inside the retention window.
    public let stayCount: Int
    /// Earliest stay inside the window, or nil. Says how much history the result rests on.
    public let observedFromMs: Int64?

    enum CodingKeys: String, CodingKey {
        case home, frequent, retention
        case computedAtMs = "computed_at_ms"
        case stayCount = "stay_count"
        case observedFromMs = "observed_from_ms"
    }

    init(_ p: EnrichPlaces) {
        home = p.home.map(PrismPlace.init)
        frequent = p.frequent.map(PrismPlace.init)
        computedAtMs = p.computedAtMs
        retention = PrismPlaceRetention(p.retention)
        stayCount = p.stayCount
        observedFromMs = p.observedFromMs
    }

    public static let empty = PrismPlaces(.empty(retention: .threeMonths, computedAtMs: 0))
}
