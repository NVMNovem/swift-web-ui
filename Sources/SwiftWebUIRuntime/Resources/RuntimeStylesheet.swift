//
//  RuntimeStylesheet.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 22/07/2026.
//

import SwiftWebUI

/// A stylesheet installed into the browser document head for a runtime application.
///
/// The same value as ``DocumentStylesheet``, which the core defines so that a view's
/// ``View/stylesheet(_:)`` modifier can name one too.
public typealias RuntimeStylesheet = DocumentStylesheet
