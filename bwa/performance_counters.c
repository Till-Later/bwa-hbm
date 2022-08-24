#include "performance_counters.h"

#ifdef PERFORMANCE_COUNTERS

#ifdef PERFORMANCE_COUNTERS_PERF
#include <linux/perf_event.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>

#include <errno.h>
#include <string.h>
#include <unistd.h>

#endif

#include <sys/time.h>

#include <stdio.h>
#include <stdlib.h>


#define PERFORMANCE_COUNTERS_FD 3
#define perfprint(...) dprintf(PERFORMANCE_COUNTERS_FD, __VA_ARGS__);
#define perfprintvar(VAR_NAME) \
    dprintf(PERFORMANCE_COUNTERS_FD, "\"" #VAR_NAME "\": %lld,\n", global_performance_counter_data.VAR_NAME);

#define MIN(a, b) (((a) < (b)) ? (a) : (b))
#define MAX(a, b) (((a) > (b)) ? (a) : (b))

performance_counter_data_t global_performance_counter_data = {0};

uint64_t performance_counters_get_time() {
    struct timeval timecheck;
    gettimeofday(&timecheck, NULL);
    return (long)timecheck.tv_sec * 1000 + (long)timecheck.tv_usec / 1000;
}

#ifdef PERFORMANCE_COUNTERS_PERF
static int64_t
perf_event_open(struct perf_event_attr* hw_event, pid_t pid, int cpu, int group_fd, unsigned long flags) {
    int ret;

    ret = syscall(__NR_perf_event_open, hw_event, pid, cpu, group_fd, flags);
    return ret;
}
#endif

void performance_counters_init() {
    global_performance_counter_data.program_start_time = performance_counters_get_time();
}

int compare(const void* a, const void* b) {
    return (*(int*)b - *(int*)a);
}

void performance_counters_write_results() {
    global_performance_counter_data.program_done_time = performance_counters_get_time();
    perfprint("{\n");

#ifdef PERFORMANCE_COUNTERS_PERF
    perfprintvar(first_second_pass_l1d_cache_misses);
    perfprintvar(first_second_pass_l1d_cache_accesses);
    perfprintvar(third_pass_l1d_cache_misses);
    perfprintvar(third_pass_l1d_cache_accesses);
#endif

    perfprintvar(program_start_time);
    perfprintvar(program_done_time);

    perfprint("\"process_iteration_events\": [");
    for (int i = 0; i < global_performance_counter_data.num_process_iteration_events; i++) {
        perfprint(
            "{\"is_start_event\": %d, \"time\": %lld, \"step\": %d",
            global_performance_counter_data.process_iteration_events[i].is_start_event,
            global_performance_counter_data.process_iteration_events[i].time,
            global_performance_counter_data.process_iteration_events[i].step);
        perfprint("}%c", i + 1 == global_performance_counter_data.num_process_iteration_events ? ' ' : ',');
    }
#ifdef PERFORMANCE_COUNTERS_LOW_OVERHEAD
    perfprint("]\n");
#else
    perfprint("],\n");

    perfprintvar(num_first_pass_tasks);
    perfprintvar(num_second_pass_tasks);

    perfprintvar(num_bwt_forward_accesses);
    perfprintvar(num_bwt_backward_accesses);

    perfprintvar(bwt_forward_extend_calls);
    perfprintvar(bwt_backward_extend_calls);

    perfprintvar(max_first_pass_num_intervals);
    perfprintvar(max_second_pass_num_intervals);
    perfprintvar(max_overall_num_intervals);

#ifdef PERFORMANCE_COUNTERS_GET_MOST_FREQUENT_ACCESS_CHUNKS
    qsort(
        global_performance_counter_data.bwt_forward_access_chunks,
        (1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS),
        sizeof(atomic_llong),
        compare);

    perfprint(
        "\"most_frequent_bwt_forward_access_chunks\": [%lld",
        global_performance_counter_data.bwt_forward_access_chunks[0]);
    for (int i = 1; i < 2048; i++)
        perfprint(", %lld", global_performance_counter_data.bwt_forward_access_chunks[i]);
    perfprint("],\n");

    qsort(
        global_performance_counter_data.bwt_backward_access_chunks,
        (1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS),
        sizeof(atomic_llong),
        compare);

    perfprint(
        "\"most_frequent_bwt_backward_access_chunks\": [%lld",
        global_performance_counter_data.bwt_backward_access_chunks[0]);
    for (int i = 1; i < 2048; i++)
        perfprint(", %lld", global_performance_counter_data.bwt_backward_access_chunks[i]);
    perfprint("],\n");

    qsort(
        global_performance_counter_data.bwt_access_chunks,
        (1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS),
        sizeof(atomic_llong),
        compare);

    perfprint("\"most_frequent_bwt_access_chunks\": [%lld", global_performance_counter_data.bwt_access_chunks[0]);
    for (int i = 1; i < 2048; i++)
        perfprint(", %lld", global_performance_counter_data.bwt_access_chunks[i]);
    perfprint("]\n");

#else
    perfprint("\"bwt_forward_access_chunks\": [%lld", global_performance_counter_data.bwt_forward_access_chunks[0]);
    for (int i = 1; i < (1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS); i++)
        perfprint(", %lld", global_performance_counter_data.bwt_forward_access_chunks[i]);
    perfprint("],\n");
    perfprint("\"bwt_backward_access_chunks\": [%lld", global_performance_counter_data.bwt_backward_access_chunks[0]);
    for (int i = 1; i < (1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS); i++)
        perfprint(", %lld", global_performance_counter_data.bwt_backward_access_chunks[i]);
    perfprint("]\n");
#endif

#endif
    perfprint("}\n");
}

void performance_counters_log_process_iteration_start(int step) {
    long long insertion_index = atomic_fetch_add(&global_performance_counter_data.num_process_iteration_events, 1);
    global_performance_counter_data.process_iteration_events[insertion_index] =
        (process_iteration_event_t){1, performance_counters_get_time(), step};
}

void performance_counters_log_process_iteration_done(int step) {
    long long insertion_index = atomic_fetch_add(&global_performance_counter_data.num_process_iteration_events, 1);
    global_performance_counter_data.process_iteration_events[insertion_index] =
        (process_iteration_event_t){0, performance_counters_get_time(), step};
}

#ifndef PERFORMANCE_COUNTERS_LOW_OVERHEAD

void performance_counters_log_bwt_access(bwtint_t k, int is_back) {
    if (!is_back) {
        atomic_fetch_add(&global_performance_counter_data.num_bwt_forward_accesses, 1);
        // Each BWT Entry contains 128 Bases and is 64 Byte large
        atomic_fetch_add(
            &global_performance_counter_data.bwt_forward_access_chunks
                 [(k >> PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS)
                  & ((1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS) - 1)],
            1);
    } else {
        atomic_fetch_add(&global_performance_counter_data.num_bwt_backward_accesses, 1);
        // Each BWT Entry contains 128 Bases and is 64 Byte large
        atomic_fetch_add(
            &global_performance_counter_data.bwt_backward_access_chunks
                 [(k >> PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS)
                  & ((1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS) - 1)],
            1);
    }

    atomic_fetch_add(
        &global_performance_counter_data.bwt_access_chunks
             [(k >> PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS)
              & ((1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS) - 1)],
        1);
}

void performance_counters_log_task(bool ist_first_pass_task) {
    if (ist_first_pass_task) {
        atomic_fetch_add(&global_performance_counter_data.num_first_pass_tasks, 1);
    } else {
        atomic_fetch_add(&global_performance_counter_data.num_second_pass_tasks, 1);
    }
}

void performance_counters_log_bwt_extend_call(int is_back) {
    if (is_back) {
        atomic_fetch_add(&global_performance_counter_data.bwt_backward_extend_calls, 1);
    } else {
        atomic_fetch_add(&global_performance_counter_data.bwt_forward_extend_calls, 1);
    }
};

void performance_counters_log_first_pass_num_intervals(int n) {
    atomic_store(
        &global_performance_counter_data.max_first_pass_num_intervals,
        MAX(atomic_load(&global_performance_counter_data.max_first_pass_num_intervals), n));
}
void performance_counters_log_second_pass_num_intervals(int n) {
    atomic_store(
        &global_performance_counter_data.max_second_pass_num_intervals,
        MAX(atomic_load(&global_performance_counter_data.max_second_pass_num_intervals), n));
}

void performance_counters_log_overall_num_intervals(int n) {
    atomic_store(
        &global_performance_counter_data.max_overall_num_intervals,
        MAX(atomic_load(&global_performance_counter_data.max_overall_num_intervals), n));
}


#else

void performance_counters_log_bwt_access(bwtint_t k, int is_back) {}
void performance_counters_log_task(bool ist_first_pass_task) {}
void performance_counters_log_bwt_extend_call() {}
void performance_counters_log_first_pass_num_intervals(int n) {}
void performance_counters_log_second_pass_num_intervals(int n) {}
void performance_counters_log_overall_num_intervals(int n) {}

#endif

#else

void performance_counters_init() {}
void performance_counters_write_results() {}

void performance_counters_log_process_iteration_start(int step) {}
void performance_counters_log_process_iteration_done(int step) {}

void performance_counters_log_bwt_access(bwtint_t k, int is_back) {}
void performance_counters_log_task(bool ist_first_pass_task) {}
void performance_counters_log_bwt_extend_call() {}
void performance_counters_log_first_pass_num_intervals(int n) {}
void performance_counters_log_second_pass_num_intervals(int n) {}
void performance_counters_log_overall_num_intervals(int n) {}

#endif

#if defined(PERFORMANCE_COUNTERS_PERF) && defined(PERFORMANCE_COUNTERS)

void performance_counters_log_first_second_pass_seeding_start() {
    struct perf_event_attr event_1;
    memset(&event_1, 0, sizeof(struct perf_event_attr));
    event_1.type = PERF_TYPE_HW_CACHE;
    event_1.size = sizeof(struct perf_event_attr);
    event_1.config = PERF_COUNT_HW_CACHE_L1D | PERF_COUNT_HW_CACHE_OP_READ << 8 | PERF_COUNT_HW_CACHE_RESULT_MISS << 16;
    event_1.disabled = 1;
    event_1.exclude_kernel = 1;
    event_1.exclude_hv = 1;  // Don't count hypervisor events.

    global_performance_counter_data.l1d_cache_miss_fd = perf_event_open(&event_1, 0, -1, -1, 0);
    if (global_performance_counter_data.l1d_cache_miss_fd == -1) {
        fprintf(stderr, "Failed to setup perf events! %s\n", strerror(errno));
    }

    struct perf_event_attr event_2;
    memset(&event_2, 0, sizeof(struct perf_event_attr));
    event_2.type = PERF_TYPE_HW_CACHE;
    event_2.size = sizeof(struct perf_event_attr);
    event_2.config =
        PERF_COUNT_HW_CACHE_L1D | PERF_COUNT_HW_CACHE_OP_READ << 8 | PERF_COUNT_HW_CACHE_RESULT_ACCESS << 16;
    event_2.disabled = 1;
    event_2.exclude_kernel = 1;
    event_2.exclude_hv = 1;  // Don't count hypervisor events.

    global_performance_counter_data.l1d_cache_access_fd = perf_event_open(&event_2, 0, -1, -1, 0);

    ioctl(global_performance_counter_data.l1d_cache_miss_fd, PERF_EVENT_IOC_ENABLE, 0);
    ioctl(global_performance_counter_data.l1d_cache_access_fd, PERF_EVENT_IOC_ENABLE, 0);

    ioctl(global_performance_counter_data.l1d_cache_miss_fd, PERF_EVENT_IOC_RESET, 0);
    ioctl(global_performance_counter_data.l1d_cache_access_fd, PERF_EVENT_IOC_RESET, 0);
};

void performance_counters_log_first_second_pass_seeding_done() {
    int64_t misses = 0, accesses = 0;
    int ret;
    ret = read(global_performance_counter_data.l1d_cache_miss_fd, &misses, sizeof(long long));
    ret = read(global_performance_counter_data.l1d_cache_access_fd, &accesses, sizeof(long long));

    atomic_fetch_add(&global_performance_counter_data.first_second_pass_l1d_cache_misses, misses);
    atomic_fetch_add(&global_performance_counter_data.first_second_pass_l1d_cache_accesses, accesses);

    ioctl(global_performance_counter_data.l1d_cache_miss_fd, PERF_EVENT_IOC_DISABLE, 0);
    ioctl(global_performance_counter_data.l1d_cache_access_fd, PERF_EVENT_IOC_DISABLE, 0);

    close(global_performance_counter_data.l1d_cache_miss_fd);
    close(global_performance_counter_data.l1d_cache_access_fd);
};

void performance_counters_log_third_pass_seeding_start() {
    struct perf_event_attr event_1;
    memset(&event_1, 0, sizeof(struct perf_event_attr));
    event_1.type = PERF_TYPE_HW_CACHE;
    event_1.size = sizeof(struct perf_event_attr);
    event_1.config = PERF_COUNT_HW_CACHE_L1D | PERF_COUNT_HW_CACHE_OP_READ << 8 | PERF_COUNT_HW_CACHE_RESULT_MISS << 16;
    event_1.disabled = 1;
    event_1.exclude_kernel = 1;
    event_1.exclude_hv = 1;  // Don't count hypervisor events.

    global_performance_counter_data.l1d_cache_miss_fd = perf_event_open(&event_1, 0, -1, -1, 0);
    if (global_performance_counter_data.l1d_cache_miss_fd == -1) {
        fprintf(stderr, "Failed to setup perf events! %s\n", strerror(errno));
    }

    struct perf_event_attr event_2;
    memset(&event_2, 0, sizeof(struct perf_event_attr));
    event_2.type = PERF_TYPE_HW_CACHE;
    event_2.size = sizeof(struct perf_event_attr);
    event_2.config =
        PERF_COUNT_HW_CACHE_L1D | PERF_COUNT_HW_CACHE_OP_READ << 8 | PERF_COUNT_HW_CACHE_RESULT_ACCESS << 16;
    event_2.disabled = 1;
    event_2.exclude_kernel = 1;
    event_2.exclude_hv = 1;  // Don't count hypervisor events.

    global_performance_counter_data.l1d_cache_access_fd = perf_event_open(&event_2, 0, -1, -1, 0);

    ioctl(global_performance_counter_data.l1d_cache_miss_fd, PERF_EVENT_IOC_ENABLE, 0);
    ioctl(global_performance_counter_data.l1d_cache_access_fd, PERF_EVENT_IOC_ENABLE, 0);

    ioctl(global_performance_counter_data.l1d_cache_miss_fd, PERF_EVENT_IOC_RESET, 0);
    ioctl(global_performance_counter_data.l1d_cache_access_fd, PERF_EVENT_IOC_RESET, 0);
};

void performance_counters_log_third_pass_seeding_done() {
    int64_t misses = 0, accesses = 0;
    int ret;
    ret = read(global_performance_counter_data.l1d_cache_miss_fd, &misses, sizeof(int64_t));
    ret = read(global_performance_counter_data.l1d_cache_access_fd, &accesses, sizeof(int64_t));

    atomic_fetch_add(&global_performance_counter_data.third_pass_l1d_cache_misses, misses);
    atomic_fetch_add(&global_performance_counter_data.third_pass_l1d_cache_accesses, accesses);

    ioctl(global_performance_counter_data.l1d_cache_miss_fd, PERF_EVENT_IOC_DISABLE, 0);
    ioctl(global_performance_counter_data.l1d_cache_access_fd, PERF_EVENT_IOC_DISABLE, 0);

    close(global_performance_counter_data.l1d_cache_miss_fd);
    close(global_performance_counter_data.l1d_cache_access_fd);
};

#else

void performance_counters_log_first_second_pass_seeding_start(){};
void performance_counters_log_first_second_pass_seeding_done(){};

void performance_counters_log_third_pass_seeding_start(){};
void performance_counters_log_third_pass_seeding_done(){};

#endif