#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACHINE="${MACHINE:-raspberrypi4-64}"
IMAGE_NAME="${IMAGE_NAME:-embedded-linux-demo-image}"
DEPLOY="${ROOT}/build/tmp/deploy/images/${MACHINE}"

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <block-device>"
    echo "Example: $0 /dev/sdX"
    echo
    echo "WARNING: this overwrites the entire device."
    exit 1
fi

DEVICE="$1"

if [[ ! -b "$DEVICE" ]]; then
    echo "Not a block device: $DEVICE" >&2
    exit 1
fi

WIC=""
for candidate in \
    "${DEPLOY}/${IMAGE_NAME}-${MACHINE}.rootfs.wic" \
    "${DEPLOY}/${IMAGE_NAME}-${MACHINE}.wic" \
    "${DEPLOY}/${IMAGE_NAME}-${MACHINE}.rootfs.wic.bz2" \
    "${DEPLOY}/${IMAGE_NAME}-${MACHINE}.wic.bz2"
do
    if [[ -f "$candidate" ]]; then
        WIC="$candidate"
        break
    fi
done

if [[ -z "$WIC" ]]; then
    echo "No .wic image found in ${DEPLOY}" >&2
    echo "Build the image first with ./scripts/build.sh" >&2
    exit 1
fi

echo "Flashing ${WIC} -> ${DEVICE}"
echo "This will erase all data on ${DEVICE}."
read -r -p "Type YES to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
    echo "Aborted."
    exit 1
fi

BMAP="${WIC%.bz2}.bmap"
if [[ "$WIC" == *.bz2 ]]; then
    BMAP="${WIC%.wic.bz2}.wic.bmap"
fi
if [[ ! -f "$BMAP" ]]; then
    BMAP="${WIC}.bmap"
fi

if command -v bmaptool >/dev/null 2>&1 && [[ -f "$BMAP" ]]; then
    sudo bmaptool copy "$WIC" "$DEVICE"
elif [[ "$WIC" == *.bz2 ]]; then
    bunzip2 -c "$WIC" | sudo dd of="$DEVICE" bs=4M status=progress conv=fsync
else
    sudo dd if="$WIC" of="$DEVICE" bs=4M status=progress conv=fsync
fi

sudo sync
echo "Flash complete. Insert the SD card into the Raspberry Pi and power on."
