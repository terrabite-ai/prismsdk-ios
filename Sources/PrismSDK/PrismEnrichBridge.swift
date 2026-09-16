import Foundation
import PrismEnrich
#if canImport(UIKit)
import UIKit
#endif

/// Wires the Enrich binary into Prism: feeds it every location while enabled,
/// runs a catch-up when the app returns to the foreground and flushes when it
/// leaves, and maps its results into Prism's own types.
enum PrismEnrichBridge {

    static let engine = Retained<PlaceEngineBox>()
    private static let lastConfig = Retained<ConfigBox>()
    private static let observers = Retained<ObserverTokens>()

    final class ConfigBox: @unchecked Sendable { let config: PrismEnrichConfig; init(_ c: PrismEnrichConfig) { config = c } }
    final class ObserverTokens: @unchecked Sendable { let tokens: [NSObjectProtocol]; init(_ t: [NSObjectProtocol]) { tokens = t } }

    static var current: any PlaceEngine { engine.current?.engine ?? LiveEnrich() }

    /// `Library/Application Support/ai.terrabite.prism/enrich`, protected and excluded from backup.
    static func storageDir() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        var vendor = base.appendingPathComponent("ai.terrabite.prism", isDirectory: true)
        let dir = vendor.appendingPathComponent("enrich", isDirectory: true)
        var attributes: [FileAttributeKey: Any] = [:]
        #if os(iOS)
        attributes[.protectionKey] = FileProtectionType.completeUntilFirstUserAuthentication
        #endif
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true, attributes: attributes)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? vendor.setResourceValues(values)
        return dir
    }

    static func attach() {
        current.attach(storageDir: storageDir())
        if current.isEnabled { install() }
    }

    static func apply(_ config: PrismEnrichConfig?) {
        if let config {
            lastConfig.set(ConfigBox(config))
            current.start(config.core)
            install()
        } else {
            lastConfig.set(nil)
            uninstall()
            current.stop()
        }
    }

    static func places() -> PrismPlaces { PrismPlaces(current.places()) }

    static func placesUpdates() -> AsyncStream<PrismPlaces> {
        let engine = current
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let observation = engine.observe { continuation.yield(PrismPlaces($0)) }
            continuation.onTermination = { _ in observation.cancel() }
        }
    }

    /// Delete everything, then start again if places were enabled.
    static func clearPlaces() {
        current.clear()
        if let c = lastConfig.current?.config { current.start(c.core) }
    }

    /// `Prism.reset()`: delete and disable.
    static func reset() {
        uninstall()
        lastConfig.set(nil)
        current.clear()
    }

    private static func install() {
        let engine = current
        if PrismFanout.enrichSink.current == nil {
            PrismFanout.enrichSink.set(ClosureBox { engine.ingest(EnrichFix($0)) })
        }
        #if canImport(UIKit)
        if observers.current == nil {
            let center = NotificationCenter.default
            let fg = center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in engine.catchUp() }
            let bg = center.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { _ in engine.flush() }
            observers.set(ObserverTokens([fg, bg]))
        }
        #endif
    }

    private static func uninstall() {
        PrismFanout.enrichSink.set(nil)
        if let tokens = observers.current?.tokens {
            for t in tokens { NotificationCenter.default.removeObserver(t) }
        }
        observers.set(nil)
    }
}

extension EnrichFix {
    /// Maps a Prism location to Enrich's input. The engine's `±HH:MM` offset is
    /// resolved at the fix instant, so it is used as is.
    init(_ l: PrismLocation) {
        self.init(
            latitude: l.latitude,
            longitude: l.longitude,
            timestampMs: l.timestamp,
            tzOffsetMinutes: EnrichFix.parseOffsetMinutes(l.timezoneOffset),
            horizontalAccuracyMeters: l.horizontalAccuracy,
            speedMps: l.speed,
            kind: EnrichFixKind(rawValue: l.type.rawValue) ?? .stationary,
            arrivalMs: l.arrivalDate,
            departureMs: l.departureDate
        )
    }

    /// `"+02:00"`, `"+0530"`, `"-05:00"` → minutes east of UTC; anything else → 0.
    static func parseOffsetMinutes(_ s: String) -> Int {
        guard let sign = s.first, sign == "+" || sign == "-" else { return 0 }
        let digits = s.dropFirst().filter(\.isNumber)
        guard digits.count == 4, let h = Int(digits.prefix(2)), let m = Int(digits.suffix(2)) else { return 0 }
        return (sign == "-" ? -1 : 1) * (h * 60 + m)
    }
}
