//
//  ItemProvider.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

/// The content that a drag carries, in one or more representations.
///
/// The counterpart of Foundation's `NSItemProvider`: what ``View/onDrag(_:)``
/// returns and what `onDrop(of:isTargeted:perform:)` receives. It drops the `NS` prefix because Foundation already declares
/// `NSItemProvider`, and a file that imports both would not compile.
///
/// A browser drag carries text, keyed by MIME type, so every representation is a
/// `String` and every type identifier is a MIME type — ``UTType/identifier``.
///
/// ```swift
/// Text(task.title)
///     .onDrag { ItemProvider(object: task.id) }
/// ```
///
/// Loading never waits: the browser hands a drop's content over all at once, so a
/// completion handler is called before the loading method returns.
///
/// Dropped files are not supported yet. A drag of files from the desktop carries
/// no representation an `ItemProvider` can hold.
public final class ItemProvider {
    private var storage: [ItemRepresentation]

    /// Creates a provider with no content.
    public init() {
        storage = []
    }

    /// Creates a provider that carries `object` as plain text.
    public convenience init(object: String) {
        self.init()
        registerObject(object)
    }

    /// Creates a provider that carries `item` as the type named by `typeIdentifier`.
    ///
    /// `typeIdentifier` is a MIME type such as `"application/json"`, or
    /// ``UTType/identifier``. A string that is not a MIME type registers nothing.
    public convenience init(item: String, typeIdentifier: String) {
        self.init()
        registerItem(item, forTypeIdentifier: typeIdentifier)
    }

    @_spi(Rendering)
    public convenience init(representations: [ItemRepresentation]) {
        self.init()
        for representation in representations {
            register(representation)
        }
    }

    /// Adds `object` as plain text.
    public func registerObject(_ object: String) {
        register(.init(contentType: .plainText, value: object))
    }

    /// Adds `item` as the type named by `typeIdentifier`, replacing any earlier
    /// content of that type.
    public func registerItem(_ item: String, forTypeIdentifier typeIdentifier: String) {
        guard let contentType = UTType(mimeType: typeIdentifier) else { return }
        register(.init(contentType: contentType, value: item))
    }

    /// The MIME types this provider carries, in the order they were registered.
    public var registeredTypeIdentifiers: [String] {
        storage.map { $0.contentType.identifier }
    }

    /// The content types this provider carries, in the order they were registered.
    public var registeredContentTypes: [UTType] {
        storage.map { $0.contentType }
    }

    /// Whether the provider carries content conforming to `typeIdentifier`.
    public func hasItemConformingToTypeIdentifier(_ typeIdentifier: String) -> Bool {
        guard let contentType = UTType(mimeType: typeIdentifier) else { return false }
        return representation(conformingTo: contentType) != nil
    }

    /// Whether the provider can load a `String`, which it can when it carries any text.
    public func canLoadObject(ofClass: String.Type) -> Bool {
        representation(conformingTo: .text) != nil
    }

    /// Loads the provider's text, preferring plain text, and passes it to
    /// `completionHandler` — or `nil` when there is none.
    ///
    /// The handler runs before this method returns.
    public func loadObject(ofClass: String.Type, completionHandler: (String?) -> Void) {
        completionHandler((representation(conformingTo: .plainText) ?? representation(conformingTo: .text))?.value)
    }

    /// Loads the content conforming to `typeIdentifier` and passes it to
    /// `completionHandler` — or `nil` when there is none.
    ///
    /// The handler runs before this method returns.
    public func loadItem(forTypeIdentifier typeIdentifier: String, completionHandler: (String?) -> Void) {
        guard let contentType = UTType(mimeType: typeIdentifier) else {
            completionHandler(nil)
            return
        }
        completionHandler(representation(conformingTo: contentType)?.value)
    }

    /// Every representation, in registration order.
    @_spi(Rendering)
    public var representations: [ItemRepresentation] {
        storage
    }

    private func register(_ representation: ItemRepresentation) {
        storage.removeAll { $0.contentType == representation.contentType }
        storage.append(representation)
    }

    private func representation(conformingTo contentType: UTType) -> ItemRepresentation? {
        storage.first { $0.contentType.conforms(to: contentType) }
    }
}
