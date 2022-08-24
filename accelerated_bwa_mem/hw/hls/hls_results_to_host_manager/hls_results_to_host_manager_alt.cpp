#include "hls_results_to_host_manager.h"

#include "action_aligner.h"
#include "hls_bwt_definitions.h"
#include "hls_definitions.h"
#include "hls_stream_processing.h"

task_index_t get_smem_results_extraction_index(snap_membus_1024_t* gmem, snapu64_t runtime_status_control_addr) {
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

void result_buffer_to_host(
    snap_membus_1024_t* host_mem,
    const snapu64_t runtime_status_control_addr,
    task_index_t& smem_results_insertion_index,
    filled_result_buffer_stream_element result,
    accelerator_bwt_interval_vector_cacheline_t
        accelerator_result_buffer[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128]) {
    snap_membus_1024_t* host_result_buffer = host_mem
        + (((runtime_status_control_addr + SMEM_RESULTS_OFFSET)
            + ((smem_results_insertion_index % SMEM_RESULT_BUFFER_NUM_ENTRIES) << 11))
           >> ADDR_RIGHT_SHIFT_1024);

    for (int8_t interval_index = 0; interval_index < result.results_end_index; interval_index += DW256PERDW1024) {
        snap_membus_1024_t buffer_1024_cacheline = 0;
#pragma HLS pipeline
        for (int dw256counter = 0; dw256counter < DW256PERDW1024; dw256counter++) {
            // if (interval_index >= results_end_index) continue;
            accelerator_bwt_interval_vector_cacheline_t accelerator_cacheline =
                accelerator_result_buffer[interval_index + dw256counter];

            host_bwt_interval_vector_cacheline_t host_cacheline = 0;
            if (interval_index == 0) {
                // No conversion needed for metadata, only extend length to host_bwt_interval_vector_cacheline_t::width implicitly
                host_cacheline(accelerator_bwt_interval_vector_cacheline_t::width - 1, 0) = accelerator_cacheline;
            } else {
                host_cacheline(63, 0) = (uint64_t)accelerator_cacheline(33, 0);
                host_cacheline(127, 64) = (uint64_t)accelerator_cacheline(67, 34);
                host_cacheline(191, 128) = (uint64_t)accelerator_cacheline(101, 68);
                host_cacheline(223, 192) = (uint32_t)accelerator_cacheline(114, 102);
                host_cacheline(255, 224) = (uint32_t)accelerator_cacheline(127, 115);
            }

            SLICE(buffer_1024_cacheline, dw256counter, host_bwt_interval_vector_cacheline_t::width) = host_cacheline;
        }
        host_result_buffer[interval_index >> 2] = buffer_1024_cacheline;
    }
}

void results_to_host_manager(
    snap_membus_1024_t* host_mem,
    const snapu64_t runtime_status_control_addr,
    accelerator_bwt_interval_vector_cacheline_t
        result_buffers[NUM_SMEM_KERNELS]
                      [ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES * NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    hls::stream<accelerator_result_buffer_index_t> freed_result_buffer_streams[NUM_SMEM_KERNELS],
    ap_stream<filled_result_buffer_stream_element> filled_result_buffer_streams[NUM_SMEM_KERNELS],
    hls::stream<bool>& termination_signal_stream) {
#pragma HLS interface ap_ctrl_hs port = return

#pragma HLS interface m_axi port = host_mem max_read_burst_length = 2 max_write_burst_length = \
    16 num_read_outstanding = 2 num_write_outstanding = 16

#pragma HLS array_partition variable = result_buffers dim = 1
#pragma HLS interface ap_memory port = result_buffers
#pragma HLS resource variable = result_buffers core = RAM_1P latency = 3

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
        if (num_entries_ahead > (SMEM_RESULT_BUFFER_NUM_ENTRIES - NUM_SMEM_KERNELS)) {
            smem_results_extraction_index = get_smem_results_extraction_index(host_mem, runtime_status_control_addr);
            num_entries_ahead = smem_results_insertion_index - smem_results_extraction_index;

            while (num_entries_ahead >= (SMEM_RESULT_BUFFER_NUM_ENTRIES - NUM_SMEM_KERNELS)) {
                for (int i = 0; i < 10000; i++)
                    ap_wait();
                smem_results_extraction_index =
                    get_smem_results_extraction_index(host_mem, runtime_status_control_addr);
                num_entries_ahead = smem_results_insertion_index - smem_results_extraction_index;
            }
        }

        for (int current_completion_stream = 0; current_completion_stream < NUM_SMEM_KERNELS;
             current_completion_stream++) {
            if (filled_result_buffer_streams[current_completion_stream].empty()
                || freed_result_buffer_streams[current_completion_stream].full())
                continue;

            smem_results_insertion_index++;
            insertion_index_has_changed = true;

            filled_result_buffer_stream_element result;
            filled_result_buffer_streams[current_completion_stream] >> result;

            accelerator_bwt_interval_vector_cacheline_t
                result_buffer[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128];
            for (int interval_index = 0; interval_index < result.results_end_index; interval_index++) {
#pragma HLS pipeline
                result_buffer[interval_index] =
                    result_buffers[current_completion_stream]
                                  [result.result_buffer_index * NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128
                                   + interval_index];
            }

            result_buffer_to_host(
                host_mem, runtime_status_control_addr, smem_results_insertion_index, result, result_buffer);

            freed_result_buffer_streams[current_completion_stream] << result.result_buffer_index;
        }
        if (insertion_index_has_changed)
            set_smem_results_insertion_index(host_mem, runtime_status_control_addr, smem_results_insertion_index);
    }
}
