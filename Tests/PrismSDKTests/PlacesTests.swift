import Foundation
import LocalSDKCore
import PrismEnrich
import Testing
@testable import PrismSDK

/// Installs a fake engine for the duration of a test and restores the live one after.
struct FakeEngineScope {
    let fake = FakePlaceEngine()
    init() { PrismEnrichBridge.engine.set(PlaceEngineBox(fake)) }
    func done() {
        PrismEnrichBridge.reset()
        PrismEnrichBridge.engine.set(nil)
        PrismFanout.clearHostClosures()
    }
}

/// Both suites mutate global fan-out and bridge state, so they must not run
/// concurrently with each other. A serialized parent orders its nested suites.
@Suite("Enrich integration", .serialized)
enum EnrichIntegrationTests {

    @Suite("Fan-out")
    struct PrismFanoutTests {

        @Test("a location reaches the host closure and Enrich once each")
        func deliversToBoth() {
            let scope = FakeEngineScope(); defer { scope.done() }
            PrismEnrichBridge.apply(PrismEnrichConfig())
            final class Seen: @unchecked Sendable { var locations: [PrismLocation] = [] }
            let seen = Seen()
            PrismFanout.hostLocation.set(ClosureBox { seen.locations.append($0) })

            PrismFanout.deliver(LocationFixtures.visit)

            #expect(seen.locations.count == 1)
            #expect(seen.locations.first?.id == "loc-0001")
            #expect(scope.fake.ingested.count == 1)
            #expect(scope.fake.ingested.first?.arrivalMs == 1_756_999_000_000)
        }

        @Test("with no host closure, Enrich still receives it; with no Enrich, the host still does")
        func eitherSide() {
            let scope = FakeEngineScope(); defer { scope.done() }
            PrismEnrichBridge.apply(PrismEnrichConfig())
            PrismFanout.deliver(LocationFixtures.moving)
            #expect(scope.fake.ingested.count == 1)

            PrismEnrichBridge.apply(nil)
            final class Count: @unchecked Sendable { var n = 0 }
            let count = Count()
            PrismFanout.hostLocation.set(ClosureBox { _ in count.n += 1 })
            PrismFanout.deliver(LocationFixtures.moving)
            #expect(count.n == 1)
            #expect(scope.fake.ingested.count == 1, "disabled: nothing more reaches Enrich")
        }

        @Test("a second onLocation replaces the first; reset clears both")
        func replaceAndClear() {
            let scope = FakeEngineScope(); defer { scope.done() }
            final class Log: @unchecked Sendable { var calls: [String] = [] }
            let log = Log()
            PrismFanout.hostLocation.set(ClosureBox { _ in log.calls.append("first") })
            PrismFanout.hostLocation.set(ClosureBox { _ in log.calls.append("second") })
            PrismFanout.deliver(LocationFixtures.moving)
            #expect(log.calls == ["second"])
            PrismFanout.clearHostClosures()
            PrismFanout.deliver(LocationFixtures.moving)
            #expect(log.calls == ["second"])
        }
    }

    @Suite("PrismEnrichBridge")
    struct PrismEnrichBridgeTests {
        @Test("apply(nil) after apply(config) stops but does not clear")
        func stopNotClear() {
            let scope = FakeEngineScope(); defer { scope.done() }
            PrismEnrichBridge.apply(PrismEnrichConfig(retention: .sixMonths))
            #expect(scope.fake.started.last?.retention == .sixMonths)
            #expect(PrismFanout.enrichSink.current != nil)
            PrismEnrichBridge.apply(nil)
            #expect(scope.fake.stops == 1)
            #expect(scope.fake.clears == 0)
            #expect(PrismFanout.enrichSink.current == nil)
        }

        @Test("clearPlaces re-starts with the last config")
        func clearRestarts() {
            let scope = FakeEngineScope(); defer { scope.done() }
            PrismEnrichBridge.apply(PrismEnrichConfig(retention: .oneMonth))
            PrismEnrichBridge.clearPlaces()
            #expect(scope.fake.clears == 1)
            #expect(scope.fake.started.count == 2)
            #expect(scope.fake.started.last?.retention == .oneMonth)
        }

        @Test("placesUpdates yields what the engine pushes and stops when cancelled")
        func updates() async {
            let scope = FakeEngineScope(); defer { scope.done() }
            PrismEnrichBridge.apply(PrismEnrichConfig())
            let stream = PrismEnrichBridge.placesUpdates()
            var iterator = stream.makeAsyncIterator()
            let first = await iterator.next()
            #expect(first?.home == nil, "initial value")
            scope.fake.push(FakePlaceEngine.samplePlaces())
            let second = await iterator.next()
            #expect(second?.home?.distinctNights == 7)
        }

        @Test("storage dir is under Application Support and vendor-scoped")
        func storage() {
            let dir = PrismEnrichBridge.storageDir()
            #expect(dir.path.hasSuffix("ai.terrabite.prism/enrich"))
            #expect(FileManager.default.fileExists(atPath: dir.path))
        }
    }
}

@Suite("EnrichFix mapping")
struct EnrichFixMappingTests {
    @Test("maps the fields Enrich needs from a visit row")
    func visitRow() {
        let f = EnrichFix(PrismLocation(LocationFixtures.visit))
        #expect(f.latitude == 52.2297)
        #expect(f.longitude == 21.0122)
        #expect(f.timestampMs == 1_757_000_000_123)
        #expect(f.tzOffsetMinutes == 120)
        #expect(f.horizontalAccuracyMeters == 12.25)
        #expect(f.speedMps == 3.5)
        #expect(f.kind == .visit)
        #expect(f.arrivalMs == 1_756_999_000_000)
        #expect(f.departureMs == 1_757_000_500_000)
    }

    @Test("a moving row has no visit dates")
    func movingRow() {
        let f = EnrichFix(PrismLocation(LocationFixtures.moving))
        #expect(f.kind == .moving)
        #expect(f.arrivalMs == nil)
        #expect(f.departureMs == nil)
        #expect(f.tzOffsetMinutes == -300)
    }

    @Test("offset strings", arguments: [("+02:00", 120), ("-05:00", -300), ("+0530", 330), ("Z", 0), ("", 0), ("+2", 0)])
    func offsets(input: String, expected: Int) {
        #expect(EnrichFix.parseOffsetMinutes(input) == expected)
    }
}

@Suite("PrismPlace mapping")
struct PrismPlaceMappingTests {
    @Test("every field crosses, into the Swift value and the Objective-C view")
    func mapping() {
        let places = PrismPlaces(FakePlaceEngine.samplePlaces())
        let h = try! #require(places.home)
        #expect(h.kind == .home)
        #expect(h.latitude == 52.2297)
        #expect(h.longitude == 21.0122)
        #expect(h.visitCount == 7)
        #expect(h.totalDwellMs == 3_600_000 * 70)
        #expect(h.distinctNights == 7)
        #expect(h.firstSeenMs == 1_000)
        #expect(h.lastSeenMs == 2_000)
        #expect(h.confidence == .high)
        #expect(places.frequent.count == 1)
        #expect(places.frequent[0].confidence == nil)
        #expect(places.retention == .sixMonths)
        #expect(places.stayCount == 12)
        #expect(places.observedFromMs == 1_000)
        #expect(places.computedAtMs == 3_000)

        let objc = PrismPlacesObjC(places)
        #expect(objc.home?.kind == "HOME")
        #expect(objc.home?.confidence == "HIGH")
        #expect(objc.frequent.count == 1)
        #expect(objc.retention == "SIX_MONTHS")
        #expect(objc.observedFromMs?.int64Value == 1_000)
    }

    @Test("PrismPlace has nine fields, mirrored by the Objective-C view")
    func fieldCount() {
        let p = PrismPlaces(FakePlaceEngine.samplePlaces()).home!
        #expect(Mirror(reflecting: p).children.count == 9)
        #expect(Mirror(reflecting: PrismPlaceObjC(p)).children.count == 9)
    }

    @Test("JSON and asDictionary use the same snake_case wire names")
    func wireNames() throws {
        let places = PrismPlaces(FakePlaceEngine.samplePlaces())
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(places)) as! [String: Any]
        let home = json["home"] as! [String: Any]
        #expect(Set(home.keys) == ["kind", "latitude", "longitude", "visit_count", "total_dwell_ms", "distinct_nights", "first_seen_ms", "last_seen_ms", "confidence"])
        #expect(Set(json.keys) == ["home", "frequent", "computed_at_ms", "retention", "stay_count", "observed_from_ms"])
        let dict = PrismPlacesObjC(places).asDictionary
        #expect(Set((dict["home"] as! [String: Any]).keys) == Set(home.keys))
        #expect(Set(dict.keys) == Set(json.keys))
    }

    @Test("raw strings are pinned")
    func rawStrings() {
        #expect(PrismPlaceKind.home.rawValue == "HOME")
        #expect(PrismPlaceKind.frequent.rawValue == "FREQUENT")
        #expect(PrismConfidence.provisional.rawValue == "PROVISIONAL")
        #expect(PrismConfidence.confirmed.rawValue == "CONFIRMED")
        #expect(PrismPlaceRetention.oneMonth.rawValue == "ONE_MONTH")
    }
}

@Suite("PrismEnrichConfig")
struct PrismEnrichConfigTests {
    @Test("off by default, not an engine field")
    func defaults() {
        #expect(PrismConfig().enrich == nil)
        let c = PrismConfig().withEnrich(PrismEnrichConfig(retention: .oneMonth))
        #expect(c.enrich?.retention == .oneMonth)
        #expect(c.core.trackingMode == Config().trackingMode, "engine config untouched")
        #expect(PrismEnrichConfig().retention == .threeMonths)
        #expect(PrismEnrichConfig().withRetention(.sixMonths).core.retention == .sixMonths)
    }

    @Test("Objective-C config maps the enrich flags and falls back on a typo")
    func objc() {
        let c = PrismConfigObjC()
        #expect(c.config.enrich == nil)
        c.enrichEnabled = true
        c.enrichRetention = "ONE_MONTH"
        #expect(c.config.enrich?.retention == .oneMonth)
        c.enrichRetention = "FOREVER"
        #expect(c.config.enrich?.retention == .threeMonths)
    }
}
