#include <Arduino.h>
#include <SPI.h>
#include <Wire.h>
#include "driver/spi_master.h"
#include "esp_lcd_panel_rgb.h"

static_assert(TX == 43, "NV3047 TX must be GPIO43");
static_assert(RX == 44, "NV3047 RX must be GPIO44");
static_assert(SCK == 12, "NV3047 SCK must be GPIO12");
static_assert(MOSI == 11, "NV3047 MOSI must be GPIO11");
static_assert(MISO == 13, "NV3047 MISO must be GPIO13");
static_assert(SS == 10, "NV3047 SD/TF CS default must be GPIO10");
static_assert(SDA == -1 && SCL == -1,
              "NV3047 must not silently use RGB pins GPIO8/GPIO9 for I2C");

static spi_host_device_t touchHost = SPI2_HOST;

void setup() {
  Serial0.begin(115200, SERIAL_8N1, RX, TX);
  Serial0.println("NV3047 core compile smoke test");

  // Compile-check the verified Arduino SPI defaults. CI does not execute this
  // sketch on physical hardware.
  SPI.begin(SCK, MISO, MOSI, SS);

  (void)touchHost;
}

void loop() {
  delay(1000);
}
