#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACHINE="${MACHINE:-raspberrypi4-64}"
IMAGE_NAME="${IMAGE_NAME:-embedded-linux-demo-image}"
DEPLOY="${ROOT}/build/tmp/deploy/images/${MACHINE}"
DEST="${1:-${ROOT}/build/tmp/deploy/images/${MACHINE}}"

BUNDLE=""
for candidate in \
    "${DEPLOY}/${IMAGE_NAME}-${MACHINE}.rootfs.eldupdate" \
    "${DEPLOY}/${IMAGE_NAME}-${MACHINE}.eldupdate"
do
    if [[ -f "$candidate" ]]; then
        BUNDLE="$candidate"
        break
    fi
done

if [[ -z "$BUNDLE" ]]; then
    echo "No .eldupdate bundle found in ${DEPLOY}" >&2
    echo "Build the image first with ./scripts/build.sh" >&2
    exit 1
fi

mkdir -p "$DEST"
cp -v "$BUNDLE" "$DEST/"
echo
echo "Copy this file to the device as /data/updates/$(basename "$BUNDLE")"
echo "  scp \"$BUNDLE\" root@raspi-demo:/data/updates/"
