# Embedded Linux Demonstrator

Reproducible Embedded Linux system for the **Raspberry Pi 4**: Yocto (kas) in Docker, a Qt 6 kiosk UI, U-Boot A/B root filesystem updates, and remote debugging.

The product requirement document is [PRD.md](PRD.md). Architecture and workflow details are in [docs/](docs/).

## What you get

```text
Developer Machine
      │  Docker (Ubuntu 22.04 + kas)
      ▼
Yocto image  ──flash──►  Raspberry Pi 4
                         U-Boot + Linux + Qt UI
```

After boot, the device starts the Qt application automatically. The UI shows live system information and can install a software update into the inactive A/B slot.

## Requirements

* Docker and Docker Compose v2
* About 80 GB free disk space and **at least 16 GB RAM** for a Yocto build (8 GB often fails while linking `gcc-cross`)
* Raspberry Pi 4, HDMI display, Ethernet, SD card (16 GB or larger)

The host does not need a native Yocto or Qt installation. The build container is based on **Ubuntu 22.04** as required by the PRD.

### macOS

macOS APFS is case-insensitive. BitBake rejects `TMPDIR` on that filesystem, so `./scripts/build.sh` keeps Yocto's `tmp/` in a Docker named volume and bind-mounts only `build/tmp/deploy/` back to the host (images, SDK, update bundles). Give Docker Desktop at least **100 GB** disk; the named volume lives inside Docker's VM, not in the repo.

Manual kas invocations on a Mac must include the overlay:

```bash
mkdir -p build/tmp/deploy
docker compose -f docker/compose.yml -f docker/compose.macos.yml run --rm yocto \
    kas build kas/raspberrypi4.yml
```

### WSL2 memory

WSL2 often defaults to a small VM. If `free -h` shows only a few gigabytes, raise it before building. Create or edit `%UserProfile%\.wslconfig` on Windows:

```ini
[wsl2]
memory=16GB
swap=8GB
processors=4
```

Then from PowerShell: `wsl --shutdown`, reopen WSL, and confirm with `free -h`.

If `gcc-cross` fails with thousands of `undefined reference to gen_split_…` errors, the compile was almost certainly OOM-killed (look for 0-byte `insn-*.o` files). Clean and rebuild after increasing RAM:

```bash
docker compose -f docker/compose.yml run --rm yocto \
    kas shell kas/raspberrypi4.yml -c 'bitbake -c cleansstate gcc-cross-aarch64'
./scripts/build.sh
```

On macOS, add `-f docker/compose.macos.yml` to that `docker compose` command.

## Quick start

```bash
./scripts/build.sh
./scripts/flash.sh /dev/sdX
```

`flash.sh` asks you to type `YES` before it overwrites the card. Use the SD card device, not a partition (`/dev/sdb`, not `/dev/sdb1`).

On macOS, `flash.sh` is not used (`dd` option syntax differs, and the card must be unmounted first). Identify the whole disk with `diskutil list` (look for `external, physical`, typically `/dev/disk4` — never the internal SSD):

```bash
diskutil list
diskutil unmountDisk /dev/disk4
sudo dd if=build/tmp/deploy/images/raspberrypi4-64/embedded-linux-demo-image-raspberrypi4-64.rootfs.wic \
    of=/dev/rdisk4 bs=4m status=progress
sync
```

`/dev/rdisk4` is the raw device for the same card as `/dev/disk4` and writes faster. Confirm the identifier before running `dd`.

Equivalent manual build (on macOS, add `-f docker/compose.macos.yml` as in the macOS section above):

```bash
docker compose -f docker/compose.yml run --rm yocto \
    kas build kas/raspberrypi4.yml
```

Artifacts land in `build/tmp/deploy/images/raspberrypi4-64/`:

| File | Purpose |
| --- | --- |
| `*.wic` / `*.wic.bmap` | Bootable SD card image |
| `*.tar.gz` | Root filesystem archive |
| `*.eldupdate` | A/B software-update bundle for the Qt UI |

## Demonstration flow

1. **Build** the image with `./scripts/build.sh`.
2. **Flash** and boot. The Qt UI starts on HDMI without logging in.
3. **Device UI** shows hostname, kernel, Yocto release, application version, uptime, IP address, and current image version.
4. **Remote debug** from the developer machine — see [docs/remote-debugging.md](docs/remote-debugging.md).
5. **Software update**: bump `DISTRO_VERSION` in `meta-embedded-linux-demonstrator/conf/distro/eld.conf` to `1.1.0`, rebuild, copy the `.eldupdate` file to `/data/updates` on the device, and install it from the UI.
6. **Reboot**. U-Boot selects the newly written slot.
7. **Verify** that the UI shows software version `1.1.0`. A successful UI start confirms the boot and clears the U-Boot boot counter.

## Application development without a full image rebuild

```bash
./scripts/build-sdk.sh
sudo ./build/tmp/deploy/sdk/*.sh -d /opt/eld-sdk
source /opt/eld-sdk/*/environment-setup-cortexa72-poky-linux
./scripts/deploy-app.sh root@<pi-ip>
```

The device image includes `gdbserver` and SSH (`root` with an empty password while `debug-tweaks` is enabled). That is for the demonstrator only; do not ship it as a product image.

## Repository layout

```text
docker/                 Ubuntu 22.04 image and Compose file for kas/Yocto
kas/raspberrypi4.yml    Layer revisions and machine configuration
meta-embedded-linux-demonstrator/
application/embedded-linux-ui/   Qt 6 QML application (CMake)
scripts/                build, flash, SDK, deploy helpers
docs/                   architecture, updates, remote debugging
```

Yocto series: **Scarthgap (5.0 LTS)** with Qt 6.8 (`meta-qt6` from [code.qt.io](https://code.qt.io/cgit/yocto/meta-qt6.git/)), `meta-raspberrypi`, and a custom distro `eld`.

## Documentation

* [Architecture](docs/architecture.md)
* [Software updates and A/B rollback](docs/update.md)
* [Remote debugging](docs/remote-debugging.md)

## License

MIT. See [LICENSE](LICENSE).
