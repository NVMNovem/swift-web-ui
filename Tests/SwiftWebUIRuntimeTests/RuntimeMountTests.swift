//
//  RuntimeMountTests.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 07/08/2026.
//

import Testing

/// Parent suite for every test that mounts a root.
///
/// Mounting installs process-global hooks -- `ViewInvalidation` and `StateSlotStorage`
/// each hold one active callback/store -- so two suites mounting at the same time
/// observe each other's invalidations and state slots. Swift Testing parallelises across
/// suites, and `.serialized` only orders tests within one suite, so the suites are
/// nested here to share a single serialized parent.
@Suite(.serialized) enum RuntimeMountTests {}
