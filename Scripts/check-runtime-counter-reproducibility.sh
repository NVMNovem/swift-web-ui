#!/bin/bash
set -euo pipefail

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
dist_directory="$repo_root/Examples/RuntimeCounter/dist"
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
    ) > "$destination"
}

"$script_directory/build-runtime-counter.sh"
write_manifest "$check_tmp/first-files.txt"

"$script_directory/build-runtime-counter.sh"
write_manifest "$check_tmp/second-files.txt"

if ! cmp -s "$check_tmp/first-files.txt" "$check_tmp/second-files.txt"; then
    echo "RuntimeCounter file list changed between consecutive builds:" >&2
    diff -u "$check_tmp/first-files.txt" "$check_tmp/second-files.txt" >&2 || true
    exit 1
fi

"$script_directory/validate-runtime-counter.sh"
echo "RuntimeCounter reproducibility validation passed"
