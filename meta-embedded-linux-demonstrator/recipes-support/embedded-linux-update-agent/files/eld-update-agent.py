#!/usr/bin/env python3
"""A/B rootfs update agent for the Embedded Linux Demonstrator.

Protocol: newline-delimited JSON over UNIX socket /run/eld-update.sock

Requests:
  {"cmd": "status"}
  {"cmd": "list_images"}
  {"cmd": "inspect", "path": "/data/updates/foo.eldupdate"}
  {"cmd": "install", "path": "/data/updates/foo.eldupdate"}
  {"cmd": "confirm_boot"}
  {"cmd": "reboot"}
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
import socket
import subprocess
import sys
import tarfile
import tempfile
import threading
import traceback

SOCKET_PATH = "/run/eld-update.sock"
UPDATE_DIRS = ("/data/updates", "/media", "/run/media")
PART_A = "/dev/mmcblk0p2"
PART_B = "/dev/mmcblk0p3"
MOUNTPOINT = "/mnt/eld-update"
IMAGE_VERSION_FILE = "/etc/image-version"
IMAGE_MACHINE_FILE = "/etc/image-machine"

_lock = threading.Lock()
_state = {
    "busy": False,
    "progress": 0,
    "state": "idle",
    "message": "Ready to update",
    "error": "",
    "last_image": "",
}


def log(msg: str) -> None:
    print(msg, flush=True)


def read_file(path: str) -> str:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            return handle.read().strip()
    except OSError:
        return ""


def current_version() -> str:
    return read_file(IMAGE_VERSION_FILE) or "unknown"


def current_machine() -> str:
    return read_file(IMAGE_MACHINE_FILE) or "raspberrypi4-64"


def current_slot() -> str:
    try:
        with open("/proc/cmdline", "r", encoding="utf-8") as handle:
            cmdline = handle.read()
    except OSError:
        return "A"
    if "eld.slot=B" in cmdline or "root=/dev/mmcblk0p3" in cmdline:
        return "B"
    return "A"


def inactive_slot() -> str:
    return "B" if current_slot() == "A" else "A"


def slot_device(slot: str) -> str:
    return PART_B if slot == "B" else PART_A


def fw_printenv(name: str) -> str:
    try:
        out = subprocess.check_output(["fw_printenv", "-n", name], text=True, stderr=subprocess.DEVNULL)
        return out.strip()
    except (OSError, subprocess.CalledProcessError):
        return ""


def fw_setenv(**values: str) -> None:
    for key, value in values.items():
        subprocess.check_call(["fw_setenv", key, value])


def set_state(**kwargs) -> None:
    with _lock:
        _state.update(kwargs)


def snapshot_state() -> dict:
    with _lock:
        return dict(_state)


def sha256_file(path: str) -> str:
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def find_images() -> list[dict]:
    results = []
    seen = set()
    for base in UPDATE_DIRS:
        if not os.path.isdir(base):
            continue
        for root, _dirs, files in os.walk(base):
            for name in files:
                if not name.endswith((".eldupdate", ".update")):
                    continue
                path = os.path.join(root, name)
                if path in seen:
                    continue
                seen.add(path)
                info = inspect_image(path)
                info["path"] = path
                results.append(info)
    results.sort(key=lambda item: item.get("path", ""))
    return results


def inspect_image(path: str) -> dict:
    info = {
        "path": path,
        "valid": False,
        "version": "",
        "compatible": "",
        "rootfs_sha256": "",
        "error": "",
        "size": 0,
    }
    try:
        info["size"] = os.path.getsize(path)
        with tarfile.open(path, "r:gz") as bundle:
            names = bundle.getnames()
            if "manifest.json" not in names or "rootfs.tar.gz" not in names:
                info["error"] = "Bundle must contain manifest.json and rootfs.tar.gz"
                return info
            manifest_file = bundle.extractfile("manifest.json")
            if manifest_file is None:
                info["error"] = "Unable to read manifest.json"
                return info
            manifest = json.loads(manifest_file.read().decode("utf-8"))
        info["version"] = str(manifest.get("version", ""))
        info["compatible"] = str(manifest.get("compatible", ""))
        info["rootfs_sha256"] = str(manifest.get("rootfs_sha256", ""))
        if info["compatible"] and info["compatible"] != current_machine():
            info["error"] = "Incompatible machine: %s (this device is %s)" % (
                info["compatible"],
                current_machine(),
            )
            return info
        info["valid"] = True
    except Exception as exc:  # noqa: BLE001 - surface any inspect failure to the UI
        info["error"] = str(exc)
    return info


def extract_member(bundle: tarfile.TarFile, name: str, dest: str) -> None:
    member = bundle.getmember(name)
    with bundle.extractfile(member) as src, open(dest, "wb") as out:
        shutil.copyfileobj(src, out)


def run(cmd: list[str]) -> None:
    log("+ " + " ".join(cmd))
    subprocess.check_call(cmd)


def install_image(path: str) -> None:
    set_state(busy=True, progress=5, state="validating", message="Validating update image", error="", last_image=path)
    info = inspect_image(path)
    if not info.get("valid"):
        raise RuntimeError(info.get("error") or "Invalid update image")

    target_slot = inactive_slot()
    device = slot_device(target_slot)
    if not os.path.exists(device):
        raise RuntimeError("Inactive slot device %s is missing" % device)

    set_state(progress=15, state="unpacking", message="Unpacking update bundle")
    work = tempfile.mkdtemp(prefix="eld-update-")
    try:
        with tarfile.open(path, "r:gz") as bundle:
            extract_member(bundle, "rootfs.tar.gz", os.path.join(work, "rootfs.tar.gz"))
            extract_member(bundle, "manifest.json", os.path.join(work, "manifest.json"))

        set_state(progress=25, state="checksum", message="Verifying checksum")
        actual = sha256_file(os.path.join(work, "rootfs.tar.gz"))
        expected = info["rootfs_sha256"]
        if expected and actual != expected:
            raise RuntimeError("Checksum mismatch")

        set_state(progress=40, state="formatting", message="Formatting slot %s (%s)" % (target_slot, device))
        subprocess.call(["umount", device], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        label = "rootfs_a" if target_slot == "A" else "rootfs_b"
        run(["mkfs.ext4", "-F", "-L", label, device])

        os.makedirs(MOUNTPOINT, exist_ok=True)
        set_state(progress=55, state="mounting", message="Mounting inactive slot")
        run(["mount", device, MOUNTPOINT])
        try:
            set_state(progress=70, state="installing", message="Writing root filesystem to slot %s" % target_slot)
            run(["tar", "-xzf", os.path.join(work, "rootfs.tar.gz"), "-C", MOUNTPOINT])
            run(["sync"])
        finally:
            subprocess.call(["umount", MOUNTPOINT], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

        set_state(progress=90, state="activating", message="Selecting slot %s for next boot" % target_slot)
        fw_setenv(
            active_slot=target_slot,
            upgrade_available="1",
            bootcount="0",
        )
        set_state(
            progress=100,
            state="done",
            message="Update %s installed into slot %s. Reboot to apply." % (info["version"], target_slot),
        )
    finally:
        shutil.rmtree(work, ignore_errors=True)
        subprocess.call(["umount", MOUNTPOINT], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def confirm_boot() -> dict:
    upgrade = fw_printenv("upgrade_available")
    if upgrade == "1":
        fw_setenv(upgrade_available="0", bootcount="0")
        return {"ok": True, "confirmed": True, "slot": current_slot()}
    return {"ok": True, "confirmed": False, "slot": current_slot()}


def reboot_device() -> None:
    subprocess.Popen(["reboot"], close_fds=True)


def status_payload() -> dict:
    state = snapshot_state()
    return {
        "ok": True,
        "slot": current_slot(),
        "inactive_slot": inactive_slot(),
        "version": current_version(),
        "machine": current_machine(),
        "upgrade_available": fw_printenv("upgrade_available") or "0",
        "bootcount": fw_printenv("bootcount") or "0",
        "bootlimit": fw_printenv("bootlimit") or "3",
        **state,
    }


def handle(request: dict) -> dict:
    cmd = request.get("cmd")
    if cmd == "status":
        return status_payload()
    if cmd == "list_images":
        return {"ok": True, "images": find_images()}
    if cmd == "inspect":
        path = request.get("path", "")
        if not path:
            return {"ok": False, "error": "path is required"}
        info = inspect_image(path)
        info["ok"] = bool(info.get("valid"))
        return info
    if cmd == "install":
        path = request.get("path", "")
        if not path:
            return {"ok": False, "error": "path is required"}
        with _lock:
            if _state["busy"] and _state["state"] not in ("idle", "done", "error"):
                return {"ok": False, "error": "An update is already in progress"}
            _state["busy"] = True
            _state["state"] = "queued"
            _state["message"] = "Starting update"
            _state["error"] = ""
            _state["progress"] = 1

        def worker() -> None:
            try:
                install_image(path)
            except Exception as exc:  # noqa: BLE001
                log(traceback.format_exc())
                set_state(busy=False, state="error", message="Update failed", error=str(exc), progress=0)
            else:
                set_state(busy=False)

        threading.Thread(target=worker, daemon=True).start()
        return status_payload()
    if cmd == "confirm_boot":
        return confirm_boot()
    if cmd == "reboot":
        threading.Timer(1.0, reboot_device).start()
        return {"ok": True, "message": "Rebooting"}
    return {"ok": False, "error": "Unknown command: %s" % cmd}


def serve() -> int:
    if os.path.exists(SOCKET_PATH):
        os.unlink(SOCKET_PATH)
    sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    sock.bind(SOCKET_PATH)
    os.chmod(SOCKET_PATH, 0o660)
    sock.listen(5)
    log("Update agent listening on %s (slot %s, version %s)" % (SOCKET_PATH, current_slot(), current_version()))
    while True:
        conn, _addr = sock.accept()
        with conn:
            data = b""
            while True:
                chunk = conn.recv(4096)
                if not chunk:
                    break
                data += chunk
                if b"\n" in data:
                    break
            if not data.strip():
                continue
            try:
                request = json.loads(data.decode("utf-8"))
                response = handle(request)
            except Exception as exc:  # noqa: BLE001
                response = {"ok": False, "error": str(exc)}
            conn.sendall((json.dumps(response) + "\n").encode("utf-8"))


def prepare_data_partition() -> None:
    device = "/dev/mmcblk0p4"
    if not os.path.exists(device):
        return
    try:
        fstype = subprocess.check_output(
            ["blkid", "-o", "value", "-s", "TYPE", device],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except subprocess.CalledProcessError:
        fstype = ""
    if fstype:
        return
    log("Formatting persistent data partition %s" % device)
    subprocess.check_call(["mkfs.ext4", "-F", "-L", "data", device])
    os.makedirs("/data", exist_ok=True)
    subprocess.call(["mount", device, "/data"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    os.makedirs("/data/updates", exist_ok=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Embedded Linux Demonstrator update agent")
    parser.add_argument("--daemon", action="store_true", help="Run as UNIX socket daemon")
    parser.add_argument("--prepare-data", action="store_true", help="Format /data if the partition has no filesystem")
    parser.add_argument("command", nargs="?", help="CLI command: status, list, install, confirm, reboot")
    parser.add_argument("path", nargs="?", help="Update bundle path for install")
    args = parser.parse_args()

    if args.prepare_data:
        prepare_data_partition()
        return 0

    if args.daemon or not args.command:
        if args.daemon:
            return serve()
        parser.print_help()
        return 1

    if args.command == "status":
        print(json.dumps(status_payload(), indent=2))
        return 0
    if args.command == "list":
        print(json.dumps(find_images(), indent=2))
        return 0
    if args.command == "install":
        if not args.path:
            print("install requires a path", file=sys.stderr)
            return 1
        install_image(args.path)
        print(json.dumps(status_payload(), indent=2))
        return 0
    if args.command == "confirm":
        print(json.dumps(confirm_boot(), indent=2))
        return 0
    if args.command == "reboot":
        reboot_device()
        return 0

    print("Unknown command", file=sys.stderr)
    return 1


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(130)
