#ifndef ACCELERATED_BWA_MEM_HLS_BWT_EXTEND_PROCESSOR_H
#define ACCELERATED_BWA_MEM_HLS_BWT_EXTEND_PROCESSOR_H

#include "hls_stream_processing.h"
#include "hls_bwt.h"

void bwt_extend_processor(
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_stream,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_stream,
    ap_stream<hbm_bwt_position_t>& req_bwt_position_stream,
    ap_stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    bwtint_t bwt_primary,
    ap_uint<320> bwt_L2,
    hls::stream<bool>& termination_signal_stream,
    bwt_extend_state_t::cacheline_t states_1[SMEM_KERNEL_PIPELINE_DEPTH],
    bwt_extend_state_t::cacheline_t states_2[SMEM_KERNEL_PIPELINE_DEPTH]);

#endif  //ACCELERATED_BWA_MEM_HLS_BWT_EXTEND_PROCESSOR_H
