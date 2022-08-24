#ifndef ACCELERATED_BWA_MEM_HLS_SEQUENCE_DEFINITIONS_H
#define ACCELERATED_BWA_MEM_HLS_SEQUENCE_DEFINITIONS_H

#include "hls_snap_1024.H"
#include "action_aligner.h"

#define SEQUENCE_ELEMENT_SIZE_BITS 3
#define SEQUENCE_READ_BUFFER_OFFSET_MASK (BPERDW_256 - 1)

typedef ap_uint<SEQUENCE_ELEMENT_SIZE_BITS> sequence_element_t;
typedef ap_uint<sequence_element_t::width * BPERDW_256> sequence_section_t;
typedef ap_uint<NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER_BITS> sequence_request_element_t;

#endif  //ACCELERATED_BWA_MEM_HLS_SEQUENCE_DEFINITIONS_H
