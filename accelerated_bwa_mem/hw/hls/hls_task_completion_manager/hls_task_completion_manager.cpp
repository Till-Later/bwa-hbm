#include "hls_task_completion_manager.h"

void extract_results(
    host_bwt_interval_vector_metadata_t host_metadata,
    smem_kernel_pipeline_index_t pipeline_index,
    accelerator_bwt_interval_vector_cacheline_t smem_buffer[NUM_SMEM_BUFFER_ENTRIES_128],
    accelerator_bwt_interval_vector_cacheline_t
        host_result_buffer[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128]) {

    host_result_buffer[0] = to<accelerator_bwt_interval_vector_cacheline_t>(host_metadata);

    int8_t result_buffer_index = 1;
    for (int8_t interval_index = 0; interval_index < host_metadata.end_index; interval_index++, result_buffer_index++) {
#pragma HLS pipeline
        accelerator_bwt_interval accelerator_interval(GET_INTERVAL(smem_buffer, pipeline_index, interval_index));
        host_result_buffer[result_buffer_index] =
            static_cast<accelerator_bwt_interval_vector_cacheline_t>(accelerator_interval);
    }
}

local_sequence_index_t get_next_first_pass_start_position(
    accelerator_bwt_interval_vector_cacheline_t smem_buffer[NUM_SMEM_BUFFER_ENTRIES_128],
    smem_kernel_pipeline_index_t pipeline_index,
    bwt_interval_vector_index_t results_start_index,
    bwt_interval_vector_index_t results_end_index,
    local_sequence_index_t task_start_position) {
    if (results_start_index != results_end_index) {
        // Schedule new task after end position of longest smem result
        accelerator_bwt_interval interval = GET_INTERVAL(smem_buffer, pipeline_index, results_end_index - 1);
        return interval.query_end_position;
    } else {
        // Previous task has no smem results (because first base was ambiguous)
        // => schedule new task at next position
        return task_start_position + 1;
    }
}

bwt_interval_vector_index_t write_results_and_schedule_follow_up_tasks(
    const snapu32_t split_width,
    const snapu32_t split_len,
    const snapu32_t min_seed_len,
    accelerator_bwt_interval_vector_cacheline_t host_result_buffer[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    accelerator_bwt_interval_vector_cacheline_t smem_buffer[NUM_SMEM_BUFFER_ENTRIES_128],
    ap_stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream) {
    smem_kernel_pipeline_index_t pipeline_index;
    completed_task_stream >> pipeline_index;

    accelerator_bwt_interval_vector_metadata_1 metadata_1 = static_cast<accelerator_bwt_interval_vector_metadata_1>(
        smem_buffer[pipeline_index * NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128]);
    accelerator_bwt_interval_vector_metadata_2 metadata_2 = static_cast<accelerator_bwt_interval_vector_metadata_2>(
        smem_buffer[pipeline_index * NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 + 1]);

    if (metadata_1.task_has_failed) {
        // Move failed tasks to host without further processing
        host_bwt_interval_vector_metadata_t host_metadata;
        host_metadata.task_index = metadata_2.task_index;
        host_metadata.end_index = 0;
        host_metadata.is_last_task = true;
        host_metadata.has_task_failed = true;

        host_result_buffer[0] = to<accelerator_bwt_interval_vector_cacheline_t>(host_metadata);

        // Free interval vector
        freed_pipeline_index_stream << pipeline_index;

        return 1;
    }


    bool has_next_second_pass_task = false;
    follow_up_task task;
    task.pipeline_index = pipeline_index;
    task.sequence_offset = metadata_1.sequence_offset;
    task.sequence_length = metadata_1.sequence_length;

    bwt_interval_vector_index_t results_start_index = metadata_1.start_index;
    bwt_interval_vector_index_t results_end_index = metadata_1.end_index;
    bwt_interval_vector_index_t unflushed_intervals_end_index = metadata_2.unflushed_intervals_end_index;
    bwt_interval_vector_index_t unscheduled_second_pass_tasks_start_index =
        metadata_2.unscheduled_second_pass_tasks_start_index;

    if (metadata_2.is_first_pass_task) {
        metadata_2.next_first_pass_task_start_position = get_next_first_pass_start_position(
            smem_buffer, pipeline_index, results_start_index, results_end_index, metadata_1.start_position);

        bool remove_from_front = true;

        // Partition smem results into "unflushed intervals" (move to front)
        // and "unscheduled second pass intervals" (move to end).
        // Create a second pass task, if available.
        while (results_start_index < results_end_index) {
#pragma HLS pipeline
            accelerator_bwt_interval interval;
#pragma HLS data_pack variable = interval
            if (remove_from_front) {
                interval = GET_INTERVAL(smem_buffer, pipeline_index, results_start_index);
                results_start_index++;
            } else {
                interval = GET_INTERVAL(smem_buffer, pipeline_index, results_end_index - 1);
                results_end_index--;
            }
            local_sequence_index_t interval_length = interval.query_end_position - interval.query_begin_position;

            if (interval_length < min_seed_len) {
                // Interval is too short for further processing => filter out
                continue;
            }

            bool is_eligible_for_second_pass = interval_length >= split_len && interval.x[2] <= split_width;

            // To prevent collisions, remove next result from front,
            // iff the current result has been inserted in front of result vector
            remove_from_front = !is_eligible_for_second_pass || !has_next_second_pass_task;

            if (is_eligible_for_second_pass) {
                // We need to create a second pass task now or store it for later scheduling
                if (has_next_second_pass_task) {
                    // Next second pass task already exists => store as unscheduled second pass interval
                    // I assume that each task generates no more than 31 intervals.
                    // Therefore we can assume at least one unused entry behind end_index.
                    unscheduled_second_pass_tasks_start_index--;
                    SET_INTERVAL(smem_buffer, pipeline_index, unscheduled_second_pass_tasks_start_index, interval);
                    continue;
                } else {
                    // Is first eligible interval => create Task and append to unflushed intervals
                    has_next_second_pass_task = true;
                    task.start_position = (interval.query_begin_position + interval.query_end_position) >> 1;
                    task.min_intv = interval.x[2] + 1;
                }
            }
            // Interval is not eligible for second pass OR Is FIRST eligible interval
            // => append to unflushed intervals
            SET_INTERVAL(smem_buffer, pipeline_index, unflushed_intervals_end_index, interval);
            unflushed_intervals_end_index++;
        }
    } else {  // is second pass task
        // Append smem results to unflushed intervals
        while (results_start_index < results_end_index) {
#pragma HLS pipeline
            accelerator_bwt_interval interval;
#pragma HLS data_pack variable = interval
            interval = GET_INTERVAL(smem_buffer, pipeline_index, results_start_index);
            results_start_index++;

            local_sequence_index_t interval_length = interval.query_end_position - interval.query_begin_position;
            if (interval_length < min_seed_len) {
                // Interval is too short for further processing => filter out
                continue;
            }

            SET_INTERVAL(smem_buffer, pipeline_index, unflushed_intervals_end_index, interval);
            unflushed_intervals_end_index++;
        }

        // Create next second pass task from interval at end of vector (and it append to unflushed intervals)
        if (unscheduled_second_pass_tasks_start_index < NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_ENTRIES) {
            accelerator_bwt_interval interval;

            interval = GET_INTERVAL(smem_buffer, pipeline_index, unscheduled_second_pass_tasks_start_index);
            unscheduled_second_pass_tasks_start_index++;

            SET_INTERVAL(smem_buffer, pipeline_index, unflushed_intervals_end_index, interval);
            unflushed_intervals_end_index++;

            has_next_second_pass_task = true;
            task.start_position = (interval.query_begin_position + interval.query_end_position) >> 1;
            task.min_intv = interval.x[2] + 1;
        }
    }

    bool has_follow_up_task = has_next_second_pass_task;
    if (!has_next_second_pass_task && metadata_2.next_first_pass_task_start_position < metadata_1.sequence_length) {
        // If no second pass task was created, try to create next first pass task
        has_follow_up_task = true;
        task.start_position = metadata_2.next_first_pass_task_start_position;
        task.min_intv = 1;
    }

    if (has_follow_up_task) {
        bwt_interval_vector_index_t result_buffer_end_index = 0;
        if (unscheduled_second_pass_tasks_start_index - unflushed_intervals_end_index < 31) {
            // Ensure that each task has space for at least 31 smem results
            host_bwt_interval_vector_metadata_t host_metadata;
            host_metadata.task_index = metadata_2.task_index;
            host_metadata.end_index = unflushed_intervals_end_index;
            host_metadata.is_last_task = false;

            extract_results(host_metadata, pipeline_index, smem_buffer, host_result_buffer);
            result_buffer_end_index = unflushed_intervals_end_index + 1;

            unflushed_intervals_end_index = 0;
        }

        metadata_2.is_first_pass_task = !has_next_second_pass_task;
        metadata_2.unflushed_intervals_end_index = unflushed_intervals_end_index;
        metadata_2.unscheduled_second_pass_tasks_start_index = unscheduled_second_pass_tasks_start_index;
        smem_buffer[pipeline_index * NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 + 1] =
            static_cast<accelerator_bwt_interval_vector_metadata_2::cacheline_t>(metadata_2);

        task.min_start_index = unflushed_intervals_end_index;
        task.max_end_index = unscheduled_second_pass_tasks_start_index;

        follow_up_task_stream << task;

        return result_buffer_end_index;
    } else {
        // no first pass task was created => write unflushed intervals to host
        host_bwt_interval_vector_metadata_t host_metadata;
        host_metadata.task_index = metadata_2.task_index;
        host_metadata.end_index = unflushed_intervals_end_index;
        host_metadata.is_last_task = true;

        extract_results(host_metadata, pipeline_index, smem_buffer, host_result_buffer);

        // Free interval vector
        freed_pipeline_index_stream << pipeline_index;

        return unflushed_intervals_end_index + 1;
    }
}

void task_completion_manager(
    const snapu32_t split_width,
    const snapu32_t split_len,
    const snapu32_t min_seed_len,
    ap_stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream,
    accelerator_bwt_interval_vector_cacheline_t smem_buffer[NUM_SMEM_BUFFER_ENTRIES_128],
    accelerator_bwt_interval_vector_cacheline_t result_buffer[ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES]
                                                             [NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128],
    hls::stream<accelerator_result_buffer_index_t>& freed_result_buffer_stream,
    ap_stream<filled_result_buffer_stream_element>& filled_result_buffer_stream,
    hls::stream<bool>& termination_signal_stream) {
#pragma HLS interface ap_ctrl_hs port = return
#pragma HLS resource variable = smem_buffer core = RAM_1P latency = 4
#pragma HLS interface ap_memory port = smem_buffer
#pragma HLS resource variable = result_buffer core = RAM_1P latency = 3
#pragma HLS interface ap_memory port = result_buffer
    accelerator_result_buffer_index_t free_result_buffer_index_stack[ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES] =
        IOTA_ACCELERATOR_RESULT_BUFFER_ENTRIES;
    accelerator_result_buffer_index_t free_result_buffer_index_stack_size = ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES;

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
        accelerator_result_buffer_index_t freed_result_buffer_index;
        if (freed_result_buffer_stream.read_nb(freed_result_buffer_index)) {
            free_result_buffer_index_stack[free_result_buffer_index_stack_size++] = freed_result_buffer_index;
            continue;
        }
        if (!free_result_buffer_index_stack_size || filled_result_buffer_stream.full() || completed_task_stream.empty()
            || freed_pipeline_index_stream.full())
            continue;


        filled_result_buffer_stream_element result;
        result.result_buffer_index = free_result_buffer_index_stack[--free_result_buffer_index_stack_size];
        result.results_end_index = write_results_and_schedule_follow_up_tasks(
            split_width,
            split_len,
            min_seed_len,
            result_buffer[result.result_buffer_index],
            smem_buffer,
            completed_task_stream,
            follow_up_task_stream,
            freed_pipeline_index_stream);

        if (result.results_end_index > 0) {
            filled_result_buffer_stream << result;
        } else {
            free_result_buffer_index_stack[free_result_buffer_index_stack_size++] = result.result_buffer_index;
        }
    }
}