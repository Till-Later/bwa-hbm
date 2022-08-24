#include "hls_bwt_extend_processor.h"

void bwt_extend_processor(
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_stream,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_stream,
    ap_stream<hbm_bwt_position_t>& req_bwt_position_stream,
    ap_stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    bwtint_t bwt_primary,
    ap_uint<320> bwt_L2,
    hls::stream<bool>& termination_signal_stream,
    bwt_extend_state_t::cacheline_t states_1[SMEM_KERNEL_PIPELINE_DEPTH],
    bwt_extend_state_t::cacheline_t states_2[SMEM_KERNEL_PIPELINE_DEPTH]) {
#pragma HLS resource variable = states_1 core = RAM_1P latency = 2 
#pragma HLS resource variable = states_2 core = RAM_1P latency = 2
    bwt_extend(
        req_bwt_extend_stream,
        ret_bwt_extend_stream,
        req_bwt_position_stream,
        ret_bwt_entry_stream,
        bwt_primary,
        bwt_L2,
        termination_signal_stream,
        states_1,
        states_2);
}
