# Remote debugging

The Raspberry Pi runs the Qt application; GDB runs on the developer machine. The image includes `gdbserver`, SSH, SFTP, and `embedded-linux-ui-dbg`.

```text
Developer Machine              Raspberry Pi
+------------------+           +----------------------+
| SDK sysroot      |    SSH    | Yocto Linux          |
| GDB / IDE        +---------->+ Qt application       |
| Application src  |    GDB    | gdbserver :2345      |
+------------------+  remote   +----------------------+
```

## 1. SDK (once)

```bash
./scripts/build-sdk.sh
sudo ./build/tmp/deploy/sdk/*.sh -d /opt/eld-sdk
source /opt/eld-sdk/*/environment-setup-cortexa72-poky-linux
```

This provides the cross compiler, Qt headers/libraries, CMake toolchain, and a GDB that understands the target.

## 2. Build and deploy an unstripped binary

```bash
source /opt/eld-sdk/*/environment-setup-cortexa72-poky-linux
./scripts/deploy-app.sh root@<pi-ip>
```

`deploy-app.sh` cross-compiles `application/embedded-linux-ui` and rsyncs the binary to `/usr/bin/embedded-linux-ui`.

The image `debug-tweaks` feature allows `ssh root@<pi-ip>` with an empty password. Change that before any non-lab use.

## 3. Start gdbserver on the device

Either attach to the running kiosk:

```bash
ssh root@<pi-ip>
systemctl stop embedded-linux-ui
gdbserver :2345 /usr/bin/embedded-linux-ui
```

Or attach without restarting:

```bash
gdbserver --attach :2345 $(pidof embedded-linux-ui)
```

Stopping the service is easier when you want a breakpoint in `main`.

## 4. Connect GDB from the developer machine

```bash
source /opt/eld-sdk/*/environment-setup-cortexa72-poky-linux
cd application/embedded-linux-ui
$GDB -ex "set sysroot $SDKTARGETSYSROOT" \
     -ex "target remote <pi-ip>:2345" \
     build-target/embedded-linux-ui
```

Example session that matches the PRD:

```text
(gdb) break SystemInfo::readStaticInfo
(gdb) continue
# The device hits the breakpoint after a refresh() / restart.
(gdb) print m_hostname
(gdb) print m_imageVersion
(gdb) continue
```

`readStaticInfo()` runs at startup, so start gdbserver **before** the application, or trigger `sysInfo.refresh()` from QML after attaching.

## 5. VS Code / Cursor example

`.vscode/launch.json` (not committed; copy as needed):

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Remote Pi Qt UI",
      "type": "cppdbg",
      "request": "launch",
      "program": "${workspaceFolder}/application/embedded-linux-ui/build-target/embedded-linux-ui",
      "miDebuggerServerAddress": "RASPI_IP:2345",
      "MIMode": "gdb",
      "miDebuggerPath": "gdb-multiarch",
      "cwd": "${workspaceFolder}/application/embedded-linux-ui",
      "setupCommands": [
        { "text": "set sysroot /opt/eld-sdk/sysroots/cortexa72-poky-linux" }
      ]
    }
  ]
}
```

Use the `gdb` from the SDK environment if `gdb-multiarch` is not installed. Point `set sysroot` at the SDK target sysroot printed by `echo $SDKTARGETSYSROOT`.

## Notes

* Debug symbols for the image-built binary are in the `embedded-linux-ui-dbg` package on the target (`/usr/lib/debug`). SDK-built binaries used with `deploy-app.sh` are usually unstripped and are the better debug target.
* `eglfs` takes over the HDMI display. A breakpoint will freeze the UI; that is expected.
* Firewall: TCP 22 (SSH) and 2345 (gdbserver) must be reachable on the lab network.
