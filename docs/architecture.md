# Architecture

The demonstrator is a complete Embedded Linux product image for the Raspberry Pi 4. The build is isolated in Docker; the device boots U-Boot, Linux, and a Qt 6 kiosk application.

## Build pipeline

```text
Developer Machine
      │
      │ Docker (Ubuntu 22.04)
      ▼
+-------------------------+
| kas                     |
| BitBake / OpenEmbedded  |
| poky + meta-oe          |
| meta-raspberrypi        |
| meta-qt6                |
| meta-embedded-linux-    |
|   demonstrator          |
+------------+------------+
             │
             ▼
   Raspberry Pi 4 image
   (wic + eldupdate)
```

`./scripts/build.sh` builds the container (if needed) and runs `kas build kas/raspberrypi4.yml`. The host never needs a native Yocto toolchain.

### Layers

| Layer | Role |
| --- | --- |
| `poky` | Distro base, BitBake, kernel/U-Boot recipes |
| `meta-openembedded` | Extra userspace (python, networking, multimedia) |
| `meta-raspberrypi` | Raspberry Pi 4 machine, firmware, U-Boot integration |
| `meta-qt6` | Qt 6.8 |
| `meta-embedded-linux-demonstrator` | Distro `eld`, image, UI, update agent, A/B WKS, boot script |

### Distro `eld`

Defined in `meta-embedded-linux-demonstrator/conf/distro/eld.conf`:

* systemd as PID 1
* hostname `raspi-demo`
* `DISTRO_VERSION` written to `/etc/image-version` (shown in the UI)
* SDK extras for CMake and Qt

## Runtime software stack

```text
+---------------------------------------------+
| Qt 6 QML UI  (embedded-linux-ui.service)    |
|   eglfs on DRM/KMS (HDMI or official 7" DSI)|
+---------------------------------------------+
| Update agent  (UNIX socket /run/eld-update.sock)
+---------------------------------------------+
| systemd  ·  networkd  ·  sshd  ·  gdbserver |
+---------------------------------------------+
| Linux kernel (shared FAT /boot)             |
+---------------------------------------------+
| U-Boot  (loaded by Raspberry Pi firmware)   |
+---------------------------------------------+
```

The UI starts at boot via systemd, not a desktop session. It reads live data from `/proc`, `/etc/os-release`, `/etc/image-version`, and the network interfaces.

## Storage layout

SD card partitions produced by `wic/embedded-linux-demo.wks`:

```text
mmcblk0p1  boot       FAT    firmware, U-Boot, kernel, DTB, uboot.env
mmcblk0p2  rootfs_a   ext4   slot A (first boot)
mmcblk0p3  rootfs_b   ext4   slot B (written by an update)
mmcblk0p4  data       ext4   /data  (update bundles, persistent files)
```

U-Boot environment variables in `/boot/uboot.env`:

```text
active_slot=A|B
upgrade_available=0|1
bootcount=0
bootlimit=3
```

Linux selects the running slot from the kernel command line (`root=/dev/mmcblk0p2` or `p3`, plus `eld.slot=`). `fw_printenv` / `fw_setenv` (`libubootenv`) change the next boot target from userspace.

## Application vs platform development

```text
Platform (image, kernel, partitions, services)
    └── kas / BitBake  →  ./scripts/build.sh

Application (Qt UI)
    └── Yocto SDK / CMake  →  ./scripts/build-sdk.sh
                           →  ./scripts/deploy-app.sh
```

The same application sources in `application/embedded-linux-ui` are compiled into the image through `externalsrc` and can be rebuilt with the SDK for a fast SSH deploy.

## Simplifications (documented limitations)

* The **kernel and device tree live on the shared FAT boot partition**, not inside each rootfs slot. An A/B update replaces the root filesystem only. A kernel change still requires updating `/boot` (or a full SD re-flash). Official 7" DSI uses `dtoverlay=vc4-kms-dsi-7inch` plus `kernel-modules`. Do not enable `display_auto_detect` as well — firmware then loads a second v2 overlay and `vc4` never creates `/dev/dri`.
* Update bundles are **not signed**. Integrity is a SHA-256 of the rootfs tarball inside the bundle.
* `debug-tweaks` leaves an empty root password and SSH enabled.

These match the PRD: the A/B architecture is in place, and rollback of the root filesystem works, while kernel-level A/B and signed payloads are listed as later extensions.
