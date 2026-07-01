# Contributor Guide

Keep implementation, tests, and documentation aligned when changing SwiftWebUI.

## Overview

Every feature starts with ownership:

1. If the feature is an HTML node, HTML attribute rendering behavior, or escaping behavior, add it to SwiftHTML first.
2. If the feature is a CSS property, CSS value, declaration, or stylesheet rendering behavior, add it to SwiftCSS first.
3. If the feature is web UI intent, a view, a modifier, state behavior, rendered resources, or document behavior, add it to SwiftWebUI.

## Required Steps

For SwiftWebUI changes:

1. Add or update the implementation.
2. Add tests for rendered HTML, CSS, JavaScript resources, or document output.
3. Update DocC documentation.
4. Update README examples when the recommended public API changes.
5. Update `ARCHITECTURE.md` when ownership boundaries or architecture change.

## Discussion

Documentation is part of the Definition of Done. A change that adds public API, changes behavior, adds a modifier, adds a view, or changes architecture is incomplete until the relevant DocC articles and symbol comments are updated.

This rule is especially important for AI agents and future packages such as SwiftMailUI. The documentation should describe current behavior honestly, including static-only limitations and deferred browser-runtime behavior.
