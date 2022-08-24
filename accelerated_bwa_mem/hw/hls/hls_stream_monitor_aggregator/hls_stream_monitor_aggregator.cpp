#include "hls_stream_monitor_aggregator.h"

#include "hls_ap_utils.h"

void stream_monitor_aggregator(
    uint32_t aggregated_monitor_counters[NUM_STREAM_MONITORS * NUM_ENTRIES_PER_CHANNEL_32],
    hls::stream<bool>& termination_signal_stream,
    uint8_t const monitor_channel[NUM_STREAM_MONITORS][NUM_ENTRIES_PER_CHANNEL_8]) {
#pragma HLS INTERFACE ap_ctrl_hs port = return

#pragma HLS resource variable = aggregated_monitor_counters core = RAM_1P latency = 2
#pragma HLS resource variable = monitor_channel core = RAM_1P latency = 3
#pragma HLS array_partition variable = monitor_channel complete dim = 1

    bool terminate = false;
    do {
        for (int current_monitor_index = 0; current_monitor_index < NUM_STREAM_MONITORS; current_monitor_index++) {
            for (int current_counter_index = 0; current_counter_index < NUM_STREAM_COUNTERS; current_counter_index++) {
#pragma HLS pipeline
                snapu64_t current_counter = 0;
                for (int current_counter_word_index = 0; current_counter_word_index < 6; current_counter_word_index++) {
#pragma HLS pipeline
                    SLICE(current_counter, current_counter_word_index, 8) =
                        monitor_channel[current_monitor_index][current_counter_index * 6 + current_counter_word_index];
                }
                aggregated_monitor_counters
                    [(NUM_ENTRIES_PER_CHANNEL_32 * current_monitor_index) + (2 * current_counter_index)] =
                        (uint32_t)current_counter;
                aggregated_monitor_counters
                    [(NUM_ENTRIES_PER_CHANNEL_32 * current_monitor_index) + (2 * current_counter_index) + 1] =
                        (uint32_t)(current_counter >> 32);
            }
        }
    } while (!termination_signal_stream.read_nb(terminate) || !terminate);
}
