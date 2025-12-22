#!/usr/bin/env python3
"""
Enter the necessary boot mode on certain MTK devices by talking to the transient
serial port and sending b"FASTBOOT", waiting for b"READYTOO".

Works on:
- Linux: /dev/ttyACM*, /dev/ttyUSB*
- macOS: /dev/cu.usbserial*, /dev/cu.usbmodem* (preferred), plus /dev/tty.usb*

Depends on pyserial:
  python3 -m pip install pyserial

Usage:
  python3 autoboot.py
  # then connect the cable (and repeatedly short-press power, as needed)
"""

import glob
import os
import platform
import sys
import time

from serial import Serial


def device_globs() -> list[str]:
    sysname = platform.system()
    if sysname == "Darwin":  # macOS
        # Prefer /dev/cu.* for outgoing connections; include /dev/tty.* too.
        return [
            "/dev/cu.usbserial*",
            "/dev/cu.usbmodem*",
            "/dev/tty.usbserial*",
            "/dev/tty.usbmodem*",
        ]
    # Default: Linux (covers your original)
    return [
        "/dev/ttyACM*",
        "/dev/ttyUSB*",
    ]


def list_ports() -> set[str]:
    ports: list[str] = []
    for pat in device_globs():
        ports.extend(glob.glob(pat))
    return set(ports)


def main() -> int:
    sysname = platform.system()

    # On Linux, serial devices are often root/dialout-gated. macOS usually doesn't require root.
    if sysname == "Linux" and hasattr(os, "geteuid") and os.geteuid() != 0:
        print(
            "You likely need elevated privileges on Linux to access /dev/tty*.\n"
            "Try: sudo python3 autoboot.py",
            file=sys.stderr,
        )
        return 2

    orig_ports = list_ports()
    if orig_ports:
        print(f"Watching for new serial ports (baseline: {len(orig_ports)} existing).")
    else:
        print("Watching for new serial ports (baseline: none detected).")

    exit_code = 99
    success = False
    max_loops = 1000
    poll_sleep_s = 0.1

    for _ in range(max_loops):
        try:
            time.sleep(poll_sleep_s)

            # New ports that appeared since we started
            new_ports = list_ports() - orig_ports

            print(".", end="", flush=True)

            for port in sorted(new_ports):
                print(f"\nTrying Fastbooter on {port}")

                s = None
                try:
                    # timeout keeps read(8) from blocking forever
                    s = Serial(port, 115200, timeout=1.0, write_timeout=1.0)

                    s.write(b"FASTBOOT")
                    resp = s.read(8)

                    if resp == b"READYTOO":
                        print(f"Entered fastboot mode on port {port}")
                        success = True
                        exit_code = 0
                        return exit_code
                    else:
                        # Useful when debugging odd handshakes
                        if resp:
                            print(f"Unexpected response from {port!r}: {resp!r}")
                        else:
                            print(f"No response from {port!r} (yet).")

                except Exception as e:
                    # OSError / SerialException / permission issues / transient device connect
                    print(f"Error on {port}: {e}")
                finally:
                    try:
                        if s is not None:
                            s.close()
                    except Exception:
                        pass

        except KeyboardInterrupt:
            print("\nInterrupted.")
            break

    if not success:
        print("\nFailed to enter fastboot mode (timed out).")
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
