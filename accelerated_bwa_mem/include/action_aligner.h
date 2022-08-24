/*
 * Copyright 2019 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#ifndef __ACTION_ALIGNER_H__
#define __ACTION_ALIGNER_H__

#include <osnap_types.h>

#include "../sw/bwa/bwt.h"

#ifdef __cplusplus
extern "C" {
#endif

#define ACTION_TYPE 0x0ACCE701
#define RELEASE_LEVEL 0x00000004

#ifndef NUM_SMEM_CORES
#define NUM_SMEM_CORES 8
#endif

#if (NUM_SMEM_CORES > 4 && (NUM_SMEM_CORES & 3 != 0))
#error "NUM_SMEM_CORES has to be smaller than 4 or a multiple of 4!"
#endif

#define BYTES_PER_DATAWORD_1024 128
#define BYTES_PER_DATAWORD_256 32
#define DW256PERDW1024 (BPERDW_1024 / BPERDW_256)

#define NUM_SEQUENCE_CHUNKS_BITS 4
#define NUM_SEQUENCE_CHUNKS (1 << NUM_SEQUENCE_CHUNKS_BITS)

#define NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER_BITS 16
#define NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER (1 << NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER_BITS)

#define NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_CHUNK \
    (NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER / NUM_SEQUENCE_CHUNKS)

#define SEQUENCE_CHUNK_SIZE (NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_CHUNK * BYTES_PER_DATAWORD_256)

#define SMEM_RESULT_BUFFER_NUM_ENTRIES_BITS 14
#define SMEM_RESULT_BUFFER_NUM_ENTRIES (1 << SMEM_RESULT_BUFFER_NUM_ENTRIES_BITS)
#define SMEM_RESULT_BUFFER_ENTRY_MASK (SMEM_RESULT_BUFFER_NUM_ENTRIES - 1)

typedef uint8_t sequence_chunk_index_t;
typedef uint16_t task_queue_index_t;
typedef uint32_t task_index_t;

struct host_bwt_interval
{
    bwtint_t x[3];
    uint32_t query_begin_position, query_end_position;  // [query_begin_position, query_end_position[
};

typedef struct host_bwt_interval host_bwt_interval_t;

struct host_bwt_interval_vector_metadata
{
    task_index_t task_index;
    int8_t end_index;
    uint8_t is_last_task;
    uint8_t has_task_failed;
    char offset[25];
};
typedef struct host_bwt_interval_vector_metadata host_bwt_interval_vector_metadata_t;

struct host_bwt_interval_vector
{
    host_bwt_interval_vector_metadata_t m;
    host_bwt_interval_t a[63];
}; /* 2048 Bytes */
typedef struct host_bwt_interval_vector host_bwt_interval_vector_t;

struct sequence_chunk_task
{
    uint64_t host_address;
    uint32_t num_sequences;
    sequence_chunk_index_t chunk_index;
    char offset[3];
}; /* 16 Bytes */
typedef struct sequence_chunk_task sequence_chunk_task_t;

#define SCHEDULED_SEQUENCE_CHUNK_TASKS_INSERTION_INDEX_OFFSET (0)
#define SMEM_RESULTS_EXTRACTION_INDEX_OFFSET (SCHEDULED_SEQUENCE_CHUNK_TASKS_INSERTION_INDEX_OFFSET + BYTES_PER_DATAWORD_1024)
#define SCHEDULED_SEQUENCE_CHUNK_TASKS_OFFSET (SMEM_RESULTS_EXTRACTION_INDEX_OFFSET + BYTES_PER_DATAWORD_1024)
#define SCHEDULED_SEQUENCE_CHUNK_TASKS_EXTRACTION_INDEX_OFFSET (SCHEDULED_SEQUENCE_CHUNK_TASKS_OFFSET + (sizeof(sequence_chunk_task_t) * NUM_SEQUENCE_CHUNKS))
#define SMEM_RESULTS_INSERTION_INDEX_OFFSET (SCHEDULED_SEQUENCE_CHUNK_TASKS_EXTRACTION_INDEX_OFFSET + BYTES_PER_DATAWORD_1024)
#define SMEM_RESULTS_OFFSET (SMEM_RESULTS_INSERTION_INDEX_OFFSET + BYTES_PER_DATAWORD_1024)

struct runtime_status_control
{
    // written by host, read by accelerator
    volatile task_index_t scheduled_sequence_chunk_tasks_insertion_index;
    char offset_1[BYTES_PER_DATAWORD_1024 - sizeof(task_index_t)];
    volatile task_index_t completed_tasks_extraction_index;
    char offset_2[BYTES_PER_DATAWORD_1024 - sizeof(task_index_t)];
    volatile sequence_chunk_task_t scheduled_sequence_chunk_tasks[NUM_SEQUENCE_CHUNKS];
    // char offset_3[BYTES_PER_DATAWORD_1024 - sizeof(sequence_chunk_task_t) * NUM_SEQUENCE_CHUNKS];
    // read by host, written by accelerator
    volatile task_index_t scheduled_sequence_chunk_tasks_extraction_index;
    char offset_4[BYTES_PER_DATAWORD_1024 - sizeof(task_index_t)];
    volatile task_index_t completed_tasks_insertion_index;
    char offset_5[BYTES_PER_DATAWORD_1024 - sizeof(task_index_t)];
    volatile host_bwt_interval_vector_t completed_tasks[SMEM_RESULT_BUFFER_NUM_ENTRIES];
};
typedef struct runtime_status_control runtime_status_control_t;

struct aligner_job
{
    uint64_t bwt_addr;
    uint64_t runtime_status_control_addr;

    bwtint_t bwt_primary; /* 8 Bytes */
    bwtint_t bwt_L2[5];   /* 40 Bytes */

    uint32_t bwt_size;  // Size in number of uint32_t

    uint32_t split_width;
    uint32_t split_len;
    uint32_t min_seed_len;
}; /* 80 Bytes */

typedef struct aligner_job aligner_job_t;

struct stream_counter {
    uint64_t active_cycles;
    uint64_t master_stall_cycles;
    uint64_t idle_or_slave_stall_cycles;
};
typedef struct stream_counter stream_counter_t;

#define NUM_STREAM_MONITORS (10 * NUM_SMEM_CORES)
#define STREAM_MONITORS_BASE_ADDRESS 0x200
struct stream_monitor_data {
    stream_counter_t counters[NUM_STREAM_MONITORS];
};

typedef struct stream_monitor_data stream_monitor_data_t;

#ifdef __cplusplus
}
#endif

#endif /* __ACTION_ALIGNER_H__ */
