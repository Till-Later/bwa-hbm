
#include "accelerator_performance_counters.h"

#ifdef ACCELERATOR_PERFORMANCE_COUNTERS

#include <sys/time.h>

#include <stdio.h>


#define ACCELERATOR_PERFORMANCE_COUNTERS_FD 4
#define accpcprint(...) dprintf(ACCELERATOR_PERFORMANCE_COUNTERS_FD, __VA_ARGS__);
#define accpcprintd(VAR_NAME) dprintf(ACCELERATOR_PERFORMANCE_COUNTERS_FD, "\"" #VAR_NAME "\": %d,\n", global_accelerator_performance_counter_data.VAR_NAME);
#define accpcprintlu(VAR_NAME) dprintf(ACCELERATOR_PERFORMANCE_COUNTERS_FD, "\"" #VAR_NAME "\": %lu,\n", global_accelerator_performance_counter_data.VAR_NAME);

accelerator_performance_counter_data_t global_accelerator_performance_counter_data = {0};

uint64_t accelerator_performance_counters_get_time() {
    struct timeval timecheck;
    gettimeofday(&timecheck, NULL);
    return (long)timecheck.tv_sec * 1000 + (long)timecheck.tv_usec / 1000;
}

void accelerator_performance_counters_init() {
    atomic_init(&global_accelerator_performance_counter_data.num_accelerator_iterations, 0);
    global_accelerator_performance_counter_data.program_start_time = accelerator_performance_counters_get_time();
}

void accelerator_performance_counters_log_start(stream_monitor_data_t monitor_data) {
    int current_iteration = global_accelerator_performance_counter_data.num_accelerator_iterations;

    global_accelerator_performance_counter_data.accelerator_iterations[current_iteration].start_monitors = monitor_data;
    global_accelerator_performance_counter_data.accelerator_iterations[current_iteration].start_time =
        accelerator_performance_counters_get_time();

}

void accelerator_performance_counters_log_done(stream_monitor_data_t monitor_data) {
    int current_iteration = global_accelerator_performance_counter_data.num_accelerator_iterations;

    global_accelerator_performance_counter_data.accelerator_iterations[current_iteration].done_monitors = monitor_data;
    global_accelerator_performance_counter_data.accelerator_iterations[current_iteration].done_time =
        accelerator_performance_counters_get_time();

    global_accelerator_performance_counter_data.num_accelerator_iterations++;
}

void accelerator_performance_counters_write_stream_monitor(stream_monitor_data_t monitor_data) {    
    const char* monitor_names[] = {
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

    accpcprint("[");
    for (int current_core = 0; current_core < NUM_SMEM_CORES; current_core++) {
        accpcprint("{");
        for (int channel = 0; channel < 10; channel++) {
            accpcprint(
                "\"%s\": {\"active\": %ld, \"master_stall\": %ld, \"idle_or_slave_stall\": %ld}%c",
                monitor_names[channel],
                monitor_data.counters[current_core * 10 + channel].active_cycles,
                monitor_data.counters[current_core * 10 + channel].master_stall_cycles,
                monitor_data.counters[current_core * 10 + channel].idle_or_slave_stall_cycles, channel + 1 == 10 ? ' ' : ',');
        }
        accpcprint("}%c", current_core + 1 == NUM_SMEM_CORES ? ' ' : ',');
    }
    accpcprint("]");
}


void accelerator_performance_counters_log_failed_task() {
    atomic_fetch_add(&global_accelerator_performance_counter_data.num_failed_tasks, 1);
}

void accelerator_performance_counters_write_results() {
    global_accelerator_performance_counter_data.program_done_time = accelerator_performance_counters_get_time();

    accpcprint("{\n");
    accpcprintlu(num_accelerator_iterations);
    accpcprintlu(program_start_time);
    accpcprintlu(program_done_time);
    accpcprintd(num_failed_tasks);

    accpcprint("\"accelerator_iterations\": [");
    for (int i = 0; i < global_accelerator_performance_counter_data.num_accelerator_iterations; i++) {
        accpcprint("{");
        accpcprint(
            "\"start_time\": %ld,", global_accelerator_performance_counter_data.accelerator_iterations[i].start_time);
        accpcprint(
            "\"done_time\": %ld,", global_accelerator_performance_counter_data.accelerator_iterations[i].done_time);
        accpcprint("\"start_monitors\": ");
        accelerator_performance_counters_write_stream_monitor(
            global_accelerator_performance_counter_data.accelerator_iterations[i].start_monitors);
        accpcprint(",");
        accpcprint("\"done_monitors\": ");
        accelerator_performance_counters_write_stream_monitor(
            global_accelerator_performance_counter_data.accelerator_iterations[i].done_monitors);
        accpcprint("}%c", i + 1  == global_accelerator_performance_counter_data.num_accelerator_iterations ? ' ' : ',');
    }
    accpcprint("]\n");

    accpcprint("}\n");
}

#else

void accelerator_performance_counters_init() {}
void accelerator_performance_counters_log_start(stream_monitor_data_t monitor_data) {}
void accelerator_performance_counters_log_done(stream_monitor_data_t monitor_data) {}
void accelerator_performance_counters_log_failed_task() {}
void accelerator_performance_counters_write_results() {}

#endif