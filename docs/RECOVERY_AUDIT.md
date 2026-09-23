# NV3047-Core Recovery Audit

Audit target:

- repository: `AirysDark/NV3047-Core`
- recovered main HEAD: `98171155a78d272ecf745bd37d6bba64123dee6c`
- upstream reference: Espressif Arduino-ESP32 `2.0.17`
- upstream commit: `5e19e086c43d0fa5e5a596497ff8f11a0a43f6c2`

## Executive result

NV3047-Core is a trimmed Arduino-ESP32 2.0.17 platform with a custom board definition, package-index experiment, dedicated-but-unused NV3047 variant, and a legacy duplicated ESP32-S3 SDK directory.

The active ESP32-S3 SDK is stock 2.0.17. No custom ESP-IDF SPI/GDMA/LCD IRAM build is active.

## Classification

| Area | Classification | Result |
| --- | --- | --- |
| `package.json` | unchanged upstream | Byte-identical to 2.0.17 |
| `cores/esp32/esp_arduino_version.h` | unchanged upstream | Reports 2.0.17 |
| `cores/esp32/core_version.h` | generated/additional | Records upstream 2.0.17 git version |
| `boards.txt` | NV3047 customized | Contains the custom board and menus; needed repair |
| `platform.txt` | NV3047 customized | Mostly stock; tool paths changed for packaged tool dependencies |
| `programmers.txt` | cosmetic customization | Programmer display name only |
| `variants/esp32s3` | unchanged upstream | Generic ESP32-S3 variant |
| `variants/NV3047` | NV3047 added | Previously identical to generic S3 and not selected |
| `tools/partitions` | unchanged upstream | No NV3047 partition changes detected |
| `tools/sdk/esp32s3` | unchanged upstream | Active stock ESP32-S3 SDK |
| `tools/sdk/MV3047` | incorrectly named / unused | Duplicate stock SDK with only sdkconfig changed |
| `package_nv3047_index.json` | NV3047 added / broken | Current archive metadata incomplete |
| BLE/NetBIOS apparent diffs | non-functional | Line-ending differences only |
| upstream docs/tests/variants omitted | trimmed fork | Expected repository reduction, not HMI customization |

## Active SDK path

`platform.txt` resolves:

```text
compiler.sdk.path={runtime.platform.path}/tools/sdk/{build.mcu}
```

and the board resolves:

```text
nv3047.build.mcu=esp32s3
```

Therefore the active path is:

```text
tools/sdk/esp32s3
```

not:

```text
tools/sdk/MV3047
```

## MV3047 SDK comparison

The recursive file audit found 2,387 files in `tools/sdk/MV3047`.

For every one of those paths a corresponding `tools/sdk/esp32s3` file exists.

Results:

```text
2,386 files: byte-for-byte identical
1 file:      different
```

The only different file is:

```text
sdkconfig
```

This proves the legacy directory is not a rebuilt custom SDK.

## IRAM configuration status

Legacy `tools/sdk/MV3047/sdkconfig` contains requested options including SPI master/ISR, GDMA control/ISR, LCD RGB ISR, and UART ISR IRAM settings.

The active `tools/sdk/esp32s3/sdkconfig` explicitly leaves those options disabled.

Because the linked ESP-IDF components are precompiled archives, adding a matching `CONFIG_*` preprocessor symbol when compiling Arduino code cannot retroactively rebuild those archives.

The old board-level:

```text
-DCONFIG_SPI_MASTER_ISR_IN_IRAM=1
```

was therefore misleading and is removed in the recovery branch.

## Silicon target identity

Legacy custom sdkconfig incorrectly contained:

```text
CONFIG_IDF_TARGET="NV3047"
CONFIG_IDF_TARGET_ESP32S3=y
```

Correct architecture:

```text
ESP-IDF target: esp32s3
Arduino board:  nv3047
Arduino variant: NV3047
```

No new ESP-IDF silicon target is required.

## Variant problem

Recovered main used:

```text
nv3047.build.variant=esp32s3
```

despite containing:

```text
variants/NV3047/pins_arduino.h
```

The recovery branch now selects:

```text
nv3047.build.variant=NV3047
```

and makes that file the authoritative board variant.

## Generic-pin conflicts discovered

The inherited generic ESP32-S3 variant defined:

```text
SDA = GPIO8
SCL = GPIO9
PIN_NEOPIXEL = GPIO48
```

Verified NV3047 display wiring uses GPIO8 and GPIO9 as RGB green data lines and GPIO48 as an RGB red data line.

Those inherited defaults were therefore unsafe for a dedicated display board.

The recovery variant removes the GPIO48 LED identity and requires explicit I2C pin selection instead of silently assigning GPIO8/GPIO9.

## boards.txt compile-flag problem

Recovered main defined:

```text
nv3047.build.extra_flags=-DARDUINO_USB_CDC_ON_BOOT=1 -DCONFIG_SPI_MASTER_ISR_IN_IRAM=1
```

The platform already owns the normal `build.extra_flags` composition for:

- `ESP32` architecture define;
- debug level;
- Arduino loop/event core;
- board defines;
- target-specific USB flags.

A board-specific replacement of that entire property could discard parts of the normal composition. It also forced CDC-on-boot to 1 while the visible board property said 0. That accidental force explains why existing hardware tests could use `Serial0`: Arduino-ESP32 2.0.17 declares `Serial0` when USB CDC-on-boot is enabled, while CDC-disabled builds expose UART0 as `Serial`.

The recovery branch removes the whole `build.extra_flags` override, sets CDC-on-boot to 1 explicitly as the baseline, and uses the normal platform target-specific USB flag mechanism.

## platform.txt customization

Compared with official 2.0.17, the meaningful platform changes are limited:

- display name changed to `NV3047-Core`;
- compiler/esptool/openocd locations use `runtime.tools.*` package-tool resolution instead of expecting host tools inside the platform tree.

The compile/link recipes and ESP32-S3 SDK path remain otherwise upstream-style 2.0.17 behavior.

This is appropriate for a Board Manager platform whose host tools are declared as package dependencies.

## Partition status

The inspected partition files are stock upstream files, including:

- `huge_app.csv`;
- `default.csv`;
- `default_8MB.csv`.

The recovery board menu now couples each exposed partition option to its correct maximum application size.

## Package-index status

Tag `1.0.0` exists but points to the commit immediately before recovered main.

The old tag package metadata used a placeholder archive URL. Recovered main changed the URL to the tag source ZIP but removed the checksum and size rather than regenerating them.

The dependency set also diverges from the official 2.0.17 platform dependency set.

Conclusion: `package_nv3047_index.json` must be generated from a real release artifact and validated; it should not be patched with guessed checksum/size values.

## Recovery baseline changes

The `core-recovery-v1` branch intentionally limits first-stage changes to:

- board identity repair;
- dedicated variant selection;
- safe pin defaults;
- removal of fake IRAM compiler define;
- deterministic QSPI PSRAM and core-affinity defaults;
- menu maximum-size corrections;
- compile smoke tests;
- CI;
- documentation.

No precompiled ESP-IDF library is changed in this phase.

## Next technical phase

Once the baseline compiles and installs cleanly:

1. reconstruct the 2.0.17 ESP32-S3 SDK build process;
2. rebuild the SDK with target `esp32s3`;
3. introduce one measured IRAM group at a time;
4. confirm resulting static archives/linker outputs actually change;
5. record IRAM/DRAM/flash deltas;
6. benchmark identical driver/memory-manager/application builds against stock 2.0.17.
