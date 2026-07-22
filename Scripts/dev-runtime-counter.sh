#!/bin/bash
set -uo pipefail

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
example_directory="$repo_root/Examples/RuntimeCounter"
host=${SWIFTWEBUI_RUNTIME_HOST:-127.0.0.1}
port=${SWIFTWEBUI_RUNTIME_PORT:-8080}
url="http://$host:$port/"
server_pid=""

cleanup() {
    if [[ -n "$server_pid" ]]; then
        kill "$server_pid" 2>/dev/null || true
        wait "$server_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT INT TERM

fingerprint() {
    {
        find \
            "$example_directory/Sources" \
            "$repo_root/Sources/SwiftWebUI" \
            "$repo_root/Sources/SwiftWebUIRuntime" \
            -type f -name '*.swift' -print
        find "$example_directory/Resources" -type f -print
        printf '%s\n' "$repo_root/Package.swift"
        if [[ -f "$repo_root/Package.resolved" ]]; then
            printf '%s\n' "$repo_root/Package.resolved"
        fi
    } | LC_ALL=C sort | while IFS= read -r path; do
        cksum "$path"
    done | cksum | awk '{ print $1 ":" $2 }'
}

"$script_directory/build-runtime-counter.sh" || exit $?

SWIFTWEBUI_RUNTIME_HOST="$host" SWIFTWEBUI_RUNTIME_PORT="$port" \
    "$script_directory/serve-runtime-counter.sh" &
server_pid=$!

ready=0
for _ in 1 2 3 4 5 6 7 8 9 10; do
    if curl --silent --fail --output /dev/null "${url}__swiftwebui_reload"; then
        ready=1
        break
    fi
    if ! kill -0 "$server_pid" 2>/dev/null; then
        wait "$server_pid"
        exit $?
    fi
    sleep 0.25
done

if [[ $ready -ne 1 ]]; then
    echo "RuntimeCounter server did not become ready at $url" >&2
    exit 1
fi

echo "Edit Examples/RuntimeCounter/Sources/RuntimeCounter.swift; successful rebuilds reload the browser."
echo "Browser URL: $url"

open_browser=${SWIFTWEBUI_OPEN_BROWSER:-auto}
if [[ $open_browser == 1 || ($open_browser == auto && $(uname -s) == Darwin) ]]; then
    open "$url"
fi

observed=$(fingerprint)
while kill -0 "$server_pid" 2>/dev/null; do
    sleep 1
    current=$(fingerprint)
    if [[ "$current" == "$observed" ]]; then
        continue
    fi

    observed=$current
    echo "RuntimeCounter source changed; rebuilding..."
    if "$script_directory/build-runtime-counter.sh"; then
        observed=$(fingerprint)
        echo "RuntimeCounter rebuilt; the browser will reload automatically."
    else
        echo "RuntimeCounter build failed; fix the error and save again." >&2
    fi
done

wait "$server_pid"
