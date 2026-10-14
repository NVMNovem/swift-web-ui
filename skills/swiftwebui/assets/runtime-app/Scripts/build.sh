#!/bin/bash
#
#  Builds the App WebAssembly bundle and assembles the deployable output in dist/.
#
#  Environment:
#    SWIFT_SDK       WebAssembly Swift SDK (default: swift-6.3.3-RELEASE_wasm)
#    CONFIGURATION   debug or release (default: release)
#    HOST_SDK        macOS SDK for host-side manifest compilation, when the
#                    toolchain is older than the installed Xcode's SDK
#
set -euo pipefail

package_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
product=App
swift_sdk=${SWIFT_SDK:-swift-6.3.3-RELEASE_wasm}
configuration=${CONFIGURATION:-release}
shim_version=0.3.0

cd "$package_root"

# The compiler has to match the SDK's precompiled modules exactly. When the
# active `swift` is a different version, run the matching one through swiftly.
swift_command=(swift)
if [[ "$swift_sdk" =~ ^swift-([0-9]+\.[0-9]+\.[0-9]+)-RELEASE_wasm ]]; then
    wanted=${BASH_REMATCH[1]}
    active=$(swift --version 2>&1 | sed -nE 's/.*Swift version ([^ ]+).*/\1/p' | head -n 1)
    if [[ "$active" != "$wanted" ]]; then
        if ! command -v swiftly >/dev/null 2>&1; then
            echo "error: SDK $swift_sdk needs Swift $wanted, but 'swift' is ${active:-unknown}." >&2
            echo "       Install swiftly and run: swiftly install $wanted" >&2
            exit 1
        fi
        swift_command=(swiftly run swift "+$wanted")
    fi
fi

if ! "${swift_command[@]}" sdk list 2>/dev/null | grep -qx "$swift_sdk"; then
    echo "error: Swift SDK $swift_sdk is not installed." >&2
    echo "       See https://www.swift.org/documentation/articles/wasm-getting-started.html" >&2
    exit 1
fi

if [[ -n "${HOST_SDK:-}" ]]; then
    export SDKROOT=$HOST_SDK
fi

staging=$(mktemp -d "${TMPDIR:-/tmp}/app-build.XXXXXX")
trap 'rm -rf -- "$staging"' EXIT

# JavaScriptKit's `js` plugin links the bundle and writes it with its loader
# (index.js, instantiate.js, runtime.js) into the output directory.
"${swift_command[@]}" package \
    --swift-sdk "$swift_sdk" \
    --allow-writing-to-package-directory \
    js -c "$configuration" \
    --product "$product" \
    --output "$staging"

# Resources are copied as they are: the runtime never reads the filesystem, so
# every stylesheet, image and font a view names has to be put here by the build.
cp -R "$package_root/Resources/." "$staging/"

# The WASI shim the loader imports, kept in Vendor/ so a build needs no network
# after the first one. Commit Vendor/ to pin it.
vendor="$package_root/Vendor/browser_wasi_shim"
if [[ ! -f "$vendor/dist/index.js" ]]; then
    mkdir -p "$vendor"
    (cd "$staging" && npm pack --silent "@bjorn3/browser_wasi_shim@$shim_version" >/dev/null)
    tar -xzf "$staging"/bjorn3-browser_wasi_shim-*.tgz -C "$vendor" --strip-components=1
    rm -f "$staging"/bjorn3-browser_wasi_shim-*.tgz
fi
mkdir -p "$staging/vendor"
cp -R "$vendor" "$staging/vendor/browser_wasi_shim"

rm -rf -- "$package_root/dist"
mv "$staging" "$package_root/dist"

bundle="$package_root/dist/$product.wasm"
raw=$(wc -c < "$bundle" | tr -d ' ')
gzipped=$(gzip -6 -c "$bundle" | wc -c | tr -d ' ')
echo "Built dist/ — $product.wasm is $((raw / 1024)) KiB raw, $((gzipped / 1024)) KiB gzipped"
