#!/usr/bin/env python3
import argparse
import glob
import platform
import re
import subprocess
import time
from typing import Dict, Set, Optional

from serial import Serial  # pip install pyserial

POLL_S = 0.15
HANDSHAKE_TIMEOUT_S = 3.0
FASTBOOT_WAIT_S = 20.0
LAUNCH_COOLDOWN_S = 30.0


def run(cmd: list[str]) -> str:
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    return p.stdout


def run_quiet(cmd: list[str]) -> str:
    """
    Run a command and return stdout only. Never raises.
    Useful for probing system tools (ioreg/udevadm) quietly.
    """
    try:
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        return p.stdout or ""
    except Exception:
        return ""


def fastboot_serials() -> Set[str]:
    out = run(["fastboot", "devices"])
    serials: Set[str] = set()
    for line in out.splitlines():
        parts = line.split()
        if len(parts) >= 2 and parts[1] == "fastboot":
            serials.add(parts[0])
    return serials


def launch(serial: str, version: str) -> None:
    subprocess.Popen(["bash", "./dispatch_one.sh", serial, version])


def device_globs() -> list[str]:
    sysname = platform.system()
    if sysname == "Darwin":
        return [
            "/dev/cu.usbmodem*",
            "/dev/cu.usbserial*",
            "/dev/tty.usbmodem*",
            "/dev/tty.usbserial*",
        ]
    return ["/dev/ttyACM*", "/dev/ttyUSB*"]


def list_ports() -> Set[str]:
    ports: Set[str] = set()
    for pat in device_globs():
        ports.update(glob.glob(pat))
    return ports


def usb_connection_id(port: str) -> str:
    """
    Best-effort stable identifier for the *physical* USB connection backing a tty.

    Purpose:
      If the device re-enumerates and the /dev path changes, we still treat it
      as the same USB connection and do not send the FASTBOOT handshake again.

    Linux:
      Prefer ID_PATH (physical port path), then ID_SERIAL_SHORT, then DEVPATH.

    macOS:
      Prefer locationID (physical port identity), then USB Serial Number.
    """
    sysname = platform.system()

    if sysname != "Darwin":
        out = run_quiet(["udevadm", "info", "-q", "property", "-n", port])
        props: Dict[str, str] = {}
        for line in out.splitlines():
            if "=" in line:
                k, v = line.split("=", 1)
                props[k.strip()] = v.strip()

        if props.get("ID_PATH"):
            return f"linux:id_path:{props['ID_PATH']}"
        if props.get("ID_SERIAL_SHORT"):
            return f"linux:serial:{props['ID_SERIAL_SHORT']}"
        if props.get("DEVPATH"):
            return f"linux:devpath:{props['DEVPATH']}"
        return f"linux:port:{port}"

    # macOS: query IOSerialBSDClient records and find the one that references this /dev path.
    out = run_quiet(["ioreg", "-r", "-c", "IOSerialBSDClient", "-l"])
    if not out:
        return f"darwin:port:{port}"

    # Split into blocks beginning with "+-o" (good-enough chunking for ioreg output).
    blocks = re.split(r"\n(?=\s*\+\-o )", out)
    for b in blocks:
        if port not in b:
            continue

        # Prefer locationID (physical USB port path)
        m_loc = re.search(r'"locationID"\s*=\s*(0x[0-9a-fA-F]+|\d+)', b)
        if m_loc:
            return f"darwin:locationID:{m_loc.group(1)}"

        # Fallback: USB Serial Number (if device exposes it)
        m_sn = re.search(r'"USB Serial Number"\s*=\s*"([^"]+)"', b)
        if m_sn:
            return f"darwin:usbserial:{m_sn.group(1)}"

        # Last resort: entry name (not always unique, but better than nothing)
        m_entry = re.search(r'"IORegistryEntryName"\s*=\s*"([^"]+)"', b)
        if m_entry:
            return f"darwin:entry:{m_entry.group(1)}"

    return f"darwin:port:{port}"


def should_launch(reg: Dict[str, dict], fb_serial: str, now: float) -> bool:
    entry = reg.get(f"fastboot:{fb_serial}")
    if not entry:
        return True
    last = float(entry.get("last_launch_epoch", 0))
    return (now - last) > LAUNCH_COOLDOWN_S


def mark_launched(reg: Dict[str, dict], fb_serial: str, version: str, now: float) -> None:
    reg[f"fastboot:{fb_serial}"] = {
        "status": "launched",
        "last_launch_epoch": int(now),
        "version": version,
    }


def try_fastboot_handshake(port: str) -> bool:
    s = None
    try:
        s = Serial(port, 115200, timeout=HANDSHAKE_TIMEOUT_S, write_timeout=HANDSHAKE_TIMEOUT_S)
        s.write(b"FASTBOOT")
        resp = s.read(8)
        return resp == b"READYTOO"
    except Exception as e:
        print(f"[ports] handshake error on {port}: {e}")
        return False
    finally:
        try:
            if s is not None:
                s.close()
        except Exception:
            pass


def wait_for_new_fastboot(prev: Set[str], timeout_s: float) -> Optional[str]:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        cur = fastboot_serials()
        new = cur - prev
        if new:
            return sorted(new)[0]
        time.sleep(0.2)
    return None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    ap.add_argument("--once", action="store_true")
    ap.add_argument(
        "--allow-when-fastboot-present",
        action="store_true",
        help="By default, if ANY fastboot device is present we don't run serial handshakes.",
    )
    args = ap.parse_args()

    version = args.version
    reg: Dict[str, dict] = {}

    processed_fastboot_serials: Set[str] = set()

    # Deduplicate by *physical USB connection identity* so a single plugged-in device
    # cannot be pushed into fastboot more than once per watcher run, even if the
    # /dev path changes due to re-enumeration.
    handshaked_usb_ids: Set[str] = set()

    # Optional/noise-reduction: also remember the literal port paths we've already tried.
    handshaked_ports: Set[str] = set()

    print(f"Port watcher running. version={version}")
    print(f"Watching ports: {device_globs()}")

    known_ports = list_ports()
    print(f"[ports] baseline: {len(known_ports)} ports already present")

    while True:
        # If there's already a fastboot device connected, don't keep poking serial ports.
        # This prevents the “never exits fastboot” syndrome from repeated handshakes.
        if not args.allow_when_fastboot_present:
            if fastboot_serials():
                time.sleep(POLL_S)
                if args.once:
                    break
                continue

        cur_ports = list_ports()
        new_ports = sorted(cur_ports - known_ports)
        known_ports = cur_ports

        for port in new_ports:
            # If this exact /dev path already got a handshake attempt, don't repeat.
            if port in handshaked_ports:
                print(f"[ports] {port}: already attempted on this path; skipping")
                continue
            handshaked_ports.add(port)

            # Key behavior: only allow *one* FASTBOOT handshake per physical USB connection.
            usb_id = usb_connection_id(port)
            if usb_id in handshaked_usb_ids:
                print(f"[ports] {port}: usb_id={usb_id} already triggered FASTBOOT once; skipping")
                continue
            handshaked_usb_ids.add(usb_id)

            print(f"[ports] new port: {port} (usb_id={usb_id}) (attempting FASTBOOT handshake)")
            prev_fb = fastboot_serials()

            ok = try_fastboot_handshake(port)
            if not ok:
                print(f"[ports] {port}: handshake did not return READYTOO")
                continue

            print(f"[ports] {port}: READYTOO received; waiting for fastboot device...")
            fb_serial = wait_for_new_fastboot(prev_fb, FASTBOOT_WAIT_S)

            if not fb_serial:
                cur_fb = fastboot_serials()
                if cur_fb:
                    fb_serial = sorted(cur_fb)[0]

            if not fb_serial:
                print("[ports] no fastboot device detected after handshake")
                continue

            now = time.time()
            if should_launch(reg, fb_serial, now):
                print(f"[watcher] fastboot device: {fb_serial} -> launching terminal")
                launch(fb_serial, version)
                mark_launched(reg, fb_serial, version, now)
            else:
                print(f"[watcher] fastboot device {fb_serial} recently launched; skipping")

        if args.once:
            break

        time.sleep(POLL_S)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())