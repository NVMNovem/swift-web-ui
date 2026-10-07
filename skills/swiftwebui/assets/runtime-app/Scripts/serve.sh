#!/bin/bash
#
#  Serves the built dist/ at http://127.0.0.1:8080/. A WebAssembly bundle has to
#  be fetched over HTTP; opening dist/index.html from disk does not work.
#
set -euo pipefail

package_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
port=${PORT:-8080}

if [[ ! -f "$package_root/dist/index.html" ]]; then
    echo "No bundle found. Run Scripts/build.sh first." >&2
    exit 1
fi

echo "Serving http://127.0.0.1:$port/"
exec python3 -m http.server "$port" --bind 127.0.0.1 --directory "$package_root/dist"
