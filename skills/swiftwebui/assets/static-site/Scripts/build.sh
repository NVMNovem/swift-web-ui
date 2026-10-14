#!/bin/bash
#
#  Renders every page to static HTML and assembles the deployable site in dist/.
#
set -euo pipefail

package_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$package_root"

swift run -c release Site \
    --output "$package_root/dist" \
    --resources "$package_root/Resources" \
    "$@"
