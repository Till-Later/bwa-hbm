#ifndef BWA_PERFORMANCE_COUNTERS_H
#define BWA_PERFORMANCE_COUNTERS_H

#include <stdbool.h>

#include "bwt.h"

#ifdef PERFORMANCE_COUNTERS

#include <stdatomic.h>
#include <stdint.h>

#define MAX_PROCESS_ITERATIONS 200

#ifndef PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS
#define PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS 4
#endif

#ifndef PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS
#define PERFORMANCE_COUNTERS_ACCESS_CHUNK_OFFSET_BITS 7
#endif

struct process_iteration_event {
    uint8_t is_start_event;
    long long int time;
    int step;
};
typedef struct process_iteration_event process_iteration_event_t;


struct performance_counter_data
{
    long long int program_start_time, program_done_time;
    atomic_llong num_process_iteration_events;
    process_iteration_event_t process_iteration_events[4 * MAX_PROCESS_ITERATIONS];

#ifndef PERFORMANCE_COUNTERS_LOW_OVERHEAD
    atomic_llong num_bwt_forward_accesses;
    atomic_llong num_bwt_backward_accesses;

    atomic_llong num_first_pass_tasks;
    atomic_llong num_second_pass_tasks;

    atomic_llong bwt_forward_extend_calls;
    atomic_llong bwt_backward_extend_calls;

    atomic_llong max_first_pass_num_intervals;
    atomic_llong max_second_pass_num_intervals;
    atomic_llong max_overall_num_intervals;
    atomic_llong bwt_forward_access_chunks[1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS];
    atomic_llong bwt_backward_access_chunks[1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS];
    atomic_llong bwt_access_chunks[1 << PERFORMANCE_COUNTERS_ACCESS_CHUNK_WIDTH_BITS];
#endif

#ifdef PERFORMANCE_COUNTERS_PERF
    int l1d_cache_miss_fd;
    int l1d_cache_access_fd;

    atomic_llong first_second_pass_l1d_cache_misses;
    atomic_llong first_second_pass_l1d_cache_accesses;

    atomic_llong third_pass_l1d_cache_misses;
    atomic_llong third_pass_l1d_cache_accesses;
#endif
};
typedef struct performance_counter_data performance_counter_data_t;

extern performance_counter_data_t global_performance_counter_data;

#endif

void performance_counters_init();
void performance_counters_write_results();

void performance_counters_log_process_iteration_start(int step);
void performance_counters_log_process_iteration_done(int step);

void performance_counters_log_bwt_access(bwtint_t k, int is_back);
void performance_counters_log_task(bool ist_first_pass_task);
void performance_counters_log_bwt_extend_call();
void performance_counters_log_first_pass_num_intervals(int n);
void performance_counters_log_second_pass_num_intervals(int n);
void performance_counters_log_overall_num_intervals(int n);

void performance_counters_log_first_second_pass_seeding_start();
void performance_counters_log_first_second_pass_seeding_done();

void performance_counters_log_third_pass_seeding_start();
void performance_counters_log_third_pass_seeding_done();

#endif  //BWA_PERFORMANCE_COUNTERS_H
