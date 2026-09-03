# PRD – Embedded Linux Demonstrator

## 1. Overview

The **Embedded Linux Demonstrator** demonstrates the development, integration, deployment, debugging, and update workflow of a modern Embedded Linux system.

The target platform is a **Raspberry Pi 4** running a custom Linux image built with **Yocto Project**.

The complete Yocto build environment runs inside a **Docker container** and uses **kas** to provide a reproducible build configuration.

A custom **Qt application** serves as the device UI and provides basic system information as well as a user interface for initiating software updates.

The project shall demonstrate practical skills in:

* Embedded Linux
* Yocto Project
* BitBake / OpenEmbedded
* kas
* Docker-based build environments
* Linux system integration
* Qt application development
* U-Boot
* Embedded software update concepts
* Remote deployment and debugging

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

The resulting system shall boot directly into the Qt demonstrator application.

---

# 3. Target Platform

## Hardware

Primary target:

* Raspberry Pi 4
* SD card
* Ethernet or Wi-Fi network connection
* HDMI display
* optional keyboard/mouse

The initial implementation shall use an SD card as boot and root filesystem storage.

---

# 4. Build Environment

The complete build environment shall run inside Docker.

The Docker image used for kas and Yocto builds shall be based on **Ubuntu 22.04**.

The host system shall not require a native Yocto installation.

Example workflow:

```bash
git clone <repository>

cd embedded-linux-demonstrator

docker compose run --rm yocto \
    kas build kas/raspberrypi4.yml
```

The build shall produce a bootable Raspberry Pi image.

## Requirements

The build environment shall contain:

* Ubuntu 22.04 as the container base image
* kas
* BitBake
* Yocto/OpenEmbedded build dependencies
* required host tools

Docker shall isolate the build environment from the developer machine.

The same build process should work on different developer machines with Docker installed.

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

A small Qt application shall provide the primary UI of the device.

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

# 11. Remote Development and Debugging

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

---

# 12. Development Workflow

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

# 13. SDK / Cross Compilation

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

# 14. Repository Structure

Suggested repository structure:

```text
embedded-linux-demonstrator/
│
├── README.md
├── PRD.md
│
├── docker/
│   ├── Dockerfile
│   └── compose.yml
│
├── kas/
│   └── raspberrypi4.yml
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
    └── remote-debugging.md
```

---

# 15. Demonstration Scenario

The final demonstrator should support the following end-to-end scenario.

### Step 1 – Reproducible Build

Build the complete Raspberry Pi image using Docker and kas.

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

---

# 16. Milestones

## Milestone 1 – Yocto Base System

* Docker build environment
* kas configuration
* Raspberry Pi 4 support
* custom Yocto image
* successful boot

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

---

# 17. Success Criteria

The project is considered complete when:

* the Raspberry Pi boots a custom Yocto Linux image;
* the Yocto image can be reproduced using Docker and kas;
* the custom Qt application is part of the Yocto image;
* the Qt application starts automatically;
* the Qt application can be cross-compiled separately using the Yocto SDK;
* the application can be remotely deployed and debugged;
* the UI can initiate a system software update;
* U-Boot can boot an updated software image;
* the currently running software version is visible in the UI;
* the complete architecture and development workflow are documented.

---

# 18. Optional Extensions

Possible later extensions include:

* signed software-update images
* secure boot
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
