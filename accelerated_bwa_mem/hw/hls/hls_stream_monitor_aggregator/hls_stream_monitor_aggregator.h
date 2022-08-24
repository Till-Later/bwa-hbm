#ifndef ACCELERATED_BWA_MEM_HLS_SMEM_TASK_SCHEDULER_H
#define ACCELERATED_BWA_MEM_HLS_SMEM_TASK_SCHEDULER_H

#include <ap_int.h>

#include "action_aligner.h"
#include "hls_action_reg.h"

#define NUM_STREAM_COUNTERS 3
#define NUM_ENTRIES_PER_CHANNEL_8 (NUM_STREAM_COUNTERS * 6)
#define NUM_ENTRIES_PER_CHANNEL_32 (NUM_STREAM_COUNTERS * 2)

void stream_monitor_aggregator(
    uint32_t monitor_data[NUM_STREAM_MONITORS * NUM_ENTRIES_PER_CHANNEL_32],
    hls::stream<bool>& termination_signal_stream,
    uint8_t const monitor_channel[NUM_STREAM_MONITORS][NUM_ENTRIES_PER_CHANNEL_8]);

#endif  //ACCELERATED_BWA_MEM_HLS_SMEM_TASK_SCHEDULER_H
