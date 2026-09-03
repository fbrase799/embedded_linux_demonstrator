#!/bin/bash
set -euo pipefail

# Named volumes are created as root; BitBake runs as the unprivileged builder.
fix_owner() {
    local dir="$1"
    if [[ -d "$dir" && ! -w "$dir" ]]; then
        sudo chown "$(id -u):$(id -g)" "$dir"
    fi
}

fix_owner /work/build/tmp
fix_owner /work/build/tmp/deploy

exec "$@"
