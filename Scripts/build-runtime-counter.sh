#!/bin/bash
set -euo pipefail

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
example_directory="$repo_root/Examples/RuntimeCounter"
resources_directory="$example_directory/Resources"
vendor_directory="$example_directory/Vendor"
dist_directory="$example_directory/dist"
staging_directory="$example_directory/.dist-staging"
previous_directory="$example_directory/.dist-previous"
SWIFTPM_SCRATCH_PATH="${SWIFTWEBUI_RUNTIME_SCRATCH_PATH:-/private/tmp/swiftwebui-runtime-counter}"
build_tmp=$(mktemp -d "${TMPDIR:-/tmp}/swiftwebui-runtime-counter.XXXXXX")
PACKAGE_OUTPUT="$build_tmp/package"
previous_bundle_saved=0
replacement_started=0

cleanup() {
    rm -rf -- "$build_tmp" "$staging_directory"
    if [[ $previous_bundle_saved -eq 1 && -d "$previous_directory" ]]; then
        rm -rf -- "$dist_directory"
        mv "$previous_directory" "$dist_directory"
    elif [[ $replacement_started -eq 1 ]]; then
        rm -rf -- "$dist_directory"
    fi
    rm -rf -- "$previous_directory"
}
trap cleanup EXIT

rm -rf -- "$previous_directory"

cd "$repo_root"
rm -rf -- "$SWIFTPM_SCRATCH_PATH"
mkdir -p "$SWIFTPM_SCRATCH_PATH"

echo "Building RuntimeCounter with SwiftPM scratch path:"
echo "  $SWIFTPM_SCRATCH_PATH"

swiftly run swift package +6.3.3 \
    --scratch-path "$SWIFTPM_SCRATCH_PATH" \
    --swift-sdk swift-6.3.3-RELEASE_wasm \
    --allow-writing-to-package-directory \
    js -c release \
    --product SwiftWebUIRuntimeCounter \
    --output "$PACKAGE_OUTPUT"

rm -rf -- "$staging_directory"
mkdir -p "$staging_directory"
cp -R "$PACKAGE_OUTPUT/." "$staging_directory/"
# Resources are an application-owned directory tree. The validator rejects
# symlinks before this recursive copy so deployable paths cannot escape it.
cp -R "$resources_directory/." "$staging_directory/"
mkdir -p "$staging_directory/vendor"
cp -R "$vendor_directory/browser_wasi_shim" "$staging_directory/vendor/browser_wasi_shim"

"$script_directory/validate-runtime-counter.sh" "$staging_directory"

if [[ -d "$dist_directory" ]]; then
    mv "$dist_directory" "$previous_directory"
    previous_bundle_saved=1
fi
replacement_started=1
mv "$staging_directory" "$dist_directory"

"$script_directory/validate-runtime-counter.sh" "$dist_directory"
rm -rf -- "$previous_directory"
replacement_started=0

echo "RuntimeCounter browser bundle built at $dist_directory"
