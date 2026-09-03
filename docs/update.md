# Software updates

The demonstrator uses a dual-rootfs A/B scheme with U-Boot selecting the active slot.

## Slot selection

```text
SD Card
+----------------------+
| Boot / U-Boot / kernel |
+----------------------+
| RootFS A   (p2)      |
+----------------------+
| RootFS B   (p3)      |
+----------------------+
| Persistent /data     |
+----------------------+
```

If slot A is running, an update is installed onto slot B. After a successful write, the agent sets:

```text
active_slot=B
upgrade_available=1
bootcount=0
```

U-Boot then boots `/dev/mmcblk0p3`. When the Qt UI starts, it calls `confirm_boot`, which sets `upgrade_available=0` and `bootcount=0`. That marks the new slot as the stable system.

## Rollback

U-Boot is configured with `CONFIG_BOOTCOUNT_LIMIT` and `CONFIG_BOOTCOUNT_ENV`.

While `upgrade_available=1`, each boot increments `bootcount`. If `bootcount` exceeds `bootlimit` (default 3) before Linux confirms the boot, U-Boot runs `altbootcmd`, which swaps `active_slot` back and clears the upgrade flags.

If the UI never starts (kernel panic, broken graphics, crash before `confirmBoot()`), the device returns to the previous rootfs on its own.

The initial implementation does **not** restore a previous kernel on `/boot`. Rollback applies to the root filesystem only. See [architecture.md](architecture.md).

## Update bundle format (`.eldupdate`)

A gzip-compressed tar with:

```text
manifest.json
rootfs.tar.gz
```

`manifest.json`:

```json
{
  "name": "embedded-linux-demo",
  "version": "1.1.0",
  "compatible": "raspberrypi4-64",
  "rootfs_sha256": "<sha256 of rootfs.tar.gz>",
  "format": 1
}
```

Yocto produces this file automatically (`IMAGE_FSTYPES` includes `eldupdate`). Copy it to the device:

```bash
./scripts/package-update.sh
scp build/tmp/deploy/images/raspberrypi4-64/*.eldupdate root@raspi-demo:/data/updates/
```

On the device you can also run:

```bash
eld-update-agent list
eld-update-agent install /data/updates/<file>.eldupdate
```

The Qt **Software Update** screen talks to the same agent over `/run/eld-update.sock`.

## Building version 1.1.0

1. Set `DISTRO_VERSION = "1.1.0"` in `meta-embedded-linux-demonstrator/conf/distro/eld.conf`.
2. Run `./scripts/build.sh`.
3. Copy the new `.eldupdate` to `/data/updates` (USB storage under `/media` is also scanned).
4. On the UI: Software Update → select the image → Install Update → Reboot Device.
5. After reboot the UI should show **Current Image: 1.1.0**.

Do not flash the new `.wic` over the running card if you want to demonstrate A/B; flashing replaces both slots' container. The update path writes only the inactive partition.

## Failure handling

| Situation | Result |
| --- | --- |
| Bad checksum or wrong machine | Install aborted; running slot unchanged |
| Power loss during `tar` extract | Inactive slot is incomplete; next boot still uses the old slot |
| New slot fails to start the UI | Bootcount hits the limit; U-Boot rolls back |
| Update agent not running | UI shows desktop/simulation mode and will not write partitions |

## Optional later work

The PRD lists signed bundles, RAUC/SWUpdate, HTTPS OTA, and read-only rootfs as extensions. The socket protocol and `.eldupdate` layout are small enough to replace with RAUC later without changing the Qt screens much.
