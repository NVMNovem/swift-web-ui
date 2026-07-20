#!/bin/bash
set -euo pipefail

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
example_directory="$repo_root/Examples/RuntimeCounter"
source_html="$example_directory/Resources/index.html"
dist_directory=${1:-"$example_directory/dist"}
dist_html="$dist_directory/index.html"

test -d "$example_directory/Resources"
test -d "$example_directory/Vendor/browser_wasi_shim"

if [[ ! -d "$dist_directory" ]]; then
    echo "RuntimeCounter output directory does not exist: $dist_directory" >&2
    exit 1
fi

duplicates=""
while IFS= read -r -d '' candidate; do
    basename=${candidate##*/}
    if [[ $basename =~ \ (copy|[2-9][0-9]*)(\..*)?$ ]]; then
        duplicates+="$candidate"$'\n'
    fi
done < <(find "$dist_directory" -type f -print0)

if [[ -n "$duplicates" ]]; then
    echo "Unexpected duplicate-suffixed files found in $dist_directory:" >&2
    printf '%s' "$duplicates" >&2
    exit 1
fi

require_unique_root_file() {
    local filename=$1
    local count
    count=$(find "$dist_directory" -maxdepth 1 -type f -name "$filename" -print | wc -l | tr -d '[:space:]')
    if [[ $count -ne 1 ]]; then
        echo "Expected exactly one $filename in $dist_directory; found $count." >&2
        exit 1
    fi
}

for canonical_root_file in \
    index.html \
    index.js \
    index.d.ts \
    instantiate.js \
    instantiate.d.ts \
    runtime.js \
    runtime.d.ts \
    package.json \
    SwiftWebUIRuntimeCounter.wasm
do
    require_unique_root_file "$canonical_root_file"
done

test -d "$dist_directory/platforms"
test -d "$dist_directory/vendor"

for required_file in \
    "$dist_html" \
    "$dist_directory/index.js" \
    "$dist_directory/SwiftWebUIRuntimeCounter.wasm" \
    "$dist_directory/vendor/browser_wasi_shim/index.js" \
    "$dist_directory/vendor/browser_wasi_shim/package.json"
do
    test -f "$required_file"
done

grep -Fq 'import { init } from "./index.js";' "$source_html"
grep -Fq 'await init();' "$source_html"
if grep -Eq 'import[[:space:]]*\{[[:space:]]*main[[:space:]]*\}|await[[:space:]]+main\(' "$source_html"; then
    echo "RuntimeCounter HTML must initialize PackageToJS through init(), not main()." >&2
    exit 1
fi
if grep -Eq 'instantiate[[:space:]]*\(' "$source_html"; then
    echo "RuntimeCounter HTML must not call instantiate() directly." >&2
    exit 1
fi

cmp -s "$source_html" "$dist_html"
grep -Fq 'export async function init(options)' "$dist_directory/index.js"
grep -Fq '"@bjorn3/browser_wasi_shim": "0.3.0"' "$dist_directory/package.json"
grep -Fq '"version": "0.3.0"' "$dist_directory/vendor/browser_wasi_shim/package.json"
grep -Fq '"@bjorn3/browser_wasi_shim": "./vendor/browser_wasi_shim/index.js"' "$dist_html"

bare_imports=$(rg --no-heading --line-number "from[[:space:]]*['\"]@|import[[:space:]]*['\"]@" "$dist_directory" -g '*.js' || true)
if [[ -n "$bare_imports" ]] && grep -Fv '@bjorn3/browser_wasi_shim' <<<"$bare_imports" >/dev/null; then
    echo "Unexpected unresolved bare JavaScript import:" >&2
    grep -Fv '@bjorn3/browser_wasi_shim' <<<"$bare_imports" >&2
    exit 1
fi

grep -Fq '"-Xclang-linker", "-mexec-model=reactor"' "$repo_root/Package.swift"
grep -Fq '"-Xlinker", "--export-if-defined=__main_argc_argv"' "$repo_root/Package.swift"

echo "RuntimeCounter packaging validation passed"
