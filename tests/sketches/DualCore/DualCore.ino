#include <Arduino.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

static TaskHandle_t core0Task = nullptr;

static void core0Worker(void *) {
  for (;;) {
    vTaskDelay(pdMS_TO_TICKS(1000));
  }
}

void setup() {
  Serial0.begin(115200, SERIAL_8N1, RX, TX);

  BaseType_t result = xTaskCreatePinnedToCore(
      core0Worker,
      "nv3047-core0-smoke",
      2048,
      nullptr,
      1,
      &core0Task,
      0);

  Serial0.printf("loop core=%d worker=%s\n",
                 xPortGetCoreID(),
                 result == pdPASS ? "created" : "failed");
}

void loop() {
  delay(1000);
}
