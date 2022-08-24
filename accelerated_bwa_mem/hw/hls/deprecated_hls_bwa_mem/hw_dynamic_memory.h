#ifndef ACCELERATED_BWA_MEM_HW_DYNAMIC_MEMORY_H
#define ACCELERATED_BWA_MEM_HW_DYNAMIC_MEMORY_H

#include "../include/action_aligner.h"
#include "hls_snap_1024.H"
#include "hw_action_aligner.h"
#include "hw_definitions.h"

struct SMEM_Result;

void bwt_interval_vector_to_membus(
    bwt_interval_vector_t interval_vector,
    snap_membus_1024_t buffer1024[HOST_MEMORY_DATA_WORDS_PER_BWT_INTERVAL_VECTOR]);
void push_local_result_buffer_to_host(
    snap_membus_1024_t* dout_gmem,
    snapu64_t host_result_buffer,
    bwt_interval_vector_t* local_result_buffer);
void push_bwt_interval_to_results(
    hls::stream<uint32_t>& ret_overflow_buffer_stream,
    hls::stream<SMEM_Result_Buffer>& result_buffer_stream,
    bwt_interval_vector_t* local_result_buffer,
    snapu64_t* host_result_buffer,
    const snapu64_t overflow_buffer_start_address,
    bwt_interval_t bwt_interval);
void local_smem_manager(
    hls::stream<bool>& req_overflow_buffer_stream,
    hls::stream<uint32_t>& ret_overflow_buffer_stream,
    hls::stream<SMEM_Result_Buffer>& result_buffer_stream,
    hls::stream<SMEM_Result>& smem_result_stream,
    const snapu64_t overflow_buffer_start_address,
    hls::stream<task_index_t>& smem_task_completion_stream);
void overflow_smem_manager(
    hls::stream<snapu64_t>& req_free_list_section_stream,
    hls::stream<snap_membus_1024_t>& ret_free_list_section_stream,
    snapu64_t free_list_start_address,
    hls::stream<bool>& req_overflow_buffer_stream,
    hls::stream<uint32_t>& ret_overflow_buffer_stream);
void reset_smem_results(
    hls::stream<SMEM_Result>& smem_result_stream,
    snapu64_t host_result_buffer,
    local_sequence_index_t initial_x);
void push_smem_result(hls::stream<SMEM_Result>& smem_result_stream, bwt_interval_t bwt_interval);
void finalize_smem_results(hls::stream<SMEM_Result>& smem_result_stream, task_index_t task_index);

#endif  //ACCELERATED_BWA_MEM_HW_DYNAMIC_MEMORY_H
