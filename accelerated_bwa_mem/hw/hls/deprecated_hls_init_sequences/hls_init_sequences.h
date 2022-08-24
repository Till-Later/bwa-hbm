#ifndef ACCELERATED_BWA_MEM_HLS_INIT_SEQUENCES_H
#define ACCELERATED_BWA_MEM_HLS_INIT_SEQUENCES_H

#include "hls_snap_1024.H"
#include "action_aligner.h"
#include "hls_sequence_definitions.h"
#include "hls_action_reg.h"

void init_sequences(
    //action_reg* act_reg,
    snapu64_t sequences_host_address,
    snapu32_t sequences_size_bytes,
    snap_membus_1024_t* din_gmem,
    sequence_write_section_t sequences[MAX_NB_OF_WORDS_READ_1024 * 4]);

#endif  //ACCELERATED_BWA_MEM_HLS_INIT_SEQUENCES_H
