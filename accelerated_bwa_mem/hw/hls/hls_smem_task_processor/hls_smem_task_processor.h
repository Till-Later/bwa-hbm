#ifndef ACCELERATED_BWA_MEM_HLS_SMEM_TASK_PROCESSOR_H
#define ACCELERATED_BWA_MEM_HLS_SMEM_TASK_PROCESSOR_H

#include "action_aligner.h"
#include "hls_bwt_definitions.h"
#include "hls_definitions.h"
#include "hls_sequence_definitions.h"
#include "hls_stream_processing.h"
#include "hls_task.h"

void smem_task_processor(
    ap_uint<320> bwt_L2,
    ap_stream<task>& task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    ap_stream<bwt_extend_stream_element> req_bwt_extend_streams[4],
    ap_stream<bwt_extend_stream_element> ret_bwt_extend_streams[4],
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream,
    hls::stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    sequence_section_t* sequence_buffer,
    smem_buffer_t smem_buffer[5],
    hls::stream<bool>& termination_signal_stream);


#endif  //ACCELERATED_BWA_MEM_HLS_SMEM_TASK_PROCESSOR_H
