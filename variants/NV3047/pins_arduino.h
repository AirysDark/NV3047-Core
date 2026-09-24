#ifndef Pins_Arduino_h
#define Pins_Arduino_h

#include <stdint.h>

// NV3047 / CrowPanel ESP32-S3 board identity.
// USB VID/PID are the Espressif native USB defaults used by the recovered
// Arduino-ESP32 2.0.17 board definition.
#define USB_VID 0x303a
#define USB_PID 0x1001

// Hardware pin-map policy:
// NV3047_drivers is the authoritative source for physical NV3047/CrowPanel
// wiring. This variant mirrors that verified map so sketches and compile tests
// can share safe board-level names without re-inventing pin assignments.

// Verified debug UART0 defaults used by the recovered core.
static const uint8_t TX = 43;
static const uint8_t RX = 44;

// There is deliberately no implicit Wire/I2C pin pair.
//
// The generic ESP32-S3 variant used SDA=GPIO8 and SCL=GPIO9, but both pins
// are active RGB display data pins on the verified NV3047 hardware. Keeping
// those aliases would allow a parameterless Wire.begin() to silently fight
// the display. Use Wire.begin(sda, scl) with explicitly selected free pins.
static const int8_t SDA = -1;
static const int8_t SCL = -1;

// Verified shared SPI-area defaults used by touch/SD hardware.
static const uint8_t SS   = 10;  // SD/TF CS
static const uint8_t MOSI = 11;
static const uint8_t MISO = 13;
static const uint8_t SCK  = 12;

// RGB panel: mirrored from NV3047_drivers Config.h.
static const uint8_t NV3047_PIN_RGB_B0 = 15;
static const uint8_t NV3047_PIN_RGB_B1 = 7;
static const uint8_t NV3047_PIN_RGB_B2 = 6;
static const uint8_t NV3047_PIN_RGB_B3 = 5;
static const uint8_t NV3047_PIN_RGB_B4 = 4;

static const uint8_t NV3047_PIN_RGB_G0 = 9;
static const uint8_t NV3047_PIN_RGB_G1 = 46;
static const uint8_t NV3047_PIN_RGB_G2 = 3;
static const uint8_t NV3047_PIN_RGB_G3 = 8;
static const uint8_t NV3047_PIN_RGB_G4 = 16;
static const uint8_t NV3047_PIN_RGB_G5 = 1;

static const uint8_t NV3047_PIN_RGB_R0 = 14;
static const uint8_t NV3047_PIN_RGB_R1 = 21;
static const uint8_t NV3047_PIN_RGB_R2 = 47;
static const uint8_t NV3047_PIN_RGB_R3 = 48;
static const uint8_t NV3047_PIN_RGB_R4 = 45;

static const uint8_t NV3047_PIN_RGB_DE    = 40;
static const uint8_t NV3047_PIN_RGB_VSYNC = 41;
static const uint8_t NV3047_PIN_RGB_HSYNC = 39;
static const uint8_t NV3047_PIN_RGB_PCLK  = 42;
static const uint8_t NV3047_PIN_BACKLIGHT = 2;

// XPT2046 touch / TF shared SPI bus.
static const uint8_t NV3047_PIN_TOUCH_SCLK = 12;
static const uint8_t NV3047_PIN_TOUCH_MOSI = 11;
static const uint8_t NV3047_PIN_TOUCH_MISO = 13;
static const uint8_t NV3047_PIN_TOUCH_CS   = 0;
static const uint8_t NV3047_PIN_TOUCH_IRQ  = 36;

static const uint8_t NV3047_PIN_SD_CS   = 10;
static const uint8_t NV3047_PIN_SD_CLK  = 12;
static const uint8_t NV3047_PIN_SD_MOSI = 11;
static const uint8_t NV3047_PIN_SD_MISO = 13;

// External expansion / board silkscreen pins.
static const uint8_t NV3047_PIN_UART1_RX = 18;
static const uint8_t NV3047_PIN_UART1_TX = 17;
static const uint8_t NV3047_PIN_GPIO_D0  = 38;
static const uint8_t NV3047_PIN_GPIO_D1  = 37;

// I2S board silkscreen pins.
static const uint8_t NV3047_PIN_I2S_LRCLK = 19;
static const uint8_t NV3047_PIN_I2S_BCLK  = 35;
static const uint8_t NV3047_PIN_I2S_SDIN  = 20;

// No LED_BUILTIN/RGB_BUILTIN is declared here. The generic ESP32-S3 variant
// uses GPIO48 as a NeoPixel, but GPIO48 is an RGB-panel data pin on NV3047.
//
// Generic A0..A19 and T1..T14 aliases are also intentionally omitted. Most
// of those GPIOs are committed to the RGB panel or other board hardware and
// the aliases would imply availability that the dedicated HMI does not have.

#endif /* Pins_Arduino_h */
