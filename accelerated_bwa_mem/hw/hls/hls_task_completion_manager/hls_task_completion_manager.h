#ifndef ACCELERATED_BWA_MEM_HLS_TASK_COMPLETION_MANAGER_H
#define ACCELERATED_BWA_MEM_HLS_TASK_COMPLETION_MANAGER_H

#include "action_aligner.h"
#include "hls_bwt_definitions.h"
#include "hls_accelerator_result_buffer_definitions.h"
#include "hls_stream_processing.h"
#include "hls_task.h"

#define GET_INTERVAL(smem_buffer, pipeline_index, index) \
    static_cast<accelerator_bwt_interval>( \
        smem_buffer[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 * pipeline_index + 2 + index])

#define SET_INTERVAL(smem_buffer, pipeline_index, index, interval) \
    smem_buffer[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 * pipeline_index + 2 + index] = \
        static_cast<accelerator_bwt_interval::cacheline_t>(interval)

void task_completion_manager(
    const snapu32_t split_width,
    const snapu32_t split_len,
    const snapu32_t min_seed_len,
    ap_stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream,
    accelerator_bwt_interval_vector_cacheline_t smem_buffer[NUM_SMEM_BUFFER_ENTRIES_128],
    accelerator_bwt_interval_vector_cacheline_t result_buffer[ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES]
                                                             [NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    hls::stream<accelerator_result_buffer_index_t>& freed_result_buffer_stream,
    ap_stream<filled_result_buffer_stream_element>& filled_result_buffer_stream,
    hls::stream<bool>& termination_signal_stream);

#endif  //ACCELERATED_BWA_MEM_HLS_TASK_COMPLETION_MANAGER_H