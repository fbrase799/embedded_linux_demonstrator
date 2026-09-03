#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export USER_ID
export GROUP_ID
USER_ID="$(id -u)"
GROUP_ID="$(id -g)"

mkdir -p build/tmp/deploy

compose() {
    local -a files=(-f docker/compose.yml)
    if [[ "$(uname -s)" == "Darwin" ]]; then
        files+=(-f docker/compose.macos.yml)
    fi
    docker compose "${files[@]}" "$@"
}

MEM_GIB="$(awk '/MemTotal/ {printf "%.0f", $2/1024/1024}' /proc/meminfo 2>/dev/null || echo 0)"
if [[ "${MEM_GIB}" -gt 0 && "${MEM_GIB}" -lt 8 ]]; then
    echo "WARNING: only ~${MEM_GIB} GiB RAM visible (need ≥16 GiB for a reliable Yocto build)." >&2
    echo "On WSL2, set memory=16GB in %UserProfile%\\.wslconfig, then run: wsl --shutdown" >&2
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macOS: using a case-sensitive Docker volume for Yocto TMPDIR."
fi

echo "Building Docker image (Ubuntu 22.04 + kas)..."
compose build

echo "Starting Yocto build via kas..."
compose run --rm yocto \
    kas build kas/raspberrypi4.yml

echo
echo "Build complete. Image artifacts:"
echo "  build/tmp/deploy/images/raspberrypi4-64/"
echo
echo "Flash with:  ./scripts/flash.sh /dev/sdX"
