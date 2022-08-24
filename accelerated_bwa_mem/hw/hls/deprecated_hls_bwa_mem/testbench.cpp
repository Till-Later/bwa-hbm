#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#include <string>

#include "testbench.h"

#ifdef NO_SYNTH

void load_from_file(const std::string filename, uint64_t * addr, uint32_t * size, snap_membus_1024_t *dram, uint32_t *dram_offset_bytes) {
    // TODO-TILL: Check size bounds of DRAM

    FILE* file = fopen(filename.c_str(), "r");

    fseek(file, 0L, SEEK_END);
    uint32_t size_bytes = ftell(file);
    rewind(file);

    fread((char *) dram + *dram_offset_bytes, sizeof(char), size_bytes, file);

    fclose(file);

    *addr = *dram_offset_bytes;
    *size = size_bytes;

    *dram_offset_bytes += size_bytes;
}

#endif