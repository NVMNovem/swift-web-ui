//
//  EmbeddedConcurrencyRuntime.swift
//  swift-web-ui
//

#if hasFeature(Embedded)
// Swift 6.3's Embedded concurrency library (libswift_Concurrency.a) calls
// these runtime functions, and no Embedded library defines them, so an application
// that starts a `Task` or uses an actor does not link. They are only reached
// on paths an application rarely takes (custom executors, debugger reporting).
//
// Remove this file once a Swift release defines them.

/// An Embedded object starts with its type's metadata pointer.
@_cdecl("swift_getObjectType")
public func _embeddedGetObjectType(_ object: UnsafeRawPointer) -> UnsafeRawPointer {
    object.load(as: UnsafeRawPointer.self)
}

/// Swift calling convention, as the runtime declares it.
@_silgen_name("swift_compareWitnessTables")
public func _embeddedCompareWitnessTables(_ lhs: UnsafeRawPointer?, _ rhs: UnsafeRawPointer?) -> Bool {
    lhs == rhs
}

@_cdecl("_swift_shouldReportFatalErrorsToDebugger")
public func _embeddedShouldReportFatalErrorsToDebugger() -> Bool { false }

@_cdecl("_swift_reportToDebugger")
public func _embeddedReportToDebugger(_ flags: UInt, _ message: UnsafeRawPointer?, _ details: UnsafeRawPointer?) {}

/// Swift calling convention, as the runtime declares it: (type, qualified) -> TypeNamePair.
@_silgen_name("swift_getTypeName")
public func _embeddedGetTypeName(_ type: UnsafeRawPointer, _ qualified: Bool) -> (UnsafePointer<UInt8>, Int) {
    let name: StaticString = "<type>"
    return (name.utf8Start, name.utf8CodeUnitCount)
}

// The executor checks below are asked about a custom serial executor: the
// executor, its type and its SerialExecutor witness table, as the generic
// Swift originals take them. In a browser application every custom executor is
// JavaScriptKit's event loop on the one JavaScript thread (it is also the main
// executor, see `EmbeddedExecutors`), so each answers "yes, the same context,
// the main one". Answering "no" sends a main-actor job to be enqueued again
// on every resume.

@_silgen_name("_swift_task_isMainExecutorSwift")
public func _embeddedIsMainExecutor(_ executor: UnsafeRawPointer, _ type: UnsafeRawPointer, _ witnessTable: UnsafeRawPointer) -> Bool {
    true
}

@_silgen_name("_swift_task_checkIsolatedSwift")
public func _embeddedCheckIsolated(_ executor: UnsafeRawPointer, _ type: UnsafeRawPointer, _ witnessTable: UnsafeRawPointer) {}

/// 1: isolated. There is only the one thread to be isolated on.
@_silgen_name("_swift_task_isIsolatingCurrentContextSwift")
public func _embeddedIsIsolatingCurrentContext(_ executor: UnsafeRawPointer, _ type: UnsafeRawPointer, _ witnessTable: UnsafeRawPointer) -> Int8 {
    1
}

@_silgen_name("_task_serialExecutor_isSameExclusiveExecutionContext")
public func _embeddedIsSameExclusiveExecutionContext(
    _ current: UnsafeRawPointer, _ executor: UnsafeRawPointer, _ type: UnsafeRawPointer, _ witnessTable: UnsafeRawPointer
) -> Bool {
    true
}
#endif
