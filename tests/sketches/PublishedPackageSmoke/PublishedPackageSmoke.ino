#include <Arduino.h>
#include <SPI.h>
#include <Wire.h>
#include "driver/spi_master.h"
#include "esp_lcd_panel_rgb.h"

// Compatibility smoke for the already-published 1.0.1 prerelease.
// Keep this limited to API/board invariants that 1.0.1 is expected to expose.
// New branch-only symbols belong in CompileSmoke, not here.
static_assert(TX == 43, "Published NV3047 TX must be GPIO43");
static_assert(RX == 44, "Published NV3047 RX must be GPIO44");
static_assert(SCK == 12, "Published NV3047 SCK must be GPIO12");
static_assert(MOSI == 11, "Published NV3047 MOSI must be GPIO11");
static_assert(MISO == 13, "Published NV3047 MISO must be GPIO13");
static_assert(SS == 10, "Published NV3047 SD/TF CS must be GPIO10");
static_assert(SDA == -1 && SCL == -1,
              "Published NV3047 package must not claim RGB GPIO8/GPIO9 as I2C defaults");

static spi_host_device_t touchHost = SPI2_HOST;

void setup() {
  Serial0.begin(115200, SERIAL_8N1, RX, TX);
  SPI.begin(SCK, MISO, MOSI, SS);
  (void)touchHost;
}

void loop() {
  delay(1000);
}
