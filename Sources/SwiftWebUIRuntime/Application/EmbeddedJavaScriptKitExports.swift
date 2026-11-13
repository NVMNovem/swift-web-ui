//
//  EmbeddedJavaScriptKitExports.swift
//  swift-web-ui
//

#if hasFeature(Embedded) && arch(wasm32)
import JavaScriptKit
import _CJavaScriptKit

// JavaScriptKit's runtime calls into Swift through three exports: to run a
// `JSClosure` (every event handler), to free one, and to ask which features the
// library has. JavaScriptKit declares them itself, but under Embedded Swift its
// module compiles to an empty object file, and a function is only emitted where
// Swift code calls it, which nothing does for these. A bundle then lacks them and
// the first event handler throws "swjs_call_host_function is not a function".
// The exports below call JavaScriptKit's own functions, which emits them here.
//
// Remove this file once JavaScriptKit's Embedded build emits them itself.

@_expose(wasm, "swjs_call_host_function")
public func _swiftWebUICallHostFunction(
    _ hostFuncRef: JavaScriptHostFuncRef,
    _ argv: UnsafePointer<RawJSValue>,
    _ argc: Int32,
    _ callbackFuncRef: JavaScriptObjectRef
) -> Bool {
    _swjs_call_host_function(hostFuncRef, argv, argc, callbackFuncRef)
}

@_expose(wasm, "swjs_free_host_function")
public func _swiftWebUIFreeHostFunction(_ hostFuncRef: JavaScriptHostFuncRef) {
    _swjs_free_host_function(hostFuncRef)
}

@_expose(wasm, "swjs_library_features")
public func _swiftWebUILibraryFeatures() -> Int32 {
    _swjs_library_features()
}
#endif
