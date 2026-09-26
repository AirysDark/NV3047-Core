#!/usr/bin/env bash
set -euo pipefail

# Rebuild the stock Arduino-ESP32 2.0.17 ESP32-S3 SDK from the exact component
# revisions recovered from the shipped SDK and historical build metadata.
#
# This script intentionally performs NO NV3047 optimization. Its first job is
# provenance/reproducibility: reproduce the stock SDK before changing sdkconfig.
#
# Usage:
#   scripts/sdk/rebuild_stock_esp32s3.sh [workdir]
#
# Output:
#   <workdir>/esp32-arduino-lib-builder/out/tools/sdk/esp32s3

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKDIR="${1:-$REPO_ROOT/.sdk-rebuild}"
BUILDER="$WORKDIR/esp32-arduino-lib-builder"

LIB_BUILDER_REPO="https://github.com/espressif/esp32-arduino-lib-builder.git"
LIB_BUILDER_COMMIT="956a355d51e7f4c3a454e193a9c28fcf321a452f"

IDF_REPO="https://github.com/espressif/esp-idf.git"
IDF_TAG="v4.4.7"
IDF_COMMIT_FULL="38eeba213aa695aabfd6d89aa9f5078dbe5a94c3"

ARDUINO_REPO="https://github.com/espressif/arduino-esp32.git"
ARDUINO_BRANCH_LABEL="idf-38eeba213a"
ARDUINO_COMMIT="d75795f5e27eac7afea33b27a22d826cb4556c99"

CAMERA_REPO="https://github.com/espressif/esp32-camera.git"
CAMERA_COMMIT="f0bb42917cddcfba2c32c2e2fb2875b4fea11b7a"

ESP_DL_REPO="https://github.com/espressif/esp-dl.git"
ESP_DL_COMMIT="0632d2447dd49067faabe9761d88fa292589d5d9"

LITTLEFS_REPO="https://github.com/joltwallet/esp_littlefs.git"
LITTLEFS_COMMIT="41873c20fb5cdbcf28d7d6cc04e4bcb4a1305317"

RAINMAKER_REPO="https://github.com/espressif/esp-rainmaker.git"
RAINMAKER_COMMIT="d8e93454f495bd8a414829ec5e86842b373ff555"

DSP_REPO="https://github.com/espressif/esp-dsp.git"
DSP_COMMIT="9b4a8b42b98f2f7cd614e47bb4d159acbe500bee"

TINYUSB_REPO="https://github.com/hathach/tinyusb.git"
TINYUSB_COMMIT="a0e5626bc50d484a23f33000c48082179f0cc2dd"

# esp-rainmaker's historical manifest uses a floating ^2.2.1 dependency.
# Rebuilding in 2026 resolves that to a modern release, while the shipped
# Arduino-ESP32 2.0.17 SDK is the 2.4.1 generation. V6 keeps the component
# managed (matching the stock build path) but pins the exact historical version.
SECURE_CERT_VERSION="2.4.1"

clone_reset_master() {
    local url="$1"
    local dest="$2"
    local commit="$3"

    git clone --recursive "$url" "$dest"
    git -C "$dest" reset --hard "$commit"
    git -C "$dest" submodule update --init --recursive
}

echo "== NV3047 stock ESP32-S3 SDK reproduction =="
echo "Repository: $REPO_ROOT"
echo "Workdir:    $WORKDIR"

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

echo
echo "== Clone pinned Arduino lib-builder =="
git clone "$LIB_BUILDER_REPO" "$BUILDER"
git -C "$BUILDER" checkout --detach "$LIB_BUILDER_COMMIT"

echo
echo "== Clone exact ESP-IDF v4.4.7 revision =="
git clone --branch "$IDF_TAG" --recursive "$IDF_REPO" "$BUILDER/esp-idf"
git -C "$BUILDER/esp-idf" reset --hard "$IDF_COMMIT_FULL"
git -C "$BUILDER/esp-idf" submodule update --init --recursive

echo
echo "== Apply the historical release/v4.4 I2S compatibility patch =="
(
    cd "$BUILDER/esp-idf"
    patch -p1 --forward < "$BUILDER/patches/i2s.diff"
)

echo
echo "== Clone exact Arduino component revision =="
git clone --recursive "$ARDUINO_REPO" "$BUILDER/components/arduino"
git -C "$BUILDER/components/arduino" checkout -B "$ARDUINO_BRANCH_LABEL" "$ARDUINO_COMMIT"
git -C "$BUILDER/components/arduino" submodule update --init --recursive

echo
echo "== Clone exact auxiliary component revisions =="
clone_reset_master "$CAMERA_REPO" "$BUILDER/components/esp32-camera" "$CAMERA_COMMIT"
clone_reset_master "$ESP_DL_REPO" "$BUILDER/components/esp-dl" "$ESP_DL_COMMIT"
clone_reset_master "$LITTLEFS_REPO" "$BUILDER/components/esp_littlefs" "$LITTLEFS_COMMIT"
clone_reset_master "$RAINMAKER_REPO" "$BUILDER/components/esp-rainmaker" "$RAINMAKER_COMMIT"
clone_reset_master "$DSP_REPO" "$BUILDER/components/espressif__esp-dsp" "$DSP_COMMIT"

# Pin the historical RainMaker transitive dependency without changing its
# component-manager layout. A plain semantic version is an exact match in the
# IDF Component Manager SimpleSpec grammar.
RAINMAKER_MANIFEST="$BUILDER/components/esp-rainmaker/components/esp_rainmaker/idf_component.yml"
python3 - "$RAINMAKER_MANIFEST" "$SECURE_CERT_VERSION" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
version = sys.argv[2]
text = path.read_text(encoding="utf-8")
old = """  espressif/esp_secure_cert_mgr:
    version: "^2.2.1"
    rules:
      - if: "idf_version >=4.3"
"""
new = f"""  espressif/esp_secure_cert_mgr:
    version: "{version}"
    rules:
      - if: "idf_version >=4.3"
"""
if old not in text:
    raise SystemExit("RainMaker secure-cert dependency block did not match the pinned historical source")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
PY

grep -q 'version: "2.4.1"' "$RAINMAKER_MANIFEST"

rm -rf "$BUILDER/components/arduino_tinyusb/tinyusb"
clone_reset_master "$TINYUSB_REPO" "$BUILDER/components/arduino_tinyusb/tinyusb" "$TINYUSB_COMMIT"

echo
echo "== Install/export the exact ESP-IDF tool environment =="
"$BUILDER/esp-idf/install.sh"
# shellcheck disable=SC1091
source "$BUILDER/esp-idf/export.sh"

# ESP-IDF 4.4 allows idf-component-manager ~=1.2. On the recovered stock SDK
# build date (2024-03-05), 1.5.2 was the latest published compatible release.
# Pin it here so component resolution/order is not affected by the later 1.5.3.
python -m pip install --disable-pip-version-check --quiet "idf-component-manager==1.5.2"
python - <<'PY'
from importlib.metadata import version
assert version("idf-component-manager") == "1.5.2"
print("idf-component-manager:", version("idf-component-manager"))
PY

export IDF_PATH="$BUILDER/esp-idf"

# Recreate the variables set by the historical install-esp-idf.sh helper.
# build.sh -s skips that helper, so without these exports the generated
# memory-variant sdkconfig.h files record an empty commit and the lib-builder
# branch name instead of the ESP-IDF provenance shipped in Arduino-ESP32 2.0.17.
ACTUAL_IDF_COMMIT="$(git -C "$IDF_PATH" rev-parse HEAD)"
test "$ACTUAL_IDF_COMMIT" = "$IDF_COMMIT_FULL"

# Arduino-ESP32 2.0.17 records the historical 10-character abbreviation.
# Modern Git chooses 11 characters for this repository, so do not use
# rev-parse --short here; derive the exact recorded width deterministically.
export IDF_COMMIT="${ACTUAL_IDF_COMMIT:0:10}"
export IDF_BRANCH="v4.4.7"

test "$(git -C "$IDF_PATH" rev-parse 'v4.4.7^{commit}')" = "$IDF_COMMIT_FULL"
test "$IDF_COMMIT" = "38eeba213a"

echo
echo "== Historical ESP-IDF provenance variables =="
echo "IDF_COMMIT=$IDF_COMMIT"
echo "IDF_BRANCH=$IDF_BRANCH"

echo
echo "== Build ESP32-S3 only =="
(
    cd "$BUILDER"
    ./build.sh -s -t esp32s3
)

# Verify that Component Manager resolved the exact historical registry release
# into the same managed_components location embedded by the stock SDK.
SECURE_CERT_DIR="$BUILDER/managed_components/espressif__esp_secure_cert_mgr"
test -d "$SECURE_CERT_DIR"
grep -q 'version: "2.4.1"' "$SECURE_CERT_DIR/idf_component.yml"
grep -A8 '^  espressif/esp_secure_cert_mgr:' "$BUILDER/dependencies.lock" | grep -q 'version: 2.4.1'

OUT="$BUILDER/out/tools/sdk/esp32s3"
if [[ ! -d "$OUT" ]]; then
    echo "ERROR: expected SDK output was not produced: $OUT" >&2
    exit 1
fi

# Official Arduino-ESP32 2.0.17 omits this internal lwIP debug header from its
# packaged ESP32-S3 SDK even though the pinned ESP-IDF source tree contains it.
# The historical lib-builder harvest currently includes it, so remove only this
# verified package-only extra to reproduce the published 2.0.17 tree.
LWIP_DEBUG_HEADER="$OUT/include/lwip/port/esp32/include/debug/lwip_debug.h"
if [[ -f "$LWIP_DEBUG_HEADER" ]]; then
    rm -f "$LWIP_DEBUG_HEADER"
fi

echo
echo "Stock reproduction output:"
echo "  $OUT"
echo
echo "Pinned managed secure-cert:"
echo "  $SECURE_CERT_VERSION"
echo
echo "Recorded output versions:"
cat "$BUILDER/out/tools/sdk/versions.txt"
