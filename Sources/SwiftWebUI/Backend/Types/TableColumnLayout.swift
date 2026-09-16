//
//  TableColumnLayout.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 16/09/2026.
//

/// How a ``Table`` decides how wide its columns are.
public enum TableColumnLayout: String, Hashable, Sendable {
    /// Every column is as wide as its own widest cell wants to be.
    ///
    /// The width a column declares is a suggestion the browser may exceed, so one
    /// long line — a description that does not wrap — can take a column far wider
    /// than it was given and squeeze every other column out of the way.
    case sizedToContent

    /// Declared widths hold, and the columns without one share what is left.
    ///
    /// This is what lets a cell be cut off with an ellipsis: a column that cannot
    /// grow past its width gives the text inside it something to be cut against.
    case fixed
}
