#ifndef ACCELERATED_BWA_MEM_HW_SMEM_H
#define ACCELERATED_BWA_MEM_HW_SMEM_H

#include "action_aligner.h"
#include "hls_bwt_definitions.h"
#include "hls_definitions.h"
#include "hls_snap_1024.H"
#include "hls_task.h"

#define GET_SEQUENCE_SECTION(sequence_section, request_stream, response_stream, global_sequence_index) \
    sequence_request_stream << ((global_sequence_index) >> ADDR_RIGHT_SHIFT_256); \
    ap_wait(); \
    sequence_response_stream >> sequence_section;

void bwt_smem(
    ap_uint<320> bwt_L2,
    ap_stream<task>& new_task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    ap_stream<bwt_extend_stream_element> req_bwt_extend_streams[4],
    ap_stream<bwt_extend_stream_element> ret_bwt_extend_streams[4],
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream,
    hls::stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    sequence_section_t* sequence_buffer,
    smem_buffer_t smem_buffer[6],
    hls::stream<bool>& termination_signal_stream);

#endif  //ACCELERATED_BWA_MEM_HW_SMEM_H
