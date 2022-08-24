#ifndef ACCELERATED_BWA_MEM_FPGA_ADAPTER_H
#define ACCELERATED_BWA_MEM_FPGA_ADAPTER_H

#include <libosnap.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdatomic.h>
#include <unistd.h>
#include <sys/queue.h>

#include "action_aligner.h"
#include "bwa/bwa.h"
#include "bwa/bwt.h"

#define NUM_ADAPTER_THREADS 8

struct accelerator
{
    int card_no;
    char device[128];
    struct snap_card* card;
    struct snap_action* action;
    snap_action_flag_t action_irq;

    struct snap_job cjob;
    aligner_job_t ajob;
    runtime_status_control_t *runtime_status_control;
    task_index_t task_offset;
    task_index_t completed_tasks_pending_extraction_index;

    // BWT
    uint32_t* accelerator_bwt;
    uint32_t bwt_size;
    bwtint_t bwt_primary;  // S^{-1}(0), or the primary index of BWT
    bwtint_t bwt_L2[5];    // C(), cumulative count

    pthread_mutex_t completed_tasks_mutex;

    sequence_chunk_index_t free_chunk_index_stack[NUM_SEQUENCE_CHUNKS];
    sequence_chunk_index_t free_chunk_index_stack_size;
    pthread_mutex_t free_chunk_index_stack_mutex;
    pthread_cond_t has_free_chunk_index_condition;

    const int ACCELERATOR_TIMEOUT;
};
typedef struct accelerator accelerator_t;

struct pending_extractions_queue_entry {
    task_index_t start_index;
    task_index_t end_index;
    task_index_t completed_tasks_per_sequence_chunk[NUM_SEQUENCE_CHUNKS];
    bool is_active;
    STAILQ_ENTRY(pending_extractions_queue_entry) entries;
};

STAILQ_HEAD(pending_extractions_queue_head, pending_extractions_queue_entry);
typedef struct pending_extractions_queue_head pending_extractions_queue_head_t;

struct collect_smems_task {
    accelerator_t *this;
    int n_seqs;
    volatile int remaining_sequences;
    bseq1_t* seqs;
    sequence_chunk_task_t current_sequence_chunks[NUM_SEQUENCE_CHUNKS];
    task_index_t task_end_index_in_sequence_chunk[NUM_SEQUENCE_CHUNKS];
    pending_extractions_queue_head_t pending_extractions_queue_head;
    bwtintv_v* accelerator_mems;
};
typedef struct collect_smems_task collect_smems_task_t;

void accelerator_init(accelerator_t* this);
void accelerator_init_bwt(accelerator_t* this, bwt_t* bwt);
void accelerator_start(accelerator_t* this, uint32_t split_width, uint32_t split_len, uint32_t min_seed_len);
bwtintv_v* accelerator_collect_smems(accelerator_t* this, int n_seqs, bseq1_t* seqs);
void accelerator_print_monitors(accelerator_t* this);
void accelerator_wait_for_completion(accelerator_t* this);
void accelerator_destroy(accelerator_t* this);

int snap_action_read64(struct snap_card* card, uint64_t offset, uint64_t* data);
int snap_action_write64(struct snap_card* card, uint64_t offset, uint64_t data);

extern accelerator_t Accelerator;

#endif  //ACCELERATED_BWA_MEM_FPGA_ADAPTER_H
