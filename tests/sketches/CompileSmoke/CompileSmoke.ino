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

// Full verified board map mirrored from NV3047_drivers.
static_assert(NV3047_PIN_RGB_B0 == 15 && NV3047_PIN_RGB_B1 == 7 &&
              NV3047_PIN_RGB_B2 == 6 && NV3047_PIN_RGB_B3 == 5 &&
              NV3047_PIN_RGB_B4 == 4,
              "NV3047 blue RGB pin map drifted");

static_assert(NV3047_PIN_RGB_G0 == 9 && NV3047_PIN_RGB_G1 == 46 &&
              NV3047_PIN_RGB_G2 == 3 && NV3047_PIN_RGB_G3 == 8 &&
              NV3047_PIN_RGB_G4 == 16 && NV3047_PIN_RGB_G5 == 1,
              "NV3047 green RGB pin map drifted");

static_assert(NV3047_PIN_RGB_R0 == 14 && NV3047_PIN_RGB_R1 == 21 &&
              NV3047_PIN_RGB_R2 == 47 && NV3047_PIN_RGB_R3 == 48 &&
              NV3047_PIN_RGB_R4 == 45,
              "NV3047 red RGB pin map drifted");

static_assert(NV3047_PIN_RGB_DE == 40, "NV3047 DE must be GPIO40");
static_assert(NV3047_PIN_RGB_VSYNC == 41, "NV3047 VSYNC must be GPIO41");
static_assert(NV3047_PIN_RGB_HSYNC == 39, "NV3047 HSYNC must be GPIO39");
static_assert(NV3047_PIN_RGB_PCLK == 42, "NV3047 PCLK must be GPIO42");
static_assert(NV3047_PIN_BACKLIGHT == 2, "NV3047 backlight must be GPIO2");

static_assert(NV3047_PIN_TOUCH_SCLK == 12 &&
              NV3047_PIN_TOUCH_MOSI == 11 &&
              NV3047_PIN_TOUCH_MISO == 13 &&
              NV3047_PIN_TOUCH_CS == 0 &&
              NV3047_PIN_TOUCH_IRQ == 36,
              "NV3047 touch pin map drifted");

static_assert(NV3047_PIN_SD_CS == 10 &&
              NV3047_PIN_SD_CLK == 12 &&
              NV3047_PIN_SD_MOSI == 11 &&
              NV3047_PIN_SD_MISO == 13,
              "NV3047 SD/TF pin map drifted");

static_assert(NV3047_PIN_UART1_RX == 18 && NV3047_PIN_UART1_TX == 17,
              "NV3047 expansion UART1 pin map drifted");
static_assert(NV3047_PIN_GPIO_D0 == 38 && NV3047_PIN_GPIO_D1 == 37,
              "NV3047 expansion GPIO pin map drifted");

static_assert(NV3047_PIN_I2S_LRCLK == 19 &&
              NV3047_PIN_I2S_BCLK == 35 &&
              NV3047_PIN_I2S_SDIN == 20,
              "NV3047 I2S pin map drifted");

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
