# NV3047-Core

NV3047-Core is a dedicated Arduino board platform for the NV3047 / Elecrow CrowPanel ESP32-S3 HMI hardware.

It is based on **Arduino-ESP32 2.0.17** and intentionally remains on that generation while the NV3047 driver, memory manager, UI, and real hardware tests are stabilized.

The project is not a normal Arduino library. It contains the Arduino platform layer used below the NV3047 libraries:

```text
NV3047-Core
    |
Arduino / ESP-IDF hardware foundation
    |
NV3047_drivers
    |
NV3047_memorymanager
    |
NV3047_UI
    |
Application sketch
```

## Recovery status

The original July 2026 repository was an unfinished custom-core experiment. The recovery work has established the following facts:

- the source platform is Arduino-ESP32 2.0.17;
- the actual silicon target is and remains `esp32s3`;
- `tools/sdk/esp32s3` is the SDK selected by the Arduino build recipes;
- the active ESP32-S3 SDK files are stock Arduino-ESP32 2.0.17 files;
- `tools/sdk/MV3047` is a legacy duplicate of the stock ESP32-S3 SDK whose only substantive difference is a hand-edited `sdkconfig`;
- the legacy `MV3047` directory is **not** evidence that ESP-IDF components were rebuilt;
- the original board selected the generic `esp32s3` variant even though `variants/NV3047` existed;
- the original board injected `CONFIG_SPI_MASTER_ISR_IN_IRAM` as a compiler define. That does not rebuild the precompiled ESP-IDF SPI driver and has been removed from the recovery baseline.

See [docs/RECOVERY_AUDIT.md](docs/RECOVERY_AUDIT.md) for the detailed audit.

## Arduino IDE Board Manager installation

The recovery baseline is published as prerelease **NV3047-Core 1.0.1**.

Add this single URL to **Arduino IDE > Preferences > Additional Boards Manager URLs**:

```text
https://raw.githubusercontent.com/AirysDark/NV3047-Core/main/package_nv3047_index.json
```

Then open Boards Manager, search for `NV3047`, install **NV3047 ESP32-S3 HMI Core**, and select:

```text
NV3047 High-Priority HMI Board
```

The NV3047 package index carries the exact Espressif ESP32-S3 compiler, debugger, OpenOCD, esptool, mkspiffs, and mklittlefs tool definitions required by the 2.0.17-based core. A separate Espressif Additional Boards Manager URL is not required.

The current 1.0.1 release is intentionally marked prerelease until the package has completed physical-panel upload, RGB, touch, and PSRAM validation.

## Supported baseline

| Item | Baseline |
| --- | --- |
| MCU | ESP32-S3 |
| Arduino core | Arduino-ESP32 2.0.17 |
| ESP-IDF generation | 4.4.7-based Arduino SDK |
| CPU | 240 MHz |
| Flash default | 4 MB |
| Flash frequency target | 80 MHz |
| PSRAM default | QSPI |
| PSRAM speed in stock SDK | 80 MHz |
| Partition default | Huge APP, 3 MB application |
| Arduino loop core | Core 1 |
| Arduino event core | Core 1 |
| Board ID | `nv3047` |
| Board name | `NV3047 High-Priority HMI Board` |
| Variant | `NV3047` |

The 8 MB/16 MB flash and OPI PSRAM menu entries are hardware options and must be verified on the exact panel revision before being treated as universal defaults.

## Verified board pins

**Pin-map authority:** `NV3047_drivers` is the source of truth for physical board wiring. NV3047-Core mirrors that verified map in `variants/NV3047/pins_arduino.h` so board-level sketches and CI can use safe `NV3047_PIN_*` constants. Driver timing, colour packing, touch calibration, SPI transaction behaviour, and panel initialization remain owned by `NV3047_drivers`.

### Debug UART

| Signal | GPIO |
| --- | ---: |
| TX | 43 |
| RX | 44 |

The verified debug path is `Serial0` at 115200 baud using RX 44 / TX 43. The recovery board deliberately enables USB CDC-on-boot by default because Arduino-ESP32 2.0.17 only declares the separate `Serial0` hardware-UART object in that configuration; disabling CDC-on-boot makes UART0 the global `Serial` object instead.

### Shared SPI area

| Signal | GPIO |
| --- | ---: |
| SCK | 12 |
| MOSI | 11 |
| MISO | 13 |
| SD/TF CS | 10 |
| Touch CS | 0 |
| Touch IRQ | 36 |

The Arduino variant exposes the verified generic SPI defaults as SCK/MOSI/MISO/SS = 12/11/13/10. It also mirrors touch and SD pins as `NV3047_PIN_TOUCH_*` and `NV3047_PIN_SD_*` constants. The driver remains responsible for configuring and operating those peripherals.

### Expansion / silkscreen pins

| Function | GPIO |
| --- | ---: |
| UART1 RX | 18 |
| UART1 TX | 17 |
| GPIO D0 | 38 |
| GPIO D1 | 37 |
| I2S LRCLK | 19 |
| I2S BCLK | 35 |
| I2S SDIN | 20 |

These are mirrored in the Core as `NV3047_PIN_UART1_*`, `NV3047_PIN_GPIO_D*`, and `NV3047_PIN_I2S_*`.

### RGB display

The current driver project is authoritative for display timing, colour packing, touch calibration, and panel mapping. The Core mirrors the verified physical RGB wiring as `NV3047_PIN_RGB_*` and `NV3047_PIN_BACKLIGHT` constants:

| Function | GPIO |
| --- | --- |
| Blue | 15, 7, 6, 5, 4 |
| Green | 9, 46, 3, 8, 16, 1 |
| Red | 14, 21, 47, 48, 45 |
| DE | 40 |
| VSYNC | 41 |
| HSYNC | 39 |
| PCLK | 42 |
| Backlight | 2 |

The current driver uses a 480 x 272 RGB panel and a 6 MHz pixel clock.

## Why there is no default I2C pin pair

The generic ESP32-S3 variant used:

```text
SDA = GPIO8
SCL = GPIO9
```

Both GPIO8 and GPIO9 are active RGB display data pins on the verified NV3047 hardware.

For that reason, the dedicated NV3047 variant deliberately defines SDA/SCL as unavailable defaults. Use an explicit call such as:

```cpp
Wire.begin(chosenSdaPin, chosenSclPin);
```

only after choosing pins that are genuinely free in the application.

This avoids a parameterless `Wire.begin()` silently reconfiguring two display pins.

## Why there is no built-in NeoPixel definition

The generic ESP32-S3 variant advertises GPIO48 as a NeoPixel pin. GPIO48 is part of the verified NV3047 RGB display bus.

NV3047 therefore does not declare `LED_BUILTIN` or `RGB_BUILTIN` in its dedicated variant.

## Board menu baseline

The recovery board definition provides controlled choices for:

- upload speed;
- QSPI / disabled / experimental OPI PSRAM;
- QIO-boot and DIO-boot 80 MHz flash profiles;
- 4 MB, 8 MB, and 16 MB flash sizes;
- Huge APP, default 4 MB OTA, and default 8 MB OTA partition layouts;
- Arduino loop core;
- Arduino event core;
- native USB mode;
- CDC/MSC/DFU-on-boot;
- integrated USB JTAG;
- board revision;
- legacy LoRaWAN metadata retained from the recovered project.

The stable baseline is intentionally conservative. Aggressive compiler or SDK optimizations belong on separate experimental branches.

## USB

The baseline uses the ESP32-S3 native hardware CDC/JTAG mode with CDC-on-boot enabled. In Arduino-ESP32 2.0.17 this keeps `Serial` on USB CDC and exposes the verified hardware UART0 path as `Serial0` on RX44/TX43.

TinyUSB/USB-OTG, MSC, and DFU options remain available as board menu experiments. They must be validated before being made release defaults.

## Flash and partitions

The default application profile is the stock Arduino-ESP32 2.0.17 `huge_app.csv` layout:

- application: 0x300000 bytes (3 MB);
- no second OTA application slot;
- SPIFFS and coredump partitions retained.

The recovery did not modify the stock partition CSV files.

## PSRAM

The recovery baseline selects QSPI PSRAM and defines `BOARD_HAS_PSRAM`.

The active stock ESP32-S3 SDK configuration uses 80 MHz Quad PSRAM. OPI remains a selectable experimental option because panel revisions and fitted memory devices can differ.

## Performance architecture

The purpose of this core is to support optimizations that ordinary Arduino libraries cannot control, including:

- ESP-IDF component configuration;
- interrupt code placement;
- linker placement;
- internal RAM policy;
- GDMA behavior;
- RGB LCD driver internals;
- selected compiler optimization;
- task/core policy;
- direct-framebuffer experiments.

The project must not use core modifications to hide driver or memory-manager bugs. The stock-2.0.17 baseline is the reference point.

## IRAM work: current truth

The legacy custom `sdkconfig` requested options such as:

```text
CONFIG_SPI_MASTER_IN_IRAM=y
CONFIG_SPI_MASTER_ISR_IN_IRAM=y
CONFIG_GDMA_CTRL_FUNC_IN_IRAM=y
CONFIG_GDMA_ISR_IRAM_SAFE=y
CONFIG_LCD_RGB_ISR_IRAM_SAFE=y
CONFIG_UART_ISR_IN_IRAM=y
```

Those options are **not active in the recovery baseline**.

Arduino-ESP32 2.0.17 links many ESP-IDF components from precompiled static libraries. Adding a `CONFIG_*` macro to `boards.txt` or to a sketch does not rebuild those libraries.

An optimization branch may claim these settings only after the required ESP-IDF libraries are reproducibly rebuilt and the resulting archives/linker outputs are demonstrably different from stock.

## Legacy tools/sdk/MV3047

`tools/sdk/MV3047` is retained temporarily as recovery evidence.

Audit result:

- every file has a corresponding path under `tools/sdk/esp32s3`;
- 2,386 files are byte-for-byte identical;
- only `sdkconfig` differs.

It is not selected by the current build and should eventually be removed after any useful configuration intent has been migrated into a reproducible SDK build process.

It must never use `CONFIG_IDF_TARGET="NV3047"`. The target is `esp32s3`; NV3047 is the board identity.

## Development workflow

### 1. Stable recovery baseline

The `core-recovery-v1` branch repairs board identity and tests the stock Arduino-ESP32 2.0.17 foundation.

### 2. Board Manager packaging

A release must use a real release archive with:

- a stable archive filename;
- SHA-256 checksum;
- exact byte size;
- valid tool dependencies;
- an archive root layout accepted by Arduino;
- a package index that resolves from one Additional Boards Manager URL.

The old `1.0.0` package metadata is not considered a valid release baseline.

### 3. Rebuilt SDK branch

After installation/compile/upload are stable, build an NV3047-tuned ESP32-S3 SDK from the 2.0.17-compatible ESP-IDF/lib-builder process.

Start with measured, high-value IRAM candidates rather than enabling every IRAM option.

### 4. Performance branches

Only after the SDK baseline is reproducible should branches test:

- SPI/touch ISR in IRAM;
- GDMA ISR/control placement;
- LCD RGB ISR placement;
- UART ISR placement;
- selective O2/O3;
- linker-placement experiments;
- internal RAM reservation;
- RGB/direct-framebuffer changes.

## Tests

Compile-smoke sketches live under `tests/sketches`.

The baseline CI checks:

- dedicated NV3047 variant selection;
- UART pin constants;
- safe I2C defaults;
- complete RGB/display pin-map constants;
- touch and SD/TF pin-map constants;
- expansion UART/GPIO/I2S pin-map constants;
- SPI pin constants and ESP-IDF SPI2 host availability;
- PSRAM APIs;
- heap/memory statistics APIs;
- dual-core FreeRTOS task APIs;
- ESP LCD RGB headers.

Hardware upload tests remain manual because CI has no physical panel.

## Hardware validation checklist

For every core-level performance change record at minimum:

- IRAM usage;
- DRAM usage;
- flash usage;
- PSRAM usage;
- boot stability;
- display FPS;
- average/minimum/maximum frame interval;
- frame jitter;
- touch latency;
- SPI transaction stability;
- resets;
- watchdog events;
- upload stability.

Compare the exact same application and library versions against official Arduino-ESP32 2.0.17.

## Direct framebuffer research

A future experimental branch may vendor or modify the ESP-IDF 4.4.7 RGB panel implementation to explore explicit LCD framebuffer ownership or application drawing directly into LCD-owned buffers.

That work is intentionally deferred until the Board Manager package and rebuilt SDK are reproducible.

## Release requirements

A release is not complete merely because a Git tag exists.

Before publishing a Board Manager version:

1. compile the smoke-test sketches;
2. package the platform into a deterministic release ZIP;
3. calculate SHA-256;
4. calculate exact archive size;
5. validate the package index;
6. install from a clean Arduino CLI/IDE environment;
7. verify the board appears;
8. compile and link;
9. upload to physical NV3047 hardware;
10. verify UART, PSRAM, touch, and display operation.

## Known limitations

- The recovery baseline still uses the stock precompiled ESP32-S3 SDK.
- The legacy `tools/sdk/MV3047` duplicate has been removed after its configuration intent was documented.
- Board Manager packaging is reproducible and the 1.0.1 prerelease is published; physical-panel validation is still required before stable release.
- OPI PSRAM and non-default flash sizes require hardware verification.
- The historical QIO/DIO flash profile is preserved pending panel testing.
- LoRaWAN menu metadata is retained but is not part of the current display-core validation scope.
