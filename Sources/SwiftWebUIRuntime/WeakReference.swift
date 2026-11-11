//
//  WeakReference.swift
//  swift-web-ui
//

/// A reference that does not keep its object alive, in a form Embedded Swift
/// accepts.
///
/// Embedded Swift has no `weak`. The object that hands this out clears it in
/// its own `deinit`, so a scheduled callback or an observation callback that
/// outlives the object finds `nil` instead of a dangling pointer, which is
/// what `weak` gave before. That is only sound because a runtime lives on the
/// browser's one thread: nothing can read the reference while `deinit` runs.
///
/// The same type is used on every platform, so the host tests cover the path
/// a browser build takes.
final class WeakReference<Object: AnyObject> {
    private var unmanaged: Unmanaged<Object>?

    init() {}

    /// The object, or `nil` once it has gone away.
    var object: Object? {
        unmanaged?.takeUnretainedValue()
    }

    /// Points the reference at `object`. Called by `object` itself, once it
    /// is fully initialised.
    func set(_ object: Object) {
        unmanaged = .passUnretained(object)
    }

    /// Called from the object's `deinit`.
    func clear() {
        unmanaged = nil
    }
}
