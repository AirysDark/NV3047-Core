#!/usr/bin/env python3
"""Generate a self-contained NV3047 Arduino Boards Manager package index.

The platform is based on Arduino-ESP32 2.0.17, but NV3047-Core is a separate
packager. To make one Additional Boards Manager URL sufficient, the generator
copies the exact Espressif tool definitions required by the ESP32-S3 platform
into the NV3047 package and rewrites those tool dependencies to this packager.

The actual tool archives remain hosted by Espressif; their upstream URLs,
checksums, sizes, and host selectors are preserved verbatim.
"""

from __future__ import annotations

import argparse
import copy
import hashlib
import json
from pathlib import Path
from urllib.request import urlopen

ESPRESSIF_INDEX = (
    "https://raw.githubusercontent.com/espressif/arduino-esp32/"
    "gh-pages/package_esp32_index.json"
)
UPSTREAM_CORE_VERSION = "2.0.17"
PACKAGER = "NV3047-Core"

# The NV3047 board only targets ESP32-S3, so do not force users to download
# compiler toolchains for silicon families this platform does not expose.
REQUIRED_ESPRESSIF_TOOLS = (
    ("xtensa-esp32s3-elf-gcc", "esp-2021r2-patch5-8.4.0"),
    ("xtensa-esp-elf-gdb", "11.2_20220823"),
    ("openocd-esp32", "v0.12.0-esp32-20230921"),
    ("esptool_py", "4.5.1"),
    ("mkspiffs", "0.2.3"),
    ("mklittlefs", "3.0.0-gnu12-dc7f933"),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--archive", required=True, type=Path)
    parser.add_argument("--version", required=True)
    parser.add_argument("--url", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--upstream-index",
        default=ESPRESSIF_INDEX,
        help="Espressif package index used only as the authoritative tool source",
    )
    return parser.parse_args()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def fetch_upstream(url: str) -> dict:
    with urlopen(url, timeout=60) as response:
        return json.load(response)


def find_esp_package(index: dict) -> dict:
    for package in index.get("packages", []):
        if package.get("name") == "esp32":
            return package
    raise RuntimeError("Espressif package 'esp32' not found in upstream index")


def find_platform(package: dict, version: str) -> dict:
    for platform in package.get("platforms", []):
        if platform.get("version") == version:
            return platform
    raise RuntimeError(f"Espressif platform {version!r} not found")


def find_tool(package: dict, name: str, version: str) -> dict:
    for tool in package.get("tools", []):
        if tool.get("name") == name and tool.get("version") == version:
            return copy.deepcopy(tool)
    raise RuntimeError(f"Required Espressif tool not found: {name}@{version}")


def main() -> None:
    args = parse_args()
    archive = args.archive.resolve()
    if not archive.is_file():
        raise SystemExit(f"Archive not found: {archive}")

    upstream_index = fetch_upstream(args.upstream_index)
    esp_package = find_esp_package(upstream_index)
    upstream_platform = find_platform(esp_package, UPSTREAM_CORE_VERSION)

    upstream_deps = {
        (item["name"], item["version"]): item
        for item in upstream_platform.get("toolsDependencies", [])
    }

    tools = []
    dependencies = []
    for name, version in REQUIRED_ESPRESSIF_TOOLS:
        expected = upstream_deps.get((name, version))
        if expected is None:
            raise RuntimeError(
                f"{name}@{version} is not a dependency of upstream "
                f"Arduino-ESP32 {UPSTREAM_CORE_VERSION}"
            )

        tools.append(find_tool(esp_package, name, version))
        dependencies.append(
            {"packager": PACKAGER, "name": name, "version": version}
        )

    # Arduino's own package index is built into Arduino IDE/CLI. Keep the
    # official DFU tool dependency there rather than copying Arduino tooling.
    dfu = upstream_deps.get(("dfu-util", "0.11.0-arduino5"))
    if dfu:
        dependencies.append(copy.deepcopy(dfu))

    package_index = {
        "packages": [
            {
                "name": PACKAGER,
                "maintainer": "AirysDark",
                "websiteURL": "https://github.com/AirysDark/NV3047-Core",
                # The Arduino schema includes maintainer email metadata, but
                # this project does not publish a dedicated support mailbox.
                "email": "",
                "help": {
                    "online": "https://github.com/AirysDark/NV3047-Core/issues"
                },
                "platforms": [
                    {
                        "name": "NV3047 ESP32-S3 HMI Core",
                        "architecture": "esp32",
                        "version": args.version,
                        "category": "Contributed",
                        "url": args.url,
                        "archiveFileName": archive.name,
                        "checksum": f"SHA-256:{sha256(archive)}",
                        "size": str(archive.stat().st_size),
                        "help": {
                            "online": (
                                "https://github.com/AirysDark/NV3047-Core"
                                "/blob/main/README.md"
                            )
                        },
                        "boards": [
                            {"name": "NV3047 High-Priority HMI Board"}
                        ],
                        "toolsDependencies": dependencies,
                    }
                ],
                "tools": tools,
            }
        ]
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(package_index, indent=2) + "\n",
        encoding="utf-8",
    )

    print(f"Wrote: {args.output}")
    print(f"Archive size: {archive.stat().st_size}")
    print(f"Archive SHA-256: {sha256(archive)}")
    print(f"Platform version: {args.version}")
    print(f"Copied Espressif tool definitions: {len(tools)}")


if __name__ == "__main__":
    main()
