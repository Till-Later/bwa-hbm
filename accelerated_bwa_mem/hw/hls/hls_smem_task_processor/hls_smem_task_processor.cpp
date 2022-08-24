#include "hls_smem_task_processor.h"

#include "hls_ap_utils.h"
#include "hls_smem.h"
#include "hls_stream_processing.h"

void smem_task_processor(
    ap_uint<320> bwt_L2,
    ap_stream<task>& task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    ap_stream<bwt_extend_stream_element> req_bwt_extend_streams[4],
    ap_stream<bwt_extend_stream_element> ret_bwt_extend_streams[4],
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream,
    hls::stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    sequence_section_t* sequence_buffer,
    smem_buffer_t smem_buffer[6],
    hls::stream<bool>& termination_signal_stream) {
#pragma HLS INTERFACE ap_bus port = sequence_buffer
#pragma HLS INTERFACE ap_ctrl_hs port = return

    bwt_smem(
        bwt_L2,
        task_stream,
        follow_up_task_stream,
        req_bwt_extend_streams,
        ret_bwt_extend_streams,
        freed_pipeline_index_stream,
        completed_task_stream,
        sequence_buffer,
        smem_buffer,
        termination_signal_stream);
}