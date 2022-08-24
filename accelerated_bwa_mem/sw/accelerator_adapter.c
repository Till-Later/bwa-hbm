#include "accelerator_adapter.h"

#include <sys/mman.h>

#include <assert.h>
#include <endian.h>
#include <errno.h>
#include <limits.h>
#include <locale.h>
#include <malloc.h>
#include <osnap_hls_if.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "accelerator_performance_counters.h"
#include "bwa/bntseq.h"
#include "bwa/bwt.h"
#include "bwa/kvec.h"

#define debug_log(fmt, ...) \
    do { \
        fprintf(stderr, "\033[0;33m" fmt "\033[0m", ##__VA_ARGS__); \
    } while (0)

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

static inline void* malloc_page_aligned(size_t size) {
    unsigned int page_size = sysconf(_SC_PAGESIZE);
    void* ptr = memalign(page_size, SNAP_ROUND_UP(size, SNAP_MEMBUS_WIDTH));
    memset(ptr, '\0', SNAP_ROUND_UP(size, SNAP_MEMBUS_WIDTH));
    return ptr;
}

static void snap_prepare_aligner(
    struct snap_job* cjob,
    aligner_job_t* ajob,
    uint32_t* bwt_addr,
    uint32_t bwt_size_bytes,
    runtime_status_control_t* runtime_status_control,
    bwtint_t bwt_primary,
    bwtint_t bwt_L2[5],
    uint32_t split_width,
    uint32_t split_len,
    uint32_t min_seed_len) {

    assert(sizeof(*ajob) <= SNAP_JOBSIZE);  // SNAP_JOBSIZE is only 96 Bytes, despite comment
    memset(ajob, 0, sizeof(*ajob));

    ajob->bwt_addr = (uint64_t)bwt_addr;
    ajob->bwt_size = bwt_size_bytes;

    ajob->runtime_status_control_addr = (uint64_t)runtime_status_control;

    ajob->bwt_primary = bwt_primary;
    memcpy(ajob->bwt_L2, bwt_L2, sizeof(bwtint_t) * 5);

    ajob->split_width = split_width;
    ajob->split_len = split_len;
    ajob->min_seed_len = min_seed_len;

    snap_job_set(cjob, ajob, sizeof(*ajob), NULL, 0);
}

stream_monitor_data_t accelerator_read_monitors(accelerator_t* this) {
    stream_monitor_data_t monitor_data;
    for (int current_monitor_index = 0; current_monitor_index < NUM_STREAM_MONITORS; current_monitor_index++) {
        snap_action_read64(
            this->card,
            STREAM_MONITORS_BASE_ADDRESS + (sizeof(stream_counter_t) * current_monitor_index),
            &monitor_data.counters[current_monitor_index].active_cycles);
        snap_action_read64(
            this->card,
            STREAM_MONITORS_BASE_ADDRESS + (sizeof(stream_counter_t) * current_monitor_index) + sizeof(uint64_t),
            &monitor_data.counters[current_monitor_index].master_stall_cycles);
        snap_action_read64(
            this->card,
            STREAM_MONITORS_BASE_ADDRESS + (sizeof(stream_counter_t) * current_monitor_index) + 2 * sizeof(uint64_t),
            &monitor_data.counters[current_monitor_index].idle_or_slave_stall_cycles);
    }

    return monitor_data;
}

void accelerator_init(accelerator_t* this) {
    // Allocate the card that will be used
    if (this->card_no == 0)
        snprintf(this->device, sizeof(this->device) - 1, "IBM,oc-snap");
    else
        snprintf(this->device, sizeof(this->device) - 1, "/dev/ocxl/IBM,oc-snap.000%d:00:00.1.0", this->card_no);

    this->card = snap_card_alloc_dev(this->device, SNAP_VENDOR_ID_IBM, SNAP_DEVICE_ID_SNAP);

    if (this->card == NULL) {
        fprintf(stderr, "err: failed to open card %u: %s\n", this->card_no, strerror(errno));
        fprintf(stderr, "\n==> Did you consider running this command using sudo? <==\n");
        accelerator_destroy(this);
        exit(1);
    }

    this->action = snap_attach_action(this->card, ACTION_TYPE, this->action_irq, this->ACCELERATOR_TIMEOUT);

    if (this->action == NULL) {
        fprintf(stderr, "err: failed to attach action %u: %s\n", this->card_no, strerror(errno));
        accelerator_destroy(this);
        exit(1);
    }

    if (this->action_irq) snap_action_assign_irq(this->action, ACTION_IRQ_SRC_LO);

    pthread_mutex_init(&this->completed_tasks_mutex, NULL);
    pthread_mutex_init(&this->free_chunk_index_stack_mutex, NULL);
    pthread_cond_init(&this->has_free_chunk_index_condition, NULL);

    // Init runtime_status_control
    this->runtime_status_control = (runtime_status_control_t*)snap_malloc(sizeof(runtime_status_control_t));
    this->runtime_status_control->scheduled_sequence_chunk_tasks_insertion_index = 0;
    this->runtime_status_control->completed_tasks_extraction_index = 0;
    this->runtime_status_control->scheduled_sequence_chunk_tasks_extraction_index = 0;
    this->runtime_status_control->completed_tasks_insertion_index = 0;

    this->task_offset = 0;
    this->completed_tasks_pending_extraction_index = 0;
}

void accelerator_init_bwt(accelerator_t* this, bwt_t* bwt) {
    // TODO-TILL: Integrate memory alignment into existing index creation instead of copying here!
    this->bwt_size = bwt->bwt_size;
    this->accelerator_bwt = (uint32_t*)malloc_page_aligned(this->bwt_size * sizeof(uint32_t));
    memcpy(this->accelerator_bwt, bwt->bwt, this->bwt_size * sizeof(uint32_t));
    this->bwt_primary = bwt->primary;
    memcpy(this->bwt_L2, bwt->L2, sizeof(bwtint_t) * 5);
}

void accelerator_start(accelerator_t* this, uint32_t split_width, uint32_t split_len, uint32_t min_seed_len) {
    snap_prepare_aligner(
        &this->cjob,
        &this->ajob,
        this->accelerator_bwt,
        this->bwt_size,
        this->runtime_status_control,
        this->bwt_primary,
        this->bwt_L2,
        split_width,
        split_len,
        min_seed_len);

    int rc = snap_action_sync_execute_job_set_regs(this->action, &this->cjob);
    if (rc != 0) {
        fprintf(stderr, "err: Unable to set action registers.");
        accelerator_destroy(this);
        exit(1);
    }

    int is_idle = snap_action_is_idle(this->action, &rc);
    if (!is_idle) {
        fprintf(stderr, "Accelerator not idle. Exiting.\n");
        accelerator_destroy(this);
        exit(1);
    }

    snap_action_start(this->action);
}

task_index_t accelerator_push_sequence_chunk_task(accelerator_t* this, sequence_chunk_task_t task) {
    task_index_t ticket = this->runtime_status_control->scheduled_sequence_chunk_tasks_insertion_index;

    // Wait for free slot in task queue
    while (ticket - this->runtime_status_control->scheduled_sequence_chunk_tasks_extraction_index
           >= NUM_SEQUENCE_CHUNKS)
        usleep(100);

    // Insert Task into Queue
    this->runtime_status_control->scheduled_sequence_chunk_tasks[ticket % NUM_SEQUENCE_CHUNKS] = task;
    this->runtime_status_control->scheduled_sequence_chunk_tasks_insertion_index++;

    return ticket;
}

sequence_chunk_index_t get_free_chunk_index(accelerator_t* this) {
    pthread_mutex_lock(&this->free_chunk_index_stack_mutex);
    while (this->free_chunk_index_stack_size == 0)
        pthread_cond_wait(&this->has_free_chunk_index_condition, &this->free_chunk_index_stack_mutex);
    sequence_chunk_index_t chunk_index = this->free_chunk_index_stack[--this->free_chunk_index_stack_size];
    pthread_mutex_unlock(&this->free_chunk_index_stack_mutex);
    return chunk_index;
}

void* accelerator_schedule_sequence_chunks(void* data) {
    collect_smems_task_t* collect_smems_task = (collect_smems_task_t*)data;
    accelerator_t* this = collect_smems_task->this;
    bseq1_t* current_sequence;

    char* sequence_chunk = malloc_page_aligned(sizeof(char) * SEQUENCE_CHUNK_SIZE);
    int sequence_chunk_offset = 0;
    int sequence_chunk_num_sequences = 0;
    sequence_chunk_index_t current_sequence_chunk_index;

    for (int current_sequence_index = 0; current_sequence_index < collect_smems_task->n_seqs;
         current_sequence_index++) {

        current_sequence = &collect_smems_task->seqs[current_sequence_index];

        if (sequence_chunk_offset + current_sequence->l_seq + 1 >= SEQUENCE_CHUNK_SIZE) {
            current_sequence_chunk_index = get_free_chunk_index(this);
            collect_smems_task->current_sequence_chunks[current_sequence_chunk_index] = (sequence_chunk_task_t){
                (uint64_t)sequence_chunk, sequence_chunk_num_sequences, current_sequence_chunk_index, {}};
            collect_smems_task->task_end_index_in_sequence_chunk[current_sequence_chunk_index] = current_sequence_index;
            accelerator_push_sequence_chunk_task(
                &Accelerator, collect_smems_task->current_sequence_chunks[current_sequence_chunk_index]);

            sequence_chunk = malloc_page_aligned(sizeof(char) * SEQUENCE_CHUNK_SIZE);
            sequence_chunk_num_sequences = 0;
            sequence_chunk_offset = 0;
        }
        memcpy(&sequence_chunk[sequence_chunk_offset], current_sequence->seq, current_sequence->l_seq);
        sequence_chunk[sequence_chunk_offset + current_sequence->l_seq] = '$';

        sequence_chunk_offset += current_sequence->l_seq + 1;
        sequence_chunk_num_sequences++;
    }

    current_sequence_chunk_index = get_free_chunk_index(this);
    collect_smems_task->current_sequence_chunks[current_sequence_chunk_index] = (sequence_chunk_task_t){
        (uint64_t)sequence_chunk, sequence_chunk_num_sequences, current_sequence_chunk_index, {}};
    collect_smems_task->task_end_index_in_sequence_chunk[current_sequence_chunk_index] = collect_smems_task->n_seqs;
    accelerator_push_sequence_chunk_task(
        &Accelerator, collect_smems_task->current_sequence_chunks[current_sequence_chunk_index]);

    return NULL;
}

bool accelerator_get_next_smem_result_range(
    collect_smems_task_t* collect_smems_task,
    struct pending_extractions_queue_entry** entry_ptr) {
    accelerator_t* this = collect_smems_task->this;

    pthread_mutex_lock(&this->completed_tasks_mutex);
    while (collect_smems_task->remaining_sequences) {
        if (this->completed_tasks_pending_extraction_index
            < this->runtime_status_control->completed_tasks_insertion_index) {
            task_index_t num_extracted_tasks =
                MIN(this->runtime_status_control->completed_tasks_insertion_index
                        - this->completed_tasks_pending_extraction_index,
                    SMEM_RESULT_BUFFER_NUM_ENTRIES / NUM_ADAPTER_THREADS);
            *entry_ptr = malloc(sizeof(struct pending_extractions_queue_entry));
            (*entry_ptr)->start_index = this->completed_tasks_pending_extraction_index;
            (*entry_ptr)->end_index = this->completed_tasks_pending_extraction_index + num_extracted_tasks;
            memset(&(*entry_ptr)->completed_tasks_per_sequence_chunk, 0, NUM_SEQUENCE_CHUNKS * sizeof(task_index_t));
            (*entry_ptr)->is_active = true;
            STAILQ_INSERT_TAIL(&collect_smems_task->pending_extractions_queue_head, *entry_ptr, entries);

            this->completed_tasks_pending_extraction_index += num_extracted_tasks;

            pthread_mutex_unlock(&this->completed_tasks_mutex);
            return true;
        }
        pthread_mutex_unlock(&this->completed_tasks_mutex);
        usleep(10);
        pthread_mutex_lock(&this->completed_tasks_mutex);
    }

    pthread_mutex_unlock(&this->completed_tasks_mutex);
    return false;
}

void accelerator_release_next_smem_result_range(
    collect_smems_task_t* collect_smems_task,
    struct pending_extractions_queue_entry* entry) {
    accelerator_t* this = collect_smems_task->this;

    pthread_mutex_lock(&this->completed_tasks_mutex);

    entry->is_active = false;
    struct pending_extractions_queue_entry* head_entry =
        STAILQ_FIRST(&collect_smems_task->pending_extractions_queue_head);

    task_index_t completed_tasks = 0;
    while (head_entry != NULL && !head_entry->is_active) {
        this->runtime_status_control->completed_tasks_extraction_index = head_entry->end_index;

        for (int i = 0; i < NUM_SEQUENCE_CHUNKS; i++) {
            sequence_chunk_task_t* current_sequence_chunk = &collect_smems_task->current_sequence_chunks[i];

            if (current_sequence_chunk->num_sequences == 0) continue;

            completed_tasks += head_entry->completed_tasks_per_sequence_chunk[i];
            current_sequence_chunk->num_sequences -= head_entry->completed_tasks_per_sequence_chunk[i];

            if (current_sequence_chunk->num_sequences == 0) {
                free((char*)current_sequence_chunk->host_address);
                {
                    pthread_mutex_lock(&this->free_chunk_index_stack_mutex);
                    if (this->free_chunk_index_stack_size == 0)
                        pthread_cond_signal(&this->has_free_chunk_index_condition);
                    this->free_chunk_index_stack[this->free_chunk_index_stack_size++] =
                        current_sequence_chunk->chunk_index;
                    pthread_mutex_unlock(&this->free_chunk_index_stack_mutex);
                }
            }
        }

        STAILQ_REMOVE_HEAD(&collect_smems_task->pending_extractions_queue_head, entries);
        free(head_entry);
        head_entry = STAILQ_FIRST(&collect_smems_task->pending_extractions_queue_head);
    }
    collect_smems_task->remaining_sequences -= completed_tasks;
    pthread_mutex_unlock(&this->completed_tasks_mutex);
}

sequence_chunk_index_t task_index_to_sequence_chunk_index(
    collect_smems_task_t* collect_smems_task,
    task_index_t task_index) {
    sequence_chunk_index_t sequence_chunk_index = 0;
    task_index_t supremum_task_index = UINT_MAX;

    for (sequence_chunk_index_t current_sequence_chunk_index = 0; current_sequence_chunk_index < NUM_SEQUENCE_CHUNKS;
         current_sequence_chunk_index++) {
        task_index_t current_sequence_chunk_end_index =
            collect_smems_task->task_end_index_in_sequence_chunk[current_sequence_chunk_index];
        if (current_sequence_chunk_end_index < supremum_task_index && current_sequence_chunk_end_index > task_index) {
            supremum_task_index = current_sequence_chunk_end_index;
            sequence_chunk_index = current_sequence_chunk_index;
        }
    }

    return sequence_chunk_index;
}

void* accelerator_process_smem_results(void* data) {
    collect_smems_task_t* collect_smems_task = (collect_smems_task_t*)data;
    accelerator_t* this = collect_smems_task->this;

    struct pending_extractions_queue_entry* entry;
    while (accelerator_get_next_smem_result_range(collect_smems_task, &entry)) {
        for (task_index_t current_task_queue_index = entry->start_index; current_task_queue_index < entry->end_index;
             current_task_queue_index++) {
            volatile host_bwt_interval_vector_t* smem_results = this->runtime_status_control->completed_tasks
                + ((current_task_queue_index) % SMEM_RESULT_BUFFER_NUM_ENTRIES);
            while (smem_results->m.task_index == 0 && smem_results->m.end_index == 0
                   && smem_results->m.is_last_task == 0) {
                fprintf(stderr, "Got invalid result metadata from acclerator. Exiting.\n");
                exit(1);
            }
            task_index_t task_index = smem_results->m.task_index - this->task_offset;

            // debug_log(
            //     "Extraction index %d, task %d: Received %s%d smems.\n",
            //     this->runtime_status_control->completed_tasks_extraction_index,
            //     task_index,
            //     smem_results->m.is_last_task ? "last " : "",
            //     smem_results->m.end_index);

            while (atomic_flag_test_and_set(&collect_smems_task->accelerator_mems[task_index].lock))
                ;

            if (smem_results->m.has_task_failed) {
                // Mark task as failed
                accelerator_performance_counters_log_failed_task();
                collect_smems_task->accelerator_mems[task_index].has_task_failed = 1;
            } else {
                int required_size =
                    kv_size(collect_smems_task->accelerator_mems[task_index]) + smem_results->m.end_index;
                if (required_size > kv_max(collect_smems_task->accelerator_mems[task_index])) {
                    kv_resize(
                        bwtintv_t,
                        collect_smems_task->accelerator_mems[task_index],
                        2 * required_size);
                }

                for (int i = 0; i < smem_results->m.end_index; i++) {
                    host_bwt_interval_t accelerator_interval = smem_results->a[i];
                    bwtintv_t host_interval = {
                        {accelerator_interval.x[0], accelerator_interval.x[1], accelerator_interval.x[2]},
                        ((uint64_t)accelerator_interval.query_begin_position << 32)
                            | accelerator_interval.query_end_position};
                    // debug_log(
                    //     "%d: x[0]: %05lu, x[1]: %05lu, x[2]: %05lu, info_lo: %05d, info_up: %05d\n",
                    //     i,
                    //     accelerator_interval.x[0],
                    //     accelerator_interval.x[1],
                    //     accelerator_interval.x[2],
                    //     accelerator_interval.query_begin_position,
                    //     accelerator_interval.query_end_position);

                    kv_push(bwtintv_t, collect_smems_task->accelerator_mems[task_index], host_interval);
                }
            }

            atomic_flag_clear(&collect_smems_task->accelerator_mems[task_index].lock);

            if (smem_results->m.is_last_task) {
                sequence_chunk_index_t chunk_index = task_index_to_sequence_chunk_index(collect_smems_task, task_index);
                entry->completed_tasks_per_sequence_chunk[chunk_index]++;
            }
        }

        accelerator_release_next_smem_result_range(collect_smems_task, entry);
    }

    return NULL;
}

bwtintv_v* accelerator_collect_smems(accelerator_t* this, int n_seqs, bseq1_t* seqs) {
    accelerator_performance_counters_log_start(accelerator_read_monitors(this));
    {
        pthread_mutex_lock(&this->free_chunk_index_stack_mutex);
        for (sequence_chunk_index_t i = 0; i < NUM_SEQUENCE_CHUNKS; i++)
            this->free_chunk_index_stack[i] = i;
        this->free_chunk_index_stack_size = NUM_SEQUENCE_CHUNKS;
        pthread_mutex_unlock(&this->free_chunk_index_stack_mutex);
    }

    collect_smems_task_t collect_smems_task = {};
    collect_smems_task.this = this;
    collect_smems_task.n_seqs = n_seqs;
    collect_smems_task.remaining_sequences = n_seqs;
    collect_smems_task.seqs = seqs;
    memset(&collect_smems_task.task_end_index_in_sequence_chunk, 0, NUM_SEQUENCE_CHUNKS * sizeof(task_index_t));
    STAILQ_INIT(&collect_smems_task.pending_extractions_queue_head);
    collect_smems_task.accelerator_mems = calloc(n_seqs, sizeof(bwtintv_v));

    for (task_index_t task_index = 0; task_index < n_seqs; task_index++) {
        kv_init(collect_smems_task.accelerator_mems[task_index]);
        atomic_flag_clear(&collect_smems_task.accelerator_mems[task_index].lock);
    }

    pthread_t processor_threads[NUM_ADAPTER_THREADS];
    for (int i = 0; i < NUM_ADAPTER_THREADS; i++) {
        pthread_create(&processor_threads[i], NULL, accelerator_process_smem_results, (void*)&collect_smems_task);
    }

    accelerator_schedule_sequence_chunks((void*)&collect_smems_task);

    for (int i = 0; i < NUM_ADAPTER_THREADS; i++) {
        pthread_join(processor_threads[i], NULL);
    }

    //    printf("############### smems from accelerator ###############\n");
    //    for (int i = 0; i < n_seqs; i++) {
    //        printf("##### sequence %d #####\n", i);
    //        for (int j = 0; j < collect_smems_task.accelerator_mems[i].n; j++) {
    //            printf(
    //                "%d: x[0]: %05lu, x[1]: %05lu, x[2]: %05lu, start: %05d, end: %05d\n",
    //                j,
    //                collect_smems_task.accelerator_mems[i].a[j].x[0],
    //                collect_smems_task.accelerator_mems[i].a[j].x[1],
    //                collect_smems_task.accelerator_mems[i].a[j].x[2],
    //                (uint32_t)(collect_smems_task.accelerator_mems[i].a[j].info >> 32),
    //                (uint32_t)collect_smems_task.accelerator_mems[i].a[j].info);
    //        }
    //    }

    pthread_cond_destroy(&this->has_free_chunk_index_condition);

    this->task_offset += n_seqs;
    // accelerator_print_monitors(this);
    accelerator_performance_counters_log_done(accelerator_read_monitors(this));
    return collect_smems_task.accelerator_mems;
}

void accelerator_print_monitors(accelerator_t* this) {
    uint32_t reg = 0;
    for (int i = 0; i < 2; i++) {
        snap_action_read32(this->card, 0x110 + 4 * i, &reg);
        debug_log("reg 0x110 + %u: %u (%08x)\n", i, reg, reg);
    }

    char* channel_names[] = {
        "task_stream_source",
        "task_stream_sink",
        "freed_result_buffer_stream_source",
        "freed_result_buffer_stream_sink",
        "filled_result_buffer_stream_source",
        "filled_result_buffer_stream_sink",
        "req_bwt_position_stream_source",
        "req_bwt_position_stream_sink",
        "ret_bwt_entry_stream_source",
        "ret_bwt_entry_stream_sink",
    };

    debug_log("NUM_STREAM_MONITORS: %d\n", NUM_STREAM_MONITORS);
    stream_monitor_data_t monitor_data = accelerator_read_monitors(this);

    setlocale(LC_NUMERIC, "");
    for (int current_monitor_index = 0; current_monitor_index < NUM_STREAM_MONITORS; current_monitor_index++) {
        stream_counter_t counters = monitor_data.counters[current_monitor_index];
        uint64_t all_cycles =
            counters.active_cycles + counters.master_stall_cycles + counters.idle_or_slave_stall_cycles;
        debug_log(
            "Monitor %d (%s, %d):\n",
            current_monitor_index,
            channel_names[current_monitor_index % 10],
            current_monitor_index / 10);
        debug_log(
            "\tactive:           %'12ld\t\t\t(%.2lf%)\n",
            counters.active_cycles,
            (double)counters.active_cycles / all_cycles * 100);
        debug_log(
            "\tmaster stall:     %'12ld\t\t\t(%.2lf%)\n",
            counters.master_stall_cycles,
            (double)counters.master_stall_cycles / all_cycles * 100);
        debug_log(
            "\tidle/slave stall: %'12ld\t\t\t(%.2lf%)\n",
            counters.idle_or_slave_stall_cycles,
            (double)counters.idle_or_slave_stall_cycles / all_cycles * 100);
    }
}

void accelerator_wait_for_completion(accelerator_t* this) {
    // accelerator_print_monitors(this);

    // Issue Termination Task
    accelerator_push_sequence_chunk_task(this, (sequence_chunk_task_t){0xffffffffffffffff, 0, 0, {}});

    int rc = snap_action_sync_execute_job_check_completion(this->action, &this->cjob, this->ACCELERATOR_TIMEOUT);
    if (rc != 0) {
        fprintf(stderr, "err: job execution %d: %s!\n", rc, strerror(errno));
        accelerator_destroy(this);
        exit(1);
    }
}

void accelerator_destroy(accelerator_t* this) {
    snap_detach_action(this->action);
    snap_card_free(this->card);

    free(this->accelerator_bwt);

    pthread_mutex_destroy(&this->completed_tasks_mutex);
    pthread_mutex_destroy(&this->free_chunk_index_stack_mutex);

    free(this->runtime_status_control);
}

int snap_action_read64(struct snap_card* card, uint64_t offset, uint64_t* data) {
    uint32_t data_upper, data_lower;
    int rc = snap_action_read32(card, offset, &data_lower);
    rc |= snap_action_read32(card, offset + 4, &data_upper);
    *data = ((uint64_t)data_upper << 32) | data_lower;
    return rc;
}

int snap_action_write64(struct snap_card* card, uint64_t offset, uint64_t data) {
    int rc = 0;
    rc |= snap_action_write32(card, (uint64_t)offset, (uint32_t)(data & 0xFFFFFFFF));
    rc |= snap_action_write32(card, (uint64_t)offset + sizeof(uint32_t), (uint32_t)(data >> 32));
    return rc;
}

accelerator_t Accelerator =
    {.card_no = 4, .card = NULL, .action = NULL, .action_irq = 0x0, .ACCELERATOR_TIMEOUT = 14400};
