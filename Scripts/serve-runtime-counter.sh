#!/bin/bash
set -euo pipefail

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_directory/.." && pwd)
dist_directory="$repo_root/Examples/RuntimeCounter/dist"
host=${SWIFTWEBUI_RUNTIME_HOST:-127.0.0.1}
port=${SWIFTWEBUI_RUNTIME_PORT:-8080}

"$script_directory/validate-runtime-counter.sh" "$dist_directory"

echo "RuntimeCounter is available at http://$host:$port/"
exec python3 - "$dist_directory" "$host" "$port" <<'PY'
import http.server
import pathlib
import sys

root = pathlib.Path(sys.argv[1]).resolve()
host = sys.argv[2]
port = int(sys.argv[3])

reload_client = b"""
<script>
(() => {
    let revision;
    const poll = async () => {
        try {
            const response = await fetch("/__swiftwebui_reload", { cache: "no-store" });
            const nextRevision = await response.text();
            if (revision === undefined) {
                revision = nextRevision;
            } else if (nextRevision !== revision) {
                window.location.reload();
                return;
            }
        } catch (_) {
            // A rebuild can briefly replace the output directory. Keep polling.
        }
        window.setTimeout(poll, 500);
    };
    poll();
})();
</script>
"""


class RuntimeCounterHandler(http.server.SimpleHTTPRequestHandler):
    latest_revision = "unbuilt"

    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(root), **kwargs)

    @classmethod
    def revision(cls):
        required = (root / "index.html", root / "SwiftWebUIRuntimeCounter.wasm")
        try:
            stats = [path.stat() for path in required]
        except FileNotFoundError:
            return cls.latest_revision
        cls.latest_revision = ":".join(
            f"{stat.st_mtime_ns}-{stat.st_size}" for stat in stats
        )
        return cls.latest_revision

    def do_GET(self):
        if self.path.split("?", 1)[0] == "/__swiftwebui_reload":
            body = self.revision().encode("ascii")
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        if self.path.split("?", 1)[0] in ("/", "/index.html"):
            source = (root / "index.html").read_bytes()
            marker = b"</body>"
            body = source.replace(marker, reload_client + marker, 1)
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return

        super().do_GET()

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


server = http.server.ThreadingHTTPServer((host, port), RuntimeCounterHandler)
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
PY
