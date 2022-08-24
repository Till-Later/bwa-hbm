#ifndef ACCELERATED_BWA_MEM_TESTBENCH_H
#define ACCELERATED_BWA_MEM_TESTBENCH_H

#include <osnap_types.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "ap_int.h"
#include "hw_action_aligner.h"

#ifdef NO_SYNTH

void load_from_file(const std::string filename, uint64_t * addr, uint32_t * size, snap_membus_1024_t *dram, uint32_t *dram_offset_bytes);


#endif

#endif  //ACCELERATED_BWA_MEM_TESTBENCH_H
