import Foundation
import LocalSDKCore

/// Receives locations and errors.
///
/// Held **weakly** — keep your own strong reference, or callbacks stop silently
/// when your object is deallocated.
///
/// `@MainActor`: the engine delivers every callback on the main queue, and
/// declaring that here is what lets a view model or controller conform without
/// the compiler flagging the conformance as crossing an isolation boundary —
/// a warning in Swift 5 and an error in the Swift 6 language mode.
@MainActor
public protocol PrismLocationDelegate: AnyObject {

    /// A location was produced. Called on the main actor.
    func locationDidUpdate(_ location: PrismLocation)

    /// Something went wrong. The SDK keeps tracking unless the message says
    /// otherwise.
    func locationDidFail(_ error: String)
}

/// Adopts the engine's delegate and forwards to Prism's, mapping on the way.
///
/// Two lifetimes to keep straight, and getting either wrong is silent:
///
/// - The **engine** holds *this* weakly, so `Prism` retains it. Without that it
///   would be deallocated the moment `setDelegate` returned.
/// - *This* holds the **caller's** delegate weakly, matching the contract above,
///   so setting a delegate never keeps the caller's object alive.
///
/// `@MainActor` because its target is. The engine's protocol is nonisolated, so
/// the two forwarding methods are `nonisolated` to satisfy it and hop back with
/// `assumeIsolated`, which is honest: the engine dispatches both on the main
/// queue and traps here if that ever stops being true.
@MainActor
final class PrismDelegateAdapter: LocationDelegate {

    private weak var target: PrismLocationDelegate?

    init(_ target: PrismLocationDelegate) {
        self.target = target
    }

    nonisolated func locationDidUpdate(_ location: Location) {
        MainActor.assumeIsolated { target?.locationDidUpdate(PrismLocation(location)) }
    }

    nonisolated func locationDidFail(_ error: String) {
        MainActor.assumeIsolated { target?.locationDidFail(error) }
    }
}

/// One strong reference, behind a lock.
///
/// Exists so `Prism` and `PrismObjC` can retain their delegate adapters without
/// a bare `static var`, which is not concurrency-safe. `NSLock` rather than
/// `OSAllocatedUnfairLock` or `Mutex` because the deployment floor is iOS 15 and
/// those arrive in iOS 16 and 18. Every access goes through the lock, which is
/// what makes the `@unchecked Sendable` honest.
final class Retained<T: AnyObject>: @unchecked Sendable {

    private let lock = NSLock()
    private var value: T?

    func set(_ newValue: T?) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }

    var current: T? {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}
