#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_SRC="${ROOT}/application/embedded-linux-ui"
TARGET="${1:-root@raspi-demo}"
BUILD_DIR="${APP_SRC}/build-target"

if [[ -z "${OECORE_NATIVE_SYSROOT:-}" ]]; then
    echo "Source the Yocto SDK first, for example:"
    echo "  source /opt/eld-sdk/*/environment-setup-cortexa72-poky-linux"
    echo "then re-run: $0 [user@host]"
    exit 1
fi

cmake -S "$APP_SRC" -B "$BUILD_DIR" -DAPP_VERSION="${APP_VERSION:-1.0.0}"
cmake --build "$BUILD_DIR" -j"$(nproc)"

BIN="${BUILD_DIR}/embedded-linux-ui"
if [[ ! -x "$BIN" ]]; then
    echo "Expected binary not found: $BIN" >&2
    exit 1
fi

echo "Deploying ${BIN} to ${TARGET}:/usr/bin/embedded-linux-ui"
rsync -az "$BIN" "${TARGET}:/usr/bin/embedded-linux-ui"
ssh "$TARGET" "systemctl restart embedded-linux-ui"

echo "Deployed. Remote debug: see docs/remote-debugging.md"
