import Foundation
import LocalSDKCore

/// Holds a host closure so it can live in a `Retained` box.
final class ClosureBox<T>: @unchecked Sendable {
    let call: (T) -> Void
    init(_ call: @escaping (T) -> Void) { self.call = call }
}

/// Prism owns the engine's single closure-listener slots and fans out from here.
///
/// The engine keeps exactly one location closure and one error closure and
/// replaces them on every call, and its `reset()` clears them. Prism takes both
/// slots in `installEngineListeners()` (called from `initialize`, and again by
/// `onLocation`/`onError` in case a host registers after a reset), keeps the
/// host's closures in its own boxes, and delivers to Enrich first, then the host.
/// The delegate path is separate: the engine calls listener and delegate for
/// every fix, so tapping the closure slot alone sees everything.
enum PrismFanout {
    static let hostLocation = Retained<ClosureBox<PrismLocation>>()
    static let hostError = Retained<ClosureBox<String>>()
    /// Set by `PrismEnrichBridge` while places are enabled. Must not block.
    static let enrichSink = Retained<ClosureBox<PrismLocation>>()

    /// Idempotent: the engine replaces its closure under its own lock.
    static func installEngineListeners() {
        LocalSDK.onLocation { deliver($0) }
        LocalSDK.onError { deliverError($0) }
    }

    static func deliver(_ location: Location) {
        let mapped = PrismLocation(location)
        enrichSink.current?.call(mapped)
        hostLocation.current?.call(mapped)
    }

    static func deliverError(_ error: String) {
        hostError.current?.call(error)
    }

    static func clearHostClosures() {
        hostLocation.set(nil)
        hostError.set(nil)
    }
}
