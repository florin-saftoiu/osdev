#include <stdint.h>

#include "vga.h"

void vga_clear_screen(void) {
    uint16_t* buffer = (uint16_t*) 0xb8000;
    for (int i = 0; i < 2000; i++) {
        buffer[i] = 0;
    }
}
