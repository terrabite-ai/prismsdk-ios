import Foundation
import PrismEnrich
@testable import PrismSDK

/// Records every call and lets a test push results, so the bridge is tested without the binary.
final class FakePlaceEngine: PlaceEngine, @unchecked Sendable {
    private let lock = NSLock()
    var ingested: [EnrichFix] = []
    var started: [EnrichConfig] = []
    var stops = 0, catchUps = 0, flushes = 0, clears = 0, attaches = 0
    var attachedDir: URL?
    var enabled = false
    var current: EnrichPlaces = .empty(retention: .threeMonths, computedAtMs: 0)
    private var listeners: [(UUID, @Sendable (EnrichPlaces) -> Void)] = []

    func attach(storageDir: URL) { lock.lock(); attaches += 1; attachedDir = storageDir; lock.unlock() }
    var isEnabled: Bool { lock.lock(); defer { lock.unlock() }; return enabled }
    func start(_ config: EnrichConfig) { lock.lock(); started.append(config); enabled = true; lock.unlock() }
    func stop() { lock.lock(); stops += 1; enabled = false; lock.unlock() }
    func ingest(_ fix: EnrichFix) { lock.lock(); ingested.append(fix); lock.unlock() }
    func catchUp() { lock.lock(); catchUps += 1; lock.unlock() }
    func flush() { lock.lock(); flushes += 1; lock.unlock() }
    func places() -> EnrichPlaces { lock.lock(); defer { lock.unlock() }; return current }
    func observe(_ listener: @escaping @Sendable (EnrichPlaces) -> Void) -> PlaceObservation {
        let id = UUID()
        lock.lock(); listeners.append((id, listener)); let c = current; lock.unlock()
        listener(c)
        return PlaceObservation { [weak self] in
            guard let self else { return }
            self.lock.lock(); self.listeners.removeAll { $0.0 == id }; self.lock.unlock()
        }
    }
    func clear() {
        lock.lock(); clears += 1; enabled = false; current = .empty(retention: current.retention, computedAtMs: 0); let ls = listeners; let c = current; lock.unlock()
        for (_, l) in ls { l(c) }
    }
    func push(_ p: EnrichPlaces) {
        lock.lock(); current = p; let ls = listeners; lock.unlock()
        for (_, l) in ls { l(p) }
    }

    static func samplePlaces() -> EnrichPlaces {
        EnrichPlaces(
            home: EnrichPlace(kind: .home, latitude: 52.2297, longitude: 21.0122, visitCount: 7, totalDwellMs: 3_600_000 * 70,
                              distinctNights: 7, firstSeenMs: 1_000, lastSeenMs: 2_000, confidence: .high),
            frequent: [EnrichPlace(kind: .frequent, latitude: 52.245, longitude: 21.04, visitCount: 5, totalDwellMs: 3_600_000 * 45,
                                   distinctNights: 0, firstSeenMs: 1_500, lastSeenMs: 1_900, confidence: nil)],
            computedAtMs: 3_000, retention: .sixMonths, stayCount: 12, clusterCount: 2, observedFromMs: 1_000)
    }
}
