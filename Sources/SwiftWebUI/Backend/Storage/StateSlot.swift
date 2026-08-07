//
//  StateSlot.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

/// The source location of one `@State` declaration.
///
/// `State.init` captures this through default arguments, so the values describe the
/// property declaration rather than the initializer. Two different declarations can
/// never share a location, and one declaration always reports the same location, which
/// makes this a stable per-declaration key component without a traversal counter.
///
/// The file is reduced to the address of its `#fileID` literal. Literal addresses are
/// stable for the lifetime of the process, which is all a slot key requires, and this
/// avoids string comparison in the Embedded core.
public struct StateDeclarationSite: Hashable, Sendable {
    let fileToken: UInt
    let line: UInt32
    let column: UInt32

    init(file: StaticString, line: UInt32, column: UInt32) {
        self.fileToken = UInt(bitPattern: file.utf8Start)
        self.line = line
        self.column = column
    }
}

/// Identity of one state slot: which view, and which declaration inside it.
public struct StateSlotKey: Hashable, Sendable {
    let path: ViewIdentityPath
    let site: StateDeclarationSite
}

/// A retained state box, held type-erased as an opaque pointer.
///
/// The core may not use dynamic casts, so the box is recovered with
/// `Unmanaged.fromOpaque`, which is a static reinterpretation rather than a runtime
/// cast. That is sound because a slot key implies the declaration, and a declaration
/// implies the value type. `valueSize` and `valueAlignment` are kept as a cheap guard
/// against the one case that could violate that -- a generic view instantiated at two
/// different value types reaching the same path -- and a mismatch discards the slot.
struct StateSlot {
    let pointer: UnsafeMutableRawPointer
    let release: (UnsafeMutableRawPointer) -> Void
    let valueSize: Int
    let valueAlignment: Int
}
