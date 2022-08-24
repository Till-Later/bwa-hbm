#ifndef ACCELERATED_BWA_MEM_HLS_SEQUENCE_MANAGER_H
#define ACCELERATED_BWA_MEM_HLS_SEQUENCE_MANAGER_H

#include "action_aligner.h"
#include "hls_action_reg.h"
#include "hls_sequence_definitions.h"
#include "hls_stream_processing.h"

void sequence_manager(
    sequence_buffer_t sequences[MAX_NB_OF_WORDS_READ_1024 * 16],
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream);

#endif  //ACCELERATED_BWA_MEM_HLS_SEQUENCE_MANAGER_H
