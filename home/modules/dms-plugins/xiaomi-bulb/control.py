"""Small JSON bridge between DMS and the bulb's authenticated miIO API."""

import argparse
import fcntl
import getpass
import json
import os
from pathlib import Path
import re
import signal
import sys

from miio import Yeelight
from miio.exceptions import DeviceException


def config_directory():
    return Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config")) / "dms-xiaomi-bulb"


def bounded_int(minimum, maximum):
    def parse(value):
        number = int(value)
        if not minimum <= number <= maximum:
            raise argparse.ArgumentTypeError(f"Use a value from {minimum} to {maximum}")
        return number

    return parse


def rgb_color(value):
    if not re.fullmatch(r"#?[0-9a-fA-F]{6}", value):
        raise argparse.ArgumentTypeError("Use a six-digit hex color, such as #FF8800")
    value = value.lstrip("#")
    return tuple(int(value[index:index + 2], 16) for index in (0, 2, 4))


def setup():
    token = getpass.getpass("Bulb token: ").strip()
    if not re.fullmatch(r"[0-9a-fA-F]{32}", token):
        raise ValueError("The token must contain 32 hexadecimal characters")
    directory = config_directory()
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    os.chmod(directory, 0o700)
    # Replace atomically so a refresh never sees a partially written token.
    temporary = directory / "token.new"
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w") as output:
        os.fchmod(output.fileno(), 0o600)
        output.write(token + "\n")
    temporary.replace(directory / "token")
    print("Token saved. The Xiaomi Bulb widget will connect automatically.")


def deadline(_signal, _frame):
    raise TimeoutError


def run(args):
    token_path = config_directory() / "token"
    try:
        token = token_path.read_text().strip()
    except FileNotFoundError:
        raise ValueError("Run dms-xiaomi-bulb setup in a terminal to connect your bulb") from None
    if token_path.stat().st_mode & 0o077:
        raise ValueError("Set the token file permissions to 600")
    if not re.fullmatch(r"[0-9a-fA-F]{32}", token):
        raise ValueError("Invalid token file; run dms-xiaomi-bulb setup again")

    # DMS can instantiate the tile and detail page separately.
    with (config_directory() / "control.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValueError("Bulb is busy; try again shortly") from None
        signal.signal(signal.SIGALRM, deadline)
        signal.alarm(12)
        try:
            bulb = Yeelight(args.host, token, model="yeelink.light.color5")
            if args.action == "toggle":
                bulb.toggle()
            elif args.action in ("on", "off"):
                getattr(bulb, args.action)()
            elif args.action == "brightness":
                bulb.set_brightness(args.value)
            elif args.action == "temperature":
                bulb.set_color_temp(args.value, transition=0)
            elif args.action == "color":
                bulb.set_rgb(args.value)
            state = bulb.status()
            rgb = state.rgb
            return {
                "ok": True,
                "on": state.is_on,
                "brightness": state.brightness,
                "temperature": state.color_temp,
                "colorMode": int(state.color_mode),
                "color": "#{:02X}{:02X}{:02X}".format(*rgb) if rgb else "",
                "minTemperature": bulb.valid_temperature_range.min,
                "maxTemperature": bulb.valid_temperature_range.max,
            }
        finally:
            signal.alarm(0)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host", default="192.168.88.251")
    actions = parser.add_subparsers(dest="action", required=True)
    for action in ("setup", "status", "toggle", "on", "off"):
        actions.add_parser(action)
    actions.add_parser("brightness").add_argument("value", type=bounded_int(1, 100))
    actions.add_parser("temperature").add_argument("value", type=bounded_int(1700, 6500))
    actions.add_parser("color").add_argument("value", type=rgb_color)
    args = parser.parse_args()
    try:
        if args.action == "setup":
            setup()
            return 0
        result = run(args)
    except ValueError as error:
        result = {"ok": False, "error": str(error)}
    except (TimeoutError, DeviceException):
        result = {"ok": False, "error": "Could not reach the bulb; check power, network and token"}
    except OSError:
        result = {"ok": False, "error": "Could not access the bulb or its local configuration"}
    except Exception:
        # Library exceptions can contain request details; do not expose credentials.
        result = {"ok": False, "error": "Bulb request failed; refresh and try again"}
    print(json.dumps(result))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
