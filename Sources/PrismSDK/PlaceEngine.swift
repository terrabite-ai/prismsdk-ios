import Foundation
import PrismEnrich

/// A cancel token owned by the seam, so fakes need nothing from the Enrich module.
final class PlaceObservation: Sendable {
    private let onCancel: @Sendable () -> Void
    init(onCancel: @escaping @Sendable () -> Void) { self.onCancel = onCancel }
    func cancel() { onCancel() }
}

/// The seam between Prism and the Enrich binary. `Enrich.*` is called only from
/// `LiveEnrich`; tests install a fake on `PrismEnrichBridge.engine`.
protocol PlaceEngine: Sendable {
    func attach(storageDir: URL)
    var isEnabled: Bool { get }
    func start(_ config: EnrichConfig)
    func stop()
    func ingest(_ fix: EnrichFix)
    func catchUp()
    func flush()
    func places() -> EnrichPlaces
    func observe(_ listener: @escaping @Sendable (EnrichPlaces) -> Void) -> PlaceObservation
    func clear()
}

struct LiveEnrich: PlaceEngine {
    func attach(storageDir: URL) { Enrich.attach(storageDir: storageDir) }
    var isEnabled: Bool { Enrich.isEnabled }
    func start(_ config: EnrichConfig) { Enrich.start(config) }
    func stop() { Enrich.stop() }
    func ingest(_ fix: EnrichFix) { Enrich.ingest(fix) }
    func catchUp() { Enrich.catchUp() }
    func flush() { Enrich.flush() }
    func places() -> EnrichPlaces { Enrich.places() }
    func observe(_ listener: @escaping @Sendable (EnrichPlaces) -> Void) -> PlaceObservation {
        let observation = Enrich.observe(listener)
        return PlaceObservation { observation.cancel() }
    }
    func clear() { Enrich.clear() }
}

/// Class wrapper so an engine can live in a `Retained` box.
final class PlaceEngineBox: @unchecked Sendable {
    let engine: any PlaceEngine
    init(_ engine: any PlaceEngine) { self.engine = engine }
}
