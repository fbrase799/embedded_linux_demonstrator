# PRD – Embedded Linux Demonstrator

## 1. Overview

The **Embedded Linux Demonstrator** demonstrates the development, integration, deployment, debugging, and update workflow of a modern Embedded Linux system.

The primary target is a **Raspberry Pi 4** with the **official 7-inch DSI display**, running a custom Linux image built with **Yocto Project**. The same image recipe family shall also build for **QEMU ARM64**.

The complete Yocto build environment runs inside a **Docker container** and uses **kas** to provide a reproducible build configuration. Docker shall work on **macOS** (Docker Desktop) and **Windows Subsystem for Linux (WSL)**.

By default a custom **Qt sample application** serves as the device UI and provides system information as well as a user interface for initiating software updates. The image shall also be able to boot a **user-supplied application** selected by git tag.

The demonstrator shall specifically show:

* a Yocto image build
* a software update using U-Boot A/B slots
* a secure-boot chain

The project shall demonstrate practical skills in:

* Embedded Linux
* Yocto Project
* BitBake / OpenEmbedded
* kas
* Docker-based build environments on **macOS** and **WSL**
* Linux system integration
* Qt application development
* U-Boot
* Embedded software update concepts
* Secure boot
* QEMU
* Remote deployment and debugging, including U-Boot breakpoints

## Requirements

1. A Linux image for Raspberry Pi 4 shall be produced.
2. The Raspberry Pi 4 shall use the official 7-inch DSI display.
3. The build shall also work for the QEMU ARM64 emulator.
4. The user shall be able to set an external application referenced by a git tag.
5. If that git tag is not set, the provided sample application (system information and software update) shall be used.
6. Breakpoints in U-Boot shall work.
7. The project shall support Docker on **Mac** and **WSL**.

---

# 2. Goals

The demonstrator shall provide a reproducible Embedded Linux development workflow covering:

```text
Developer Machine
      │
      │ Docker
      ▼
+-------------------------+
| Yocto Build Environment |
|                         |
| kas                     |
| BitBake                 |
| Yocto / OpenEmbedded    |
| custom meta-layer       |
+------------+------------+
             │
             │ build
             ▼
      Raspberry Pi Image
             │
             ▼
+-------------------------+
| Raspberry Pi 4          |
|                         |
| U-Boot                   |
| Linux Kernel            |
| Yocto Root Filesystem   |
| Qt Runtime              |
| Qt Demonstrator UI      |
+-------------------------+
```

The resulting system shall boot directly into the selected kiosk application (the in-tree sample, or an external application if configured).

The same kas/Yocto workflow shall also produce a **QEMU ARM64** image so the Yocto build, boot, and U-Boot debugging can be shown without hardware.

---

# 3. Target Platform

## Hardware

Primary target:

* Raspberry Pi 4
* official Raspberry Pi **7-inch DSI** touchscreen (landscape mount)
* SD card
* Ethernet or Wi-Fi network connection
* optional HDMI monitor (not required; the kiosk shall drive the 7-inch panel)
* optional keyboard/mouse

The Raspberry Pi 4 image shall use the 7-inch DSI panel as the product display. The Qt kiosk shall start on that panel.

The initial implementation shall use an SD card as boot and root filesystem storage.

## Emulator

A second machine configuration shall build for **QEMU ARM64** (`qemuarm64`).

The QEMU build shall reuse the same distro, image recipe, sample application, and A/B update concept as far as the emulator allows. It is the preferred environment for demonstrating **U-Boot breakpoints** without a hardware debug probe.

---

# 4. Build Environment

The complete build environment shall run inside Docker.

The Docker image used for kas and Yocto builds shall be based on **Ubuntu 22.04**.

The host system shall not require a native Yocto installation.

Supported developer hosts:

* **macOS** with Docker Desktop
* **Windows** with WSL2 and Docker (Docker Desktop with the WSL2 backend, or Docker Engine inside WSL)

Native Linux Docker is acceptable but is not the required demonstration host.

Example workflow:

```bash
git clone <repository>

cd embedded-linux-demonstrator

docker compose run --rm yocto \
    kas build kas/raspberrypi4.yml
```

The Raspberry Pi 4 configuration shall produce a bootable image that drives the official 7-inch DSI panel.

A second kas configuration shall produce a QEMU ARM64 image, for example:

```bash
docker compose run --rm yocto \
    kas build kas/qemuarm64.yml
```

## Requirements

The build environment shall contain:

* Ubuntu 22.04 as the container base image
* kas
* BitBake
* Yocto/OpenEmbedded build dependencies
* required host tools

Docker shall isolate the build environment from the developer machine.

The same kas/Docker workflow shall work on **Mac** and **WSL** without a native Yocto install.

### macOS

macOS APFS is typically case-insensitive. BitBake rejects a `TMPDIR` on such a filesystem.

The Mac workflow shall therefore keep Yocto's `tmp/` on a Linux filesystem inside Docker (named volume or equivalent) and still make deploy artifacts (`*.wic`, SDK, `.eldupdate`) visible on the host.

`./scripts/build.sh` shall select that overlay automatically on Darwin. Documentation shall cover Docker Desktop disk size (Yocto needs on the order of 80–100 GB).

### WSL

The WSL workflow shall run the same Compose file and kas configurations.

Documentation shall cover WSL2 memory (Yocto linking `gcc-cross` typically needs **at least 16 GB** RAM in the WSL VM). An OOM during the cross compiler build is a host-sizing failure, not an acceptable project limitation.

---

# 5. Yocto Architecture

The project shall use upstream Yocto/OpenEmbedded layers whenever possible.

Expected layers include:

```text
poky
meta-openembedded
meta-raspberrypi
meta-qt6
meta-embedded-linux-demonstrator
```

The custom layer:

```text
meta-embedded-linux-demonstrator
```

shall contain all project-specific configuration.

It shall include at least:

* custom image recipe
* Qt application recipe
* application configuration
* systemd service
* update-related configuration

Example structure:

```text
meta-embedded-linux-demonstrator/
├── conf/
│   └── layer.conf
├── recipes-core/
│   └── images/
│       └── embedded-linux-demo-image.bb
├── recipes-apps/
│   └── embedded-linux-ui/
│       ├── embedded-linux-ui.bb
│       └── files/
└── recipes-support/
    └── ...
```

---

# 6. Qt Demonstrator Application

A small Qt application shall provide the primary UI of the device unless the user selects an external application (see below).

Qt 6 shall be used.

The application should use either:

* Qt Widgets

or

* Qt Quick / QML

Qt Quick/QML is preferred because it demonstrates a typical modern embedded-device UI architecture.

## Main Screen

The application shall display basic device information such as:

```text
Embedded Linux Demonstrator

Device
--------------------------
Hostname:      raspi-demo
Linux Kernel:  6.x
Yocto Release: ...
Application:   1.0.0
Uptime:        00:42:17
IP Address:    192.168.1.42

Software
--------------------------
Current Image: 1.0.0

[ Software Update ]
```

The information shall be retrieved from the running Linux system rather than being hard-coded where practical.

## Application selection

The image shall boot either the in-tree sample application or an external application.

1. The user shall be able to set an **external application** by git repository and **git tag** (kas configuration or equivalent documented variable).
2. If that git tag is not set, the image shall use the **provided sample application** (system information and software update), located in `application/embedded-linux-ui`.
3. When an external application is set, it shall be fetched at that tag, built into the image, and started as the kiosk instead of the sample.
4. The sample remains the default so a clone of this repository always produces a working demonstrator without extra configuration.

---

# 7. Automatic Application Startup

The Qt application shall start automatically after Linux boot.

A systemd service shall be provided by the custom Yocto layer.

Conceptually:

```text
Linux Boot
   │
   ▼
systemd
   │
   ▼
embedded-linux-ui.service
   │
   ▼
Qt Application
```

The device shall therefore behave like an embedded product rather than a general-purpose Raspberry Pi desktop.

---

# 8. Software Update

The demonstrator shall provide a software-update workflow accessible through the Qt application.

The user shall be able to:

1. Open the Software Update screen.
2. Select an update image/package.
3. Display information about the selected update.
4. Start the update.
5. Observe update progress.
6. Reboot the device.
7. Boot into the updated software.

Example UI:

```text
Software Update

Current Version:
1.0.0

Update Image:
[ embedded-linux-demo-1.1.0.img ]

[ Select Image ]

Status:
Ready to update

[ Install Update ]
```

---

# 9. Update Architecture

The update implementation should demonstrate a robust Embedded Linux update concept.

The preferred architecture is an **A/B system update**.

Example:

```text
SD Card

+----------------------+
| Boot / U-Boot        |
+----------------------+
| RootFS A             |
| Version 1.0          |
+----------------------+
| RootFS B             |
| Version 1.1          |
+----------------------+
| Persistent Data      |
+----------------------+
```

If RootFS A is currently active, the update shall be written to RootFS B.

After successful installation, the boot configuration shall mark RootFS B as the next boot target.

U-Boot shall then boot the updated system.

The design should allow a failed boot to revert to the previously working system.

The initial project implementation may simplify the rollback mechanism, but the architecture and limitations shall be documented.

---

# 10. U-Boot Integration

U-Boot shall be used as the bootloader.

The project shall demonstrate basic knowledge of:

* U-Boot environment variables
* boot targets
* selecting the active root filesystem
* switching between software slots
* boot attempt / rollback concepts

Example conceptual variables:

```text
active_slot=A
upgrade_available=0
bootcount=0
bootlimit=3
```

After installing an update:

```text
active_slot=B
upgrade_available=1
```

After the new system has successfully started, Linux shall mark the boot as successful.

---

# 11. Secure Boot

Secure boot is a core purpose of the demonstrator, not an optional extra.

The project shall show an authenticated boot chain so that the device only loads firmware, bootloader, kernel, and root filesystem images that the demonstrator trusts.

The implementation shall be documented for Raspberry Pi 4 (and, where the same artifacts apply, for QEMU). It shall cover at least:

* which components are signed or hashed
* where keys live in the build and on the device
* what happens when verification fails
* how an A/B software update remains compatible with the verified chain

A failed or tampered image shall not boot as a successful update.

---

# 12. Remote Development and Debugging

The Qt application shall support remote debugging from another development machine.

The Raspberry Pi shall run the application while the debugger runs on the developer machine.

Architecture:

```text
Developer Machine
                         Raspberry Pi
+------------------+     +---------------------+
| VS Code / IDE    |     | Yocto Linux         |
|                  | SSH |                     |
| Source Code      +---->+ Qt Application      |
| GDB              |     | gdbserver           |
+--------+---------+     +----------+----------+
         │                          │
         +--------------------------+
             Remote Debugging
```

The debug build shall contain debugging symbols.

The target image shall provide the components required for remote debugging, including `gdbserver`.

A documented example shall demonstrate:

1. Setting a breakpoint in the Qt application.
2. Starting or attaching to the application on the Raspberry Pi.
3. Hitting the breakpoint from the remote development machine.
4. Inspecting variables.
5. Continuing execution.

## U-Boot breakpoints

It shall be possible to **set breakpoints in U-Boot** and hit them from the developer machine.

QEMU ARM64 is the required, documented path for this (GDB attached to the emulator). A hardware debug probe on the Raspberry Pi 4 may be documented if available, but is not required for the demonstrator to be complete.

---

# 13. Development Workflow

The intended development workflow shall be:

## Image Development

```text
Modify Yocto configuration
        ↓
kas build
        ↓
Generate image
        ↓
Flash Raspberry Pi
        ↓
Boot
```

## Application Development

Application development should not require rebuilding the complete Linux image for every source-code modification.

The preferred workflow shall therefore be:

```text
Modify Qt application
        ↓
Cross compile
        ↓
Deploy application via SSH
        ↓
Start gdbserver
        ↓
Remote debug
```

The final production version of the application shall still be integrated into the Yocto image through its BitBake recipe.

---

# 14. SDK / Cross Compilation

Yocto shall generate an SDK for application development.

Example:

```bash
bitbake embedded-linux-demo-image -c populate_sdk
```

The SDK shall provide:

* cross compiler
* sysroot
* Qt development libraries
* target headers
* CMake toolchain integration

The SDK shall allow the Qt application to be built independently from a complete Yocto image build.

This demonstrates the separation between:

```text
Platform Development
        │
        └── Yocto / BitBake

Application Development
        │
        └── Yocto SDK / CMake / Qt
```

---

# 15. Repository Structure

Suggested repository structure:

```text
embedded-linux-demonstrator/
│
├── README.md
├── PRD.md
├── PRD_INPUT.md
├── TASKS.md
│
├── docker/
│   ├── Dockerfile
│   ├── compose.yml
│   └── compose.macos.yml
│
├── kas/
│   ├── raspberrypi4.yml
│   └── qemuarm64.yml
│
├── meta-embedded-linux-demonstrator/
│   ├── conf/
│   ├── recipes-core/
│   ├── recipes-apps/
│   └── recipes-support/
│
├── application/
│   └── embedded-linux-ui/
│       ├── CMakeLists.txt
│       ├── src/
│       └── qml/
│
├── scripts/
│   ├── build.sh
│   ├── flash.sh
│   └── deploy-app.sh
│
└── docs/
    ├── architecture.md
    ├── update.md
    ├── remote-debugging.md
    ├── qemu.md
    ├── uboot-debug.md
    ├── secure-boot.md
    └── application.md
```

---

# 16. Demonstration Scenario

The final demonstrator should support the following end-to-end scenario.

### Step 1 – Reproducible Build

Build the complete Raspberry Pi image using Docker and kas on Mac or WSL.

```bash
./scripts/build.sh
```

### Step 2 – Boot

Flash the image to an SD card and boot the Raspberry Pi.

The Qt application starts automatically.

### Step 3 – Device UI

The application displays:

* system information
* Linux/kernel information
* application version
* software image version
* network information

### Step 4 – Remote Debugging

Connect from the developer machine.

Set a breakpoint in the Qt application and demonstrate that the application running on the Raspberry Pi can be debugged remotely.

### Step 5 – Software Update

Build image version:

```text
1.1.0
```

Select the update from the Qt UI.

The application installs the image into the inactive software slot.

### Step 6 – Reboot

The system reboots.

U-Boot selects the new software slot.

### Step 7 – Verification

The Qt application starts and displays:

```text
Software Version: 1.1.0
```

The successful boot is confirmed and the new slot becomes the active software version.

### Step 8 – QEMU and U-Boot debug

Build and boot the QEMU ARM64 image. Attach GDB and hit a documented breakpoint in U-Boot.

### Step 9 – Secure boot

Show that a correctly signed image boots, and that a tampered or unsigned image is rejected.

---

# 17. Milestones

## Milestone 1 – Yocto Base System

* Docker build environment on Mac and WSL
* kas configuration for Raspberry Pi 4 and QEMU ARM64
* Raspberry Pi 4 support with official 7-inch DSI display
* custom Yocto image
* successful boot on hardware and in QEMU

## Milestone 2 – Qt Integration

* Qt 6 integrated
* custom Qt application
* BitBake application recipe
* automatic startup via systemd

## Milestone 3 – Development Workflow

* Yocto SDK
* cross compilation
* SSH deployment
* gdbserver
* remote debugging

## Milestone 4 – U-Boot

* U-Boot bootloader
* documented U-Boot environment
* boot slot selection
* U-Boot breakpoints via GDB (QEMU ARM64)

## Milestone 5 – Software Update

* update UI
* image validation
* inactive-slot installation
* reboot into updated image

## Milestone 6 – Robust Update

* boot success detection
* boot counter
* automatic rollback
* update failure handling

## Milestone 7 – Secure Boot

* signed/authenticated boot chain
* documented keys and failure behaviour
* updates remain compatible with verified boot

## Milestone 8 – Pluggable Application

* default in-tree sample (system info and software update)
* optional external application selected by git tag

---

# 18. Success Criteria

The project is considered complete when:

* the Raspberry Pi boots a custom Yocto Linux image on the official 7-inch DSI display;
* the same kas/Yocto workflow also builds and boots on QEMU ARM64;
* the Yocto image can be reproduced using Docker and kas on **Mac** and **WSL**;
* the default Qt sample application is part of the Yocto image;
* an external application can be selected by git tag; if none is set, the sample is used;
* the kiosk application starts automatically;
* the sample application can be cross-compiled separately using the Yocto SDK;
* the application can be remotely deployed and debugged;
* breakpoints in U-Boot can be hit (documented on QEMU ARM64);
* the UI can initiate a system software update;
* U-Boot can boot an updated software image;
* a secure-boot chain is demonstrated, including rejection of a tampered image;
* the currently running software version is visible in the UI;
* the complete architecture and development workflow are documented.

---

# 19. Optional Extensions

Possible later extensions include:

* signed software-update images beyond the secure-boot chain
* update integrity verification
* RAUC or SWUpdate integration
* OTA update download via HTTPS
* update server
* device health monitoring
* persistent application configuration
* watchdog integration
* read-only root filesystem
* SBOM generation
* CVE scanning
