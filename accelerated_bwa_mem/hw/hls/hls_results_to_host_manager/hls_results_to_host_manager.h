#ifndef ACCELERATED_BWA_MEM_HLS_RESULTS_TO_HOST_MANAGER_H
#define ACCELERATED_BWA_MEM_HLS_RESULTS_TO_HOST_MANAGER_H

#include "action_aligner.h"
#include "hls_accelerator_result_buffer_definitions.h"
#include "hls_bwt_definitions.h"
#include "hls_snap_1024.H"
#include "hls_stream_processing.h"
#include "hls_task.h"

#define NUM_HOST_BWT_INTERVAL_VECTOR_CACHE_LINES_1024 (sizeof(host_bwt_interval_vector_t) / BYTES_PER_DATAWORD_1024)

#define NUM_HOST_RESULT_BUFFERS (NUM_SMEM_CORES < 4 ? 1 : 4)
#define NUM_SMEM_CORES_PER_RESULT_BUFFER \
    (NUM_SMEM_CORES < 4 ? NUM_SMEM_CORES : NUM_SMEM_CORES / NUM_HOST_RESULT_BUFFERS)

struct completed_task_endpoints
{
    bool has_interval;
    bwt_interval_vector_index_t intervals_end_index;
    local_sequence_index_t query_end_position;
};

void results_to_host_manager(
    snap_membus_1024_t* host_mem,
    const snapu64_t runtime_status_control_addr,
    accelerator_bwt_interval_vector_cacheline_t result_buffers[NUM_SMEM_CORES][ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES]
                                                              [NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    hls::stream<accelerator_result_buffer_index_t> freed_result_buffer_streams[NUM_SMEM_CORES],
    ap_stream<filled_result_buffer_stream_element> filled_result_buffer_streams[NUM_SMEM_CORES],
    hls::stream<bool>& termination_signal_stream);

#endif  //ACCELERATED_BWA_MEM_HLS_RESULTS_TO_HOST_MANAGER_H
