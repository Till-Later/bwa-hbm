#ifndef ACCELERATED_BWA_MEM_HLS_SMEM_TASK_SCHEDULER_H
#define ACCELERATED_BWA_MEM_HLS_SMEM_TASK_SCHEDULER_H

#include <ap_int.h>

#include "action_aligner.h"
#include "hls_action_reg.h"
#include "hls_bwt_definitions.h"
#include "hls_definitions.h"
#include "hls_snap_1024.H"
#include "hls_stream_processing.h"
#include "hls_task.h"

// Has to be a fraction of NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER
#define HOST_SEQUENCE_COPY_BUFFER_SIZE 512  // Should exactly match size of 29 512x36 BRAMs
#define NUM_COPY_ITERATIONS_PER_SEQUENCE_CHUNK \
    (NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_CHUNK / (DW256PERDW1024 * HOST_SEQUENCE_COPY_BUFFER_SIZE))
#define NUM_TERMINATION_SIGNAL_STREAMS (3 * NUM_SMEM_CORES + 2)

#define NUM_SEQUENCE_CHUNK_TASKS_PER_DW1024 (BYTES_PER_DATAWORD_1024 / sizeof(sequence_chunk_task_t))

void smem_task_scheduler(
    snapu64_t runtime_status_control_addr,
    snap_membus_1024_t* gmem,
    ap_stream<task> smem_task_streams[NUM_SMEM_CORES],
    hls::stream<bool> termination_signal_streams[NUM_TERMINATION_SIGNAL_STREAMS]);

#endif  //ACCELERATED_BWA_MEM_HLS_SMEM_TASK_SCHEDULER_H
