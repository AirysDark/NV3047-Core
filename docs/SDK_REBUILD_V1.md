# ESP32-S3 SDK Rebuild V1

This branch begins the high-priority NV3047 core work.

It does **not** enable IRAM optimizations immediately.

The first gate is to reproduce the Arduino-ESP32 2.0.17 ESP32-S3 SDK from its
recorded source revisions, then compare the rebuilt output with the SDK already
shipped in NV3047-Core.

## Why reproduction comes first

Arduino-ESP32 2.0.17 links many ESP-IDF components from static archives in:

```text
tools/sdk/esp32s3/lib/
```

A board-level `CONFIG_*` define cannot rebuild those archives.

Before changing any ESP-IDF option, this project therefore needs a known build
pipeline that can regenerate the stock SDK. Otherwise a performance result
could be caused by unrelated source/tool drift rather than the intended IRAM
change.

## Provenance recovered from tools/sdk/versions.txt

The shipped 2.0.17 SDK records:

```text
esp-idf: v4.4.7 38eeba213a
arduino: idf-38eeba213a d75795f5
esp-dl: master 0632d24
esp-rainmaker: master d8e9345
esp32-camera: master f0bb429
esp_littlefs: master 41873c2
espressif__esp-dsp: master 9b4a8b4
tinyusb: master a0e5626bc
```

Full commits pinned by the rebuild script:

| Component | Commit |
| --- | --- |
| ESP-IDF | `38eeba213aa695aabfd6d89aa9f5078dbe5a94c3` |
| Arduino component | `d75795f5e27eac7afea33b27a22d826cb4556c99` |
| esp32-camera | `f0bb42917cddcfba2c32c2e2fb2875b4fea11b7a` |
| esp-dl | `0632d2447dd49067faabe9761d88fa292589d5d9` |
| esp_littlefs | `41873c20fb5cdbcf28d7d6cc04e4bcb4a1305317` |
| esp-rainmaker | `d8e93454f495bd8a414829ec5e86842b373ff555` |
| esp-dsp | `9b4a8b42b98f2f7cd614e47bb4d159acbe500bee` |
| TinyUSB | `a0e5626bc50d484a23f33000c48082179f0cc2dd` |

## Historical lib-builder

The matching historical line is:

```text
espressif/esp32-arduino-lib-builder
branch: release/v4.4
candidate commit:
3eb9cb06afb534d37f47e98bca9f45e99126f81a
```

That commit was made on May 22, 2024, immediately before Arduino-ESP32 2.0.17
was published on May 23, 2024.

The builder commit is treated as a **candidate provenance point**, not an
unproven fact. The stock-reproduction comparison is what validates whether this
candidate actually recreates the shipped SDK closely enough.

The builder's S3 configuration also matches the recovered stock direction:

- 240 MHz ESP32-S3;
- ESP32-S3 PSRAM support;
- size optimization;
- 80 MHz flash/PSRAM build profiles;
- SPI master ISR IRAM explicitly disabled in the common stock configuration.

## Reproduction script

Run:

```bash
scripts/sdk/rebuild_stock_esp32s3.sh
```

The script:

1. clones the historical lib-builder at the pinned commit;
2. clones ESP-IDF v4.4.7 at the exact recorded commit;
3. applies the historical release/v4.4 I2S compatibility patch;
4. checks out the exact Arduino component revision under the historical local
   branch label `idf-38eeba213a`;
5. checks out every auxiliary component at the recorded commit;
6. installs the ESP-IDF 4.4.7 tool environment;
7. runs the historical builder for **esp32s3 only**;
8. writes output under the rebuild work directory.

Nothing in this script enables NV3047-specific IRAM options.

## Comparison

Run:

```bash
python3 scripts/sdk/compare_sdk.py \
  tools/sdk/esp32s3 \
  .sdk-rebuild/esp32-arduino-lib-builder/out/tools/sdk/esp32s3 \
  --json .sdk-rebuild/sdk-compare.json
```

The first CI run reports differences instead of failing on them. Historical
build systems can contain nondeterministic metadata, and we need to see the
actual difference set before deciding what constitutes a valid reproduction
gate.

The goal is to distinguish:

- exact file matches;
- expected metadata-only differences;
- toolchain-generated but functionally equivalent differences;
- genuine SDK/library differences.

## IRAM experiment sequence after reproduction

Only after the stock rebuild is understood should experiments be introduced,
one group at a time.

### Experiment A — SPI/touch path

Candidate options:

```text
CONFIG_SPI_MASTER_IN_IRAM=y
CONFIG_SPI_MASTER_ISR_IN_IRAM=y
```

Measure archive/section changes and hardware touch behavior before combining
with anything else.

### Experiment B — GDMA path

Candidate options:

```text
CONFIG_GDMA_CTRL_FUNC_IN_IRAM=y
CONFIG_GDMA_ISR_IRAM_SAFE=y
```

Again, build and measure independently first.

### Experiment C — RGB LCD ISR

Candidate:

```text
CONFIG_LCD_RGB_ISR_IRAM_SAFE=y
```

This is directly relevant to the RGB display path and must be measured for IRAM
cost and frame/touch behavior.

### Experiment D — UART ISR

Optional candidate:

```text
CONFIG_UART_ISR_IN_IRAM=y
```

This is lower priority than display/touch/GDMA and should remain separate until
the primary HMI path is stable.

## What must be recorded for each experiment

Build-time:

- changed static archives;
- changed object sections where practical;
- resulting sdkconfig;
- IRAM/DRAM/flash deltas from linked test sketches;
- linker/map differences.

Hardware:

- boot stability;
- upload stability;
- FPS;
- average/minimum/maximum frame interval;
- jitter;
- touch latency and missed touch events;
- SPI stability;
- watchdog/reset events;
- free heap;
- free PSRAM.

No experiment becomes part of the stable Board Manager package based on a
compile result alone.
