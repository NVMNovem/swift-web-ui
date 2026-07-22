#!/bin/bash
set -euo pipefail

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
dist_directory="$repo_root/Examples/RuntimeCounter/dist"
resources_directory="$repo_root/Examples/RuntimeCounter/Resources"
check_tmp=$(mktemp -d "${TMPDIR:-/tmp}/swiftwebui-runtime-counter-check.XXXXXX")

cleanup() {
    rm -rf -- "$check_tmp"
}
trap cleanup EXIT

write_manifest() {
    local destination=$1
    (
        cd "$dist_directory"
        find . -type f -print | LC_ALL=C sort
        while IFS= read -r resource_file; do
            relative_path=${resource_file#"$resources_directory/"}
            shasum -a 256 "$relative_path"
        done < <(find "$resources_directory" -type f -print | LC_ALL=C sort)
    ) > "$destination"
}

"$script_directory/build-runtime-counter.sh"
write_manifest "$check_tmp/first-files.txt"

"$script_directory/build-runtime-counter.sh"
write_manifest "$check_tmp/second-files.txt"

if ! cmp -s "$check_tmp/first-files.txt" "$check_tmp/second-files.txt"; then
    echo "RuntimeCounter resource manifest changed between consecutive builds:" >&2
    diff -u "$check_tmp/first-files.txt" "$check_tmp/second-files.txt" >&2 || true
    exit 1
fi

"$script_directory/validate-runtime-counter.sh"

missing_resource_dist="$check_tmp/missing-resource-dist"
cp -R "$dist_directory" "$missing_resource_dist"
rm -- "$missing_resource_dist/assets/runtime-fixture.svg"
if "$script_directory/validate-runtime-counter.sh" "$missing_resource_dist" \
    >"$check_tmp/missing-resource.stdout" 2>"$check_tmp/missing-resource.stderr"; then
    echo "RuntimeCounter validation unexpectedly accepted a missing nested resource." >&2
    exit 1
fi
if ! grep -Fq 'Missing generated RuntimeCounter resource: assets/runtime-fixture.svg' \
    "$check_tmp/missing-resource.stderr"; then
    echo "RuntimeCounter validation did not report the precise missing resource path." >&2
    cat "$check_tmp/missing-resource.stderr" >&2
    exit 1
fi

if ! git -C "$repo_root" check-ignore -q Examples/RuntimeCounter/dist; then
    echo "Examples/RuntimeCounter/dist must remain ignored by Git." >&2
    exit 1
fi

echo "RuntimeCounter reproducibility validation passed"
