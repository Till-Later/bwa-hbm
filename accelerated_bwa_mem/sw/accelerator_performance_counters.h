#ifndef ACCELERATOR_PERFORMANCE_COUNTERS_H
#define ACCELERATOR_PERFORMANCE_COUNTERS_H


#include <stdint.h>
#include <stdatomic.h>

#include "action_aligner.h"

#ifdef ACCELERATOR_PERFORMANCE_COUNTERS

#define MAX_PROCESS_ITERATIONS 200

struct accelerator_iteration_data {
    stream_monitor_data_t start_monitors, done_monitors;
    uint64_t start_time, done_time;
};
typedef struct accelerator_iteration_data accelerator_iteration_data_t;

struct accelerator_performance_counter_data {
    atomic_uint num_failed_tasks;
    uint64_t program_start_time, program_done_time;
    uint64_t num_accelerator_iterations;
    accelerator_iteration_data_t accelerator_iterations[MAX_PROCESS_ITERATIONS];
};
typedef struct accelerator_performance_counter_data accelerator_performance_counter_data_t;

void accelerator_performance_counters_init();
void accelerator_performance_counters_log_start(stream_monitor_data_t monitor_data);
void accelerator_performance_counters_log_done(stream_monitor_data_t monitor_data);
void accelerator_performance_counters_log_failed_task();
void accelerator_performance_counters_write_results();

extern accelerator_performance_counter_data_t global_accelerator_performance_counter_data;

#else

void accelerator_performance_counters_init();
void accelerator_performance_counters_log_start(stream_monitor_data_t monitor_data);
void accelerator_performance_counters_log_done(stream_monitor_data_t monitor_data);
void accelerator_performance_counters_log_failed_task();
void accelerator_performance_counters_write_results();

#endif

#endif // ACCELERATOR_PERFORMANCE_COUNTERS_H