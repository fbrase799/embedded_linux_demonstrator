# Tasks

Living backlog for [PRD.md](PRD.md). Implementation for Prompt-03 is in tree. QEMU FIT boot and U-Boot GDB still need a first `./scripts/build.sh qemuarm64` to prove on this machine.

Status:

* `[x]` done in tree
* `[ ]` not done
* `[~]` started; remaining work listed underneath

---

## Milestone 1 – Yocto base system

- [x] Docker build environment (Ubuntu 22.04, kas, Compose)
- [x] Docker on **Mac** and **WSL** ([PRD §1 req. 7](PRD.md), §4)
  - [x] `docker/compose.yml` for kas/Yocto
  - [x] macOS overlay `docker/compose.macos.yml` (case-insensitive APFS / named `tmp` volume)
  - [x] `./scripts/build.sh` applies the macOS overlay on Darwin
  - [x] README: Docker Desktop disk size on Mac; WSL2 memory (`~/.wslconfig`, 16 GB)
  - [x] `./scripts/build.sh` documented as the WSL path
  - [x] `./scripts/flash.sh` supports Linux/WSL (`/dev/sdX`) and macOS (`/dev/diskN`)
- [x] kas configuration for Raspberry Pi 4 (`kas/raspberrypi4.yml`)
- [x] kas configuration for QEMU ARM64 (`kas/qemuarm64.yml`, `kas/common.yml`)
- [x] custom distro `eld` and image `embedded-linux-demo-image`
- [x] bootable Raspberry Pi 4 image (`.wic`)
- [x] official 7-inch DSI as the product display
  - [x] Pi OS–aligned `config.txt` (`display_auto_detect`, `vc4-kms-v3d`, `disable_fw_kms_setup`)
  - [x] panel compatible overlay (`eld-dsi-panel`)
  - [x] `kernel-modules` / early DSI modules so vc4 binds
  - [x] eglfs on the vc4 KMS card (start script rewrites `/run/embedded-linux-ui-kms.json`)
  - [x] landscape via QML when the window is 720×1280 (no kernel `rotate=`, so Goodix axes stay 1:1)
  - [x] touch maps through the QML 90° item (do not set `QT_QPA_EGLFS_ROTATION`)
- [x] QEMU ARM64 image recipe/kas (ext4 + U-Boot; first emulator boot not run in this change)
- [x] `./scripts/build.sh qemuarm64` builds the QEMU machine
- [x] hostname `raspi-demo` (`hostname:pn-base-files` in `eld.conf`)

## Milestone 2 – Qt integration

- [x] Qt 6 in the image (`meta-qt6`)
- [x] in-tree QML sample (`application/embedded-linux-ui`)
- [x] BitBake recipe with `externalsrc`
- [x] systemd kiosk service, auto-start after boot
- [x] live system info (hostname, kernel, Yocto, app version, uptime, IP, image version, slot)

## Milestone 3 – Development workflow

- [x] Yocto SDK (`./scripts/build-sdk.sh`)
- [x] CMake cross-compile of the sample app
- [x] SSH deploy (`./scripts/deploy-app.sh`)
- [x] `gdbserver` on the image
- [x] documented Qt remote debug ([docs/remote-debugging.md](docs/remote-debugging.md))

## Milestone 4 – U-Boot

- [x] U-Boot as bootloader
- [x] documented environment (`active_slot`, `upgrade_available`, `bootcount`, `bootlimit`)
- [x] boot script selects rootfs A or B
- [x] U-Boot GDB path on QEMU (`./scripts/debug-uboot-qemu.sh`, `u-boot.elf`, [docs/uboot-debug.md](docs/uboot-debug.md))
- [x] documented U-Boot debug session (attach, break, continue)
- [ ] optional: hardware debug probe on Pi 4 (not required for done)

## Milestone 5 – Software update

- [x] Software Update screen in the sample UI
- [x] `.eldupdate` image type and update agent
- [x] install into the inactive A/B slot
- [x] reboot into the updated rootfs
- [x] current image version visible in the UI
- [x] `/data` partition ~3 GiB (`embedded-linux-demo.wks`)
- [x] documented: A/B updates replace rootfs only ([docs/update.md](docs/update.md))

## Milestone 6 – Robust update

- [x] boot success confirmation from the UI (`confirmBoot`)
- [x] boot counter while `upgrade_available=1`
- [x] `altbootcmd` rollback to the previous rootfs slot
- [x] documented limitations (rollback does not restore a previous kernel on `/boot`)

## Milestone 7 – Secure boot

- [x] documented Pi 4 vs QEMU approach ([docs/secure-boot.md](docs/secure-boot.md))
- [x] QEMU signed FIT (`UBOOT_SIGN_ENABLE`, `kernel-fitimage` in `kas/qemuarm64.yml`)
- [x] keys generated under `keys/demo/` (gitignored private key; not a silent product secret)
- [x] tampered FIT is specified to fail in U-Boot (needs a QEMU run to demonstrate)
- [x] A/B rootfs updates stay compatible (FIT is kernel/DTB; rootfs slots unchanged)
- [x] demo steps in [docs/secure-boot.md](docs/secure-boot.md)
- [x] keys and failure behaviour documented

## Milestone 8 – Pluggable application

- [x] default in-tree sample (system info + software update)
- [x] kas variables `ELD_APP_GIT_URI` / `ELD_APP_GIT_TAG` (`kas/common.yml`, `kas/app-external.yml`)
- [x] fetch/build that tag when both are set
- [x] start script still launches `/usr/bin/embedded-linux-ui`
- [x] unset tag → sample app
- [x] documented interface ([docs/application.md](docs/application.md))

---

## Documentation and repo

- [x] [PRD.md](PRD.md) updated from [PRD_INPUT.md](PRD_INPUT.md)
- [x] architecture, update, and Qt remote-debug docs for the current Pi 4 flow
- [x] README sections for macOS Docker and WSL2
- [x] document QEMU build/run ([docs/qemu.md](docs/qemu.md))
- [x] document U-Boot GDB breakpoints ([docs/uboot-debug.md](docs/uboot-debug.md))
- [x] document secure boot ([docs/secure-boot.md](docs/secure-boot.md))
- [x] document external application git tag ([docs/application.md](docs/application.md))
- [x] `TASKS.md` / `kas/qemuarm64.yml` in README and PRD repository layout

---

## PRD success criteria

Use this as the completion checklist ([PRD §18](PRD.md)):

- [x] Raspberry Pi boots the Yocto image on the official 7-inch DSI display (landscape QML + 1:1 touch in the next flashed image)
- [~] same kas/Yocto workflow builds and boots on QEMU ARM64 (kas/scripts in tree; emulator boot not run here)
- [x] image is reproducible with Docker and kas on **Mac** and **WSL**
- [x] default Qt sample is in the image and starts automatically
- [x] external application selectable by git tag; sample if unset
- [x] sample can be SDK cross-compiled, deployed, and remotely debugged
- [~] U-Boot breakpoints on QEMU ARM64 (script + docs; needs a QEMU build)
- [x] UI can install an A/B software update; U-Boot boots the new slot
- [~] secure-boot chain on QEMU FIT (docs + kas; needs a QEMU build to show reject-tamper)
- [x] running software version visible in the UI
- [x] architecture and workflow documented

---

## Parked (PRD optional extensions)

Not in the current success criteria. Do not start unless the PRD says so.

* signed update bundles beyond the secure-boot chain
* RAUC / SWUpdate
* HTTPS OTA / update server
* device health monitoring
* persistent application configuration
* watchdog
* read-only rootfs
* SBOM / CVE scanning
* HDMI mirroring of the 7-inch UI (eglfs cannot scale-clone 720×1280 to 1080p)
* Pi 4 EEPROM/OTP ROM secure boot (would fuse hardware keys)
