#!/usr/bin/env bash
set -euo pipefail

# Rebuild the stock Arduino-ESP32 2.0.17 ESP32-S3 SDK from the exact component
# revisions recorded in tools/sdk/versions.txt.
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
LIB_BUILDER_COMMIT="3eb9cb06afb534d37f47e98bca9f45e99126f81a"

IDF_REPO="https://github.com/espressif/esp-idf.git"
IDF_TAG="v4.4.7"
IDF_COMMIT="38eeba213aa695aabfd6d89aa9f5078dbe5a94c3"

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
git -C "$BUILDER/esp-idf" reset --hard "$IDF_COMMIT"
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
clone_reset_master "$CAMERA_REPO"     "$BUILDER/components/esp32-camera" "$CAMERA_COMMIT"
clone_reset_master "$ESP_DL_REPO"     "$BUILDER/components/esp-dl" "$ESP_DL_COMMIT"
clone_reset_master "$LITTLEFS_REPO"     "$BUILDER/components/esp_littlefs" "$LITTLEFS_COMMIT"
clone_reset_master "$RAINMAKER_REPO"     "$BUILDER/components/esp-rainmaker" "$RAINMAKER_COMMIT"
clone_reset_master "$DSP_REPO"     "$BUILDER/components/espressif__esp-dsp" "$DSP_COMMIT"

rm -rf "$BUILDER/components/arduino_tinyusb/tinyusb"
clone_reset_master "$TINYUSB_REPO"     "$BUILDER/components/arduino_tinyusb/tinyusb" "$TINYUSB_COMMIT"

echo
echo "== Install/export the exact ESP-IDF tool environment =="
"$BUILDER/esp-idf/install.sh"
# shellcheck disable=SC1091
source "$BUILDER/esp-idf/export.sh"

export IDF_PATH="$BUILDER/esp-idf"

echo
echo "== Build ESP32-S3 only =="
(
    cd "$BUILDER"
    ./build.sh -s -t esp32s3
)

OUT="$BUILDER/out/tools/sdk/esp32s3"
if [[ ! -d "$OUT" ]]; then
    echo "ERROR: expected SDK output was not produced: $OUT" >&2
    exit 1
fi

echo
echo "Stock reproduction output:"
echo "  $OUT"
echo
echo "Recorded output versions:"
cat "$BUILDER/out/tools/sdk/versions.txt"
