#include "hls_results_to_host_manager.h"

#include "action_aligner.h"
#include "hls_bwt_definitions.h"
#include "hls_definitions.h"
#include "hls_stream_processing.h"

task_index_t get_smem_results_extraction_index(snap_membus_1024_t* gmem, snapu64_t runtime_status_control_addr) {
#pragma HLS inline
    snap_membus_1024_t buffer1024;
    __builtin_memcpy(
        &buffer1024,
        (snap_membus_1024_t*)gmem
            + ((runtime_status_control_addr + SMEM_RESULTS_EXTRACTION_INDEX_OFFSET) >> ADDR_RIGHT_SHIFT_1024),
        sizeof(snap_membus_1024_t));
    return SLICE(buffer1024, 0, sizeof(task_index_t) * 8);
}

void set_smem_results_insertion_index(
    snap_membus_1024_t* gmem,
    snapu64_t runtime_status_control_addr,
    task_index_t index) {
#pragma HLS inline
    snap_membus_1024_t buffer1024 = 0;
    SLICE(buffer1024, 0, sizeof(task_index_t) * 8) = index;
    *(gmem + ((runtime_status_control_addr + SMEM_RESULTS_INSERTION_INDEX_OFFSET) >> ADDR_RIGHT_SHIFT_1024)) =
        buffer1024;
}

void copy_smem_results_to_host(
    snap_membus_1024_t* gmem,
    const snapu64_t runtime_status_control_addr,
    task_queue_index_t smem_results_entry_position,
    snap_membus_1024_t buffer_1024[NUM_HOST_BWT_INTERVAL_VECTOR_CACHE_LINES_1024],
    bwt_interval_vector_index_t num_entries) {
#pragma HLS inline
    __builtin_memcpy(
        (snap_membus_1024_t*)gmem
            + ((runtime_status_control_addr + SMEM_RESULTS_OFFSET) + (smem_results_entry_position << 11)
               >> ADDR_RIGHT_SHIFT_1024),
        buffer_1024,
        num_entries * sizeof(snap_membus_1024_t));
}

void accelerator_to_host_interval_vector(
    bwt_interval_vector_index_t end_index,
    accelerator_bwt_interval_vector_cacheline_t result_buffer[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    snap_membus_1024_t buffer_1024[NUM_HOST_BWT_INTERVAL_VECTOR_CACHE_LINES_1024]) {

    snap_membus_1024_t buffer_1024_cacheline = 0;
    // No conversion needed, only extend length to implicitly
    SLICE(buffer_1024_cacheline, 0, accelerator_bwt_interval_vector_cacheline_t::width) = result_buffer[0];

    int8_t interval_index = 1;
    for (; interval_index < end_index; interval_index++) {
#pragma HLS pipeline
#pragma HLS loop_tripcount min = 0 max = 64
        if (interval_index % DW256PERDW1024 == 0) {
            buffer_1024[(interval_index - 1) >> 2] = buffer_1024_cacheline;
        }

        accelerator_bwt_interval accelerator_interval(result_buffer[interval_index]);
#pragma HLS data_pack variable = accelerator_interval

        SLICE(buffer_1024_cacheline, interval_index % DW256PERDW1024, host_bwt_interval_vector_cacheline_t::width) =
            to_host_bwt_interval_vector_cacheline(accelerator_interval);
    }
    buffer_1024[(interval_index - 1) >> 2] = buffer_1024_cacheline;
}

bwt_interval_vector_index_t get_results_from_result_buffer(
    hls::stream<accelerator_result_buffer_index_t>& freed_result_buffer_stream,
    ap_stream<filled_result_buffer_stream_element>& filled_result_buffer_stream,
    accelerator_bwt_interval_vector_cacheline_t
        accelerator_result_buffer[ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES]
                                 [NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    snap_membus_1024_t host_result_buffer[NUM_HOST_BWT_INTERVAL_VECTOR_CACHE_LINES_1024]) {
    if (filled_result_buffer_stream.empty() || freed_result_buffer_stream.full()) {
        return 0;
    }
    filled_result_buffer_stream_element result;
    filled_result_buffer_stream >> result;
    accelerator_to_host_interval_vector(
        result.results_end_index, accelerator_result_buffer[result.result_buffer_index], host_result_buffer);
    freed_result_buffer_stream << result.result_buffer_index;

    return (result.results_end_index + DW256PERDW1024 - 1) / DW256PERDW1024;
}

void results_to_host_manager(
    snap_membus_1024_t* host_mem,
    const snapu64_t runtime_status_control_addr,
    accelerator_bwt_interval_vector_cacheline_t result_buffers[NUM_SMEM_CORES][ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES]
                                                              [NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    hls::stream<accelerator_result_buffer_index_t> freed_result_buffer_streams[NUM_SMEM_CORES],
    ap_stream<filled_result_buffer_stream_element> filled_result_buffer_streams[NUM_SMEM_CORES],
    hls::stream<bool>& termination_signal_stream) {
#pragma HLS interface ap_ctrl_hs port = return

#pragma HLS interface m_axi port = host_mem max_read_burst_length = 2 max_write_burst_length = \
    32 num_read_outstanding = 2 num_write_outstanding = 16

#pragma HLS array_partition variable = result_buffers dim = 1
#pragma HLS interface ap_memory port = result_buffers
#pragma HLS resource variable = result_buffers core = RAM_1P latency = 5

#pragma HLS array_partition variable = freed_result_buffer_streams complete
#pragma HLS array_partition variable = filled_result_buffer_streams complete

    task_index_t smem_results_insertion_index = 0, smem_results_extraction_index = 0;
    task_queue_index_t num_entries_ahead = 0;
    bool insertion_index_has_changed;

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
        insertion_index_has_changed = false;
        num_entries_ahead = smem_results_insertion_index - smem_results_extraction_index;

        // Ensure that the host result buffer has at least one free slot for each smem core
        if (num_entries_ahead > (SMEM_RESULT_BUFFER_NUM_ENTRIES - NUM_SMEM_CORES)) {
            smem_results_extraction_index = get_smem_results_extraction_index(host_mem, runtime_status_control_addr);
            num_entries_ahead = smem_results_insertion_index - smem_results_extraction_index;

            while (num_entries_ahead >= (SMEM_RESULT_BUFFER_NUM_ENTRIES - NUM_SMEM_CORES)) {
                for (int i = 0; i < 10000; i++)
                    ap_wait();
                smem_results_extraction_index =
                    get_smem_results_extraction_index(host_mem, runtime_status_control_addr);
                num_entries_ahead = smem_results_insertion_index - smem_results_extraction_index;
            }
        }

        for (int current_smem_core_group = 0; current_smem_core_group < NUM_SMEM_CORES_PER_RESULT_BUFFER;
             current_smem_core_group++) {
            snap_membus_1024_t host_result_buffer[NUM_HOST_RESULT_BUFFERS]
                                                 [NUM_HOST_BWT_INTERVAL_VECTOR_CACHE_LINES_1024];
#pragma HLS array_partition variable = host_result_buffer complete
            bwt_interval_vector_index_t host_result_buffer_end_index[NUM_HOST_RESULT_BUFFERS] = {0};
#pragma HLS array_partition variable = host_result_buffer_end_index complete

            for (int current_host_result_buffer = 0; current_host_result_buffer < NUM_HOST_RESULT_BUFFERS;
                 current_host_result_buffer++) {
#pragma HLS unroll
                int current_completion_stream =
                    current_smem_core_group * NUM_HOST_RESULT_BUFFERS + current_host_result_buffer;

                host_result_buffer_end_index[current_host_result_buffer] = get_results_from_result_buffer(
                    freed_result_buffer_streams[current_completion_stream],
                    filled_result_buffer_streams[current_completion_stream],
                    result_buffers[current_completion_stream],
                    host_result_buffer[current_host_result_buffer]);
            }

            for (int current_host_result_buffer = 0; current_host_result_buffer < NUM_HOST_RESULT_BUFFERS;
                 current_host_result_buffer++) {
// #pragma HLS pipeline
                if (host_result_buffer_end_index[current_host_result_buffer] > 0) {
                    // Write results to host
                    copy_smem_results_to_host(
                        host_mem,
                        runtime_status_control_addr,
                        smem_results_insertion_index % SMEM_RESULT_BUFFER_NUM_ENTRIES,
                        host_result_buffer[current_host_result_buffer],
                        host_result_buffer_end_index[current_host_result_buffer]);

                    smem_results_insertion_index++;
                    insertion_index_has_changed = true;
                }
            }
        }
        if (insertion_index_has_changed)
            set_smem_results_insertion_index(host_mem, runtime_status_control_addr, smem_results_insertion_index);
    }
}
