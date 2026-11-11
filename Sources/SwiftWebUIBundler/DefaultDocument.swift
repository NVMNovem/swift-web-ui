//
//  DefaultDocument.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 11/11/2026.
//

import SwiftHTML
import SwiftWebUIStatic

/// The `index.html` an application gets when it does not bring its own.
///
/// It carries three things a browser application cannot start without: a loading
/// screen that paints before any WebAssembly has arrived, the element the application
/// mounts into, and the loader that fetches and starts the bundle.
struct DefaultDocument {
    var title: String
    var language: String
    var mountPoint: String
    /// The path the output is served under, with a leading and trailing slash.
    var basePath: String
    var bundleName: String
    /// The bundle's uncompressed size, which the progress bar is measured against.
    var bundleBytes: Int
    /// Where `@bjorn3/browser_wasi_shim` resolves to, when the page needs an import map.
    var wasiShimAddress: String?

    func htmlString() -> String {
        webDocument.htmlString(prettyPrinted: true)
    }

    var webDocument: WebDocument {
        var splash = HTMLRenderer().renderView(Self.splash())
        splash.resources.styles.append(
            StyleResource(id: "swiftwebui-splash", scope: .global, content: Self.splashCSS)
        )

        var scripts: [WebScript] = []
        if let wasiShimAddress {
            scripts.append(.importMap(importMap(shim: wasiShimAddress)))
        }
        scripts.append(.module(Self.loader))

        return WebDocument(
            title: title,
            meta: [.charset("utf-8"), .viewport],
            renderedView: splash,
            stylesheetPath: nil,
            language: language,
            headNodes: [
                MetaTag.name("swiftwebui-base", content: basePath).htmlNode,
                MetaTag.name("swiftwebui-bundle", content: bundleName).htmlNode,
                // `Content-Length` cannot stand in for this: a server that compresses
                // reports compressed bytes while the loader counts decompressed ones.
                MetaTag.name("swiftwebui-bundle-bytes", content: String(bundleBytes)).htmlNode,
            ],
            // The loading screen must not wait on a second file.
            renderedStyleDelivery: .inline,
            bodyScripts: scripts,
            bodySuffixNodes: [
                .element(.init(tag: "div", attributes: [.init("id", mountPoint)], children: [], isVoid: false))
            ]
        )
    }

    private func importMap(shim: String) -> String {
        """
        {
            "imports": {
                "\(Bundler.wasiShimSpecifier)": "\(shim)"
            }
        }
        """
    }

    /// The loading screen, rendered to static markup at build time.
    ///
    /// A function over primitive views rather than a `View` type with a `body`:
    /// lowering primitives touches none of the storage a composed view's traversal
    /// shares, so generating a document is safe from any thread.
    private static func splash() -> some View {
        Div {
            Div {
                Div {}
                    .id("swiftwebui-splash-bar")
                    .class("swiftwebui-splash-bar")
            }
            .class("swiftwebui-splash-track")
            .attribute("aria-hidden", "true")

            Text(verbatim: "Loading…", semanticRole: .p)
                .id("swiftwebui-splash-status")
                .class("swiftwebui-splash-status")
                .attribute("role", "status")

            // A `String` value, so the label is shown as written and not looked up
            // as a localization key.
            Button(String("Try again"))
                .id("swiftwebui-splash-retry")
                .class("swiftwebui-splash-retry")
                .attribute("hidden", "")
        }
        .id("swiftwebui-splash")
        .class("swiftwebui-splash")
    }

    static let splashCSS = """
        .swiftwebui-splash {
            position: fixed;
            inset: 0;
            z-index: 2147483647;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 16px;
            background: Canvas;
            color: CanvasText;
            color-scheme: light dark;
            font: 15px/1.4 system-ui, sans-serif;
            transition: opacity 240ms ease;
        }
        .swiftwebui-splash.is-done { opacity: 0; pointer-events: none; }
        .swiftwebui-splash-track {
            width: min(240px, 60vw);
            height: 4px;
            border-radius: 2px;
            overflow: hidden;
            background: color-mix(in srgb, CanvasText 14%, transparent);
        }
        .swiftwebui-splash-bar {
            width: 100%;
            height: 100%;
            background: currentColor;
            transform: scaleX(0);
            transform-origin: left;
            transition: transform 120ms linear;
        }
        .swiftwebui-splash.is-starting .swiftwebui-splash-bar {
            animation: swiftwebui-splash-pulse 1.2s ease-in-out infinite;
        }
        .swiftwebui-splash.is-failed .swiftwebui-splash-track { display: none; }
        .swiftwebui-splash-status { margin: 0; opacity: 0.7; text-align: center; padding: 0 24px; }
        .swiftwebui-splash-retry { font: inherit; padding: 8px 16px; cursor: pointer; }
        .swiftwebui-splash-retry[hidden] { display: none; }
        @keyframes swiftwebui-splash-pulse { 50% { opacity: 0.35; } }
        @media (prefers-reduced-motion: reduce) {
            .swiftwebui-splash, .swiftwebui-splash-bar { transition: none; }
            .swiftwebui-splash.is-starting .swiftwebui-splash-bar { animation: none; }
        }
        """

    /// Fetches the bundle, reports progress on the loading screen, and starts it.
    static let loader = #"""
        const meta = (name) => document.querySelector(`meta[name="${name}"]`)?.content;

        // Rooted rather than relative: a server that answers every unknown path
        // with this document would otherwise resolve `index.js` against a deep URL.
        const base = new URL(meta("swiftwebui-base") || "/", location.origin);
        const bundleURL = new URL(meta("swiftwebui-bundle"), base);
        const declaredBytes = Number(meta("swiftwebui-bundle-bytes")) || 0;

        const splash = document.getElementById("swiftwebui-splash");
        const bar = document.getElementById("swiftwebui-splash-bar");
        const status = document.getElementById("swiftwebui-splash-status");
        const retry = document.getElementById("swiftwebui-splash-retry");

        function setProgress(fraction) {
            bar.style.transform = `scaleX(${Math.min(Math.max(fraction, 0), 1)})`;
        }

        function starting() {
            setProgress(1);
            splash.classList.add("is-starting");
        }

        function dismiss() {
            splash.classList.remove("is-starting");
            splash.classList.add("is-done");
            const remove = () => splash.remove();
            splash.addEventListener("transitionend", remove, { once: true });
            // `transitionend` never fires under reduced motion or in a background tab.
            setTimeout(remove, 600);
        }

        function fail(error) {
            console.error("The application failed to start:", error);
            splash.classList.remove("is-starting");
            splash.classList.add("is-failed");
            status.textContent = "Loading failed. Check your connection and try again.";
            retry.hidden = false;
        }

        // The bundle as a response whose body is counted on the way past. The bytes
        // are handed on as they arrive, so compilation still overlaps the download.
        async function measuredBundle(url) {
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`${url} answered ${response.status}`);
            }
            if (!response.body || declaredBytes === 0) {
                starting();
                return response;
            }

            const reader = response.body.getReader();
            let loaded = 0;
            const counted = new ReadableStream({
                async pull(controller) {
                    const { done, value } = await reader.read();
                    if (done) {
                        starting();
                        controller.close();
                        return;
                    }
                    loaded += value.byteLength;
                    setProgress(loaded / declaredBytes);
                    controller.enqueue(value);
                },
                cancel(reason) {
                    return reader.cancel(reason);
                },
            // Unbounded, so the bar follows the network and not the compiler.
            }, new CountQueuingStrategy({ highWaterMark: Infinity }));

            // `instantiateStreaming` only accepts the WebAssembly media type.
            return new Response(counted, { headers: { "content-type": "application/wasm" } });
        }

        // Reloading rather than starting again: a second start would install a
        // second event loop over a half-built first one.
        retry.addEventListener("click", () => location.reload());

        // Started before the JavaScript is imported: the bundle is the long download.
        const bundle = measuredBundle(bundleURL);
        bundle.catch(() => {});

        try {
            const { init } = await import(new URL("index.js", base).href);
            // Resolves once `main()` has returned, which is after the first mount.
            await init({ module: bundle });
            dismiss();
        } catch (error) {
            fail(error);
        }
        """#
}
