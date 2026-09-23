#include <Arduino.h>
#include "esp_heap_caps.h"

void setup() {
  Serial0.begin(115200, SERIAL_8N1, RX, TX);

  Serial0.printf("Heap total: %u\n", ESP.getHeapSize());
  Serial0.printf("Heap free: %u\n", ESP.getFreeHeap());
  Serial0.printf("Internal free: %u\n",
                 heap_caps_get_free_size(MALLOC_CAP_INTERNAL));
  Serial0.printf("PSRAM found: %s\n", psramFound() ? "yes" : "no");
  Serial0.printf("PSRAM total: %u\n", ESP.getPsramSize());
  Serial0.printf("PSRAM free: %u\n", ESP.getFreePsram());
}

void loop() {
  delay(1000);
}
