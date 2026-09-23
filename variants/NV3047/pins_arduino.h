#ifndef Pins_Arduino_h
#define Pins_Arduino_h

#include <stdint.h>

// NV3047 / CrowPanel ESP32-S3 board identity.
// USB VID/PID are the Espressif native USB defaults used by the recovered
// Arduino-ESP32 2.0.17 board definition.
#define USB_VID 0x303a
#define USB_PID 0x1001

// Verified debug UART defaults.
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

// No LED_BUILTIN/RGB_BUILTIN is declared here. The generic ESP32-S3 variant
// uses GPIO48 as a NeoPixel, but GPIO48 is an RGB-panel data pin on NV3047.
//
// Generic A0..A19 and T1..T14 aliases are also intentionally omitted. Most
// of those GPIOs are committed to the RGB panel or other board hardware and
// the aliases would imply availability that the dedicated HMI does not have.

#endif /* Pins_Arduino_h */
