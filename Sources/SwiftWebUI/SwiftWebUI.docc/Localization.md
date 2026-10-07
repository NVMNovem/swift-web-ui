# Localization

Show text in the reader's language with string catalogs.

## Overview

SwiftWebUI localizes through [SwiftLocalization](https://github.com/NVMNovem/swift-localization),
which it re-exports. As in SwiftUI, a string literal passed to ``Text``, ``Button`` or
``Link`` is a localization key, and a `String` value is shown as it is:

```swift
Text("cart.title")          // looked up in the catalog
Text("\(count) items")      // looked up as "%lld items" and pluralized per locale
Text(product.name)          // a value: shown verbatim
Text(verbatim: "v1.0")      // a literal that must not be localized
Button("Order") { submit() }
Link("Terms", destination: "/terms")
```

Text that has no catalog entry renders exactly as written, with its interpolations
formatted, so an application that has no catalog yet behaves as it did before.

## Supplying a catalog and a locale

Place a catalog and a locale around the views that should use them:

```swift
CheckoutPage()
    .localizationCatalog(.localizable)
    .locale("nl-BE")
```

- ``View/localizationCatalog(_:)`` takes a `LocalizationCatalog`. Add
  `SwiftLocalizationPlugin` to your target and put `Localizable.xcstrings` in it; the
  plugin generates `LocalizationCatalog.localizable` at build time.
- ``View/locale(_:)`` takes a BCP 47 language tag. Lookup falls back from `nl-BE` to
  `nl` and then to the catalog's source language. With no locale placed, text resolves
  in the source language. The process and browser locale are never read implicitly, so
  a static render is the same on every machine.
- ``View/localizationResolver(_:)`` takes a configured `LocalizationResolver` when you
  need your own number formatter, plural rules, or fallback locales.

A modifier placed further in replaces the outer one for that subtree only.

`locale(_:)` is SwiftUI's `.environment(\.locale, _:)`. It is a modifier of its own
because key paths are unavailable in Embedded Swift.

```swift
// Package.swift
.target(
    name: "App",
    dependencies: [.product(name: "SwiftWebUIStatic", package: "swift-web-ui")],
    plugins: [.plugin(name: "SwiftLocalizationPlugin", package: "swift-localization")]
)
```

## How it resolves

A localized text is resolved while its view is lowered to a ``ViewNode``; the node holds
the final string. The locale and catalog travel down the traversal in ``ViewContext``,
not in shared storage. Static and runtime rendering therefore produce the same text, and
changing the locale is an ordinary re-render.

## Limitations

- Content that a primitive lowers eagerly — the content closure of ``Button`` and
  ``Link``, a ``Tab`` label — is lowered before a localization is known and shows
  default values. Their string-literal titles are localized; ``Tab`` titles, table
  column titles, placeholders and navigation titles are not localized yet.
- There is no way to read the current locale from a view yet.
- Numbers are shown with plain digits. Grouping and localized digits need a
  `LocalizedNumberFormatter`, supplied through ``View/localizationResolver(_:)``.
- The runtime does not detect the browser's language; pass the locale you want.

## Topics

### Localized views

- ``Text``
- ``Button``
- ``Link``

### Choosing a language

- ``View/locale(_:)``
- ``View/localizationCatalog(_:)``
- ``View/localizationResolver(_:)``
- ``LocalizationWriter``
