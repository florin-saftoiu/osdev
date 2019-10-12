#include "string.h"

#include <stddef.h>

size_t strlen(const char* str) {
    size_t l = 0;
    while (str[l]) {
        l++;
    }
    return l;
}

void* memmove(void* to, const void* from, size_t size) {
    unsigned char* cto = (unsigned char*) to;
    const unsigned char* cfrom = (const unsigned char*) from;
    if (cto < cfrom) {
        for (size_t i = 0; i < size; i++) {
            cto[i] = cfrom[i];
        }
    } else {
        for (size_t i = size; i != 0; i--) {
            cto[i - 1] = cfrom[i - 1];
        }
    }
    return to;
}

void* memset(void* block, int c, size_t size) {
    unsigned char* cblock = (unsigned char*) block;
    for(size_t i = 0; i < size; i++) {
        cblock[i] = (unsigned char) c;
    }
    return block;
}
