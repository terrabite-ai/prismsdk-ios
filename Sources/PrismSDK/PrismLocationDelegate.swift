import Foundation
import LocalSDKCore

/// Receives locations and errors.
///
/// Held **weakly** — keep your own strong reference, or callbacks stop silently
/// when your object is deallocated.
public protocol PrismLocationDelegate: AnyObject {

    /// A location was produced. Called on an arbitrary thread; hop to the main
    /// actor before touching UI.
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
final class PrismDelegateAdapter: LocationDelegate {

    private weak var target: PrismLocationDelegate?

    init(_ target: PrismLocationDelegate) {
        self.target = target
    }

    func locationDidUpdate(_ location: Location) {
        target?.locationDidUpdate(PrismLocation(location))
    }

    func locationDidFail(_ error: String) {
        target?.locationDidFail(error)
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
