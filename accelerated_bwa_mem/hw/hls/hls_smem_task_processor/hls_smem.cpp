#include "hls_smem.h"

#include <hls_stream.h>

#include "hls_ap_utils.h"
#include "hls_sequence_definitions.h"
#include "hls_stream_processing.h"

#define ACCELERATOR_BWT_SET_INTV(L2, metadata, ik) \
    ((ik).x[0] = L2[metadata.current_sequence_element] + 1, \
     (ik).x[2] = L2[metadata.current_sequence_element + 1] - L2[metadata.current_sequence_element], \
     (ik).x[1] = L2[3 - metadata.current_sequence_element] + 1, \
     (ik).query_begin_position = metadata.start_position, \
     (ik).query_end_position = metadata.start_position + 1)

#define GET_SEQUENCE_ELEMENT(query, index) \
    SLICE(query, index& SEQUENCE_READ_BUFFER_OFFSET_MASK, SEQUENCE_ELEMENT_SIZE_BITS)

void smem_forward_step1_prepare(
    ap_stream<task>& new_task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream,
    ap_uint<320> bwt_L2,
    hls::stream<sequence_request_element_t>& sequence_request_stream,
    hls::stream<sequence_section_t>& sequence_response_stream,
    smem_buffer_t& smem_buffer,
    ap_stream<smem_forward_extend_task>& forward_extend_task_stream,
    hls::stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    hls::stream<bool>& termination_signal_stream) {

    reference_index_t L2[NUM_REFERENCE_SYMBOLS + 1];
    for (int i = 0; i < NUM_REFERENCE_SYMBOLS + 1; i++) {
        L2[i] = bwt_L2(sizeof(reference_index_t) * 8 - 1, 0);
        bwt_L2 >>= sizeof(reference_index_t) * 8;
    }

    smem_kernel_pipeline_index_t free_pipeline_index_stack[SMEM_KERNEL_PIPELINE_DEPTH] =
        IOTA_SMEM_KERNEL_PIPELINE_DEPTH;
    smem_kernel_pipeline_index_t free_pipeline_index_stack_size = SMEM_KERNEL_PIPELINE_DEPTH;
    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
        smem_kernel_pipeline_index_t freed_pipeline_index;
        if (freed_pipeline_index_stream.read_nb(freed_pipeline_index)) {
            free_pipeline_index_stack[free_pipeline_index_stack_size++] = freed_pipeline_index;
            continue;
        }

        // Ensure that freed_pipeline_index_stream cannot stall due to stalling of forward_extend_task_stream
        if (forward_extend_task_stream.full()) continue;

        smem_kernel_pipeline_index_t pipeline_index;
        accelerator_bwt_interval_vector_metadata_1 smems_metadata_1;

        task new_task;
        follow_up_task follow_up_task;
        bwt_interval_vector_index_t interval_vector_max_end_index;
        if (follow_up_task_stream.read_nb(follow_up_task)) {
            pipeline_index = follow_up_task.pipeline_index;
            smems_metadata_1.sequence_offset = follow_up_task.sequence_offset;
            smems_metadata_1.start_position = follow_up_task.start_position;
            smems_metadata_1.sequence_length = follow_up_task.sequence_length;
            smems_metadata_1.min_intv = follow_up_task.min_intv;
            smems_metadata_1.filtered_candidates_end_index = follow_up_task.min_start_index;
            smems_metadata_1.start_index = follow_up_task.min_start_index;
            smems_metadata_1.end_index = follow_up_task.min_start_index;
            smems_metadata_1.task_has_failed = false;
            interval_vector_max_end_index = follow_up_task.max_end_index;

        } else if (free_pipeline_index_stack_size && new_task_stream.read_nb(new_task)) {
            pipeline_index = free_pipeline_index_stack[--free_pipeline_index_stack_size];

            smems_metadata_1.sequence_offset = new_task.sequence_offset;
            smems_metadata_1.start_position = 0;
            smems_metadata_1.sequence_length = new_task.sequence_length;
            smems_metadata_1.min_intv = 1;
            smems_metadata_1.filtered_candidates_end_index = 0;
            smems_metadata_1.start_index = 0;
            smems_metadata_1.end_index = 0;
            smems_metadata_1.task_has_failed = false;

            interval_vector_max_end_index = NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_ENTRIES - 1;

            accelerator_bwt_interval_vector_metadata_2 smems_metadata_2;
            smems_metadata_2.task_index = new_task.task_index;
            smems_metadata_2.is_first_pass_task = true;
            smems_metadata_2.unflushed_intervals_end_index = 0;
            smems_metadata_2.unscheduled_second_pass_tasks_start_index = NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_ENTRIES;
            smems_metadata_2.next_first_pass_task_start_position = 0;
            store(smem_buffer, pipeline_index, smems_metadata_2);
        } else
            continue;

        smem_forward_extend_task forward_extend_task;
        GET_SEQUENCE_SECTION(
            forward_extend_task.current_sequence_section,
            sequence_request_stream,
            sequence_response_stream,
            (smems_metadata_1.sequence_offset + smems_metadata_1.start_position));
        smems_metadata_1.current_sequence_element = GET_SEQUENCE_ELEMENT(
            forward_extend_task.current_sequence_section,
            smems_metadata_1.sequence_offset + smems_metadata_1.start_position);

        bool isAmbiguousBase = smems_metadata_1.current_sequence_element > 3;
        if (isAmbiguousBase) {
            // first base is ambiguous
            store_ack(smem_buffer, pipeline_index, smems_metadata_1);
            completed_task_stream << pipeline_index;
        } else {
            store(smem_buffer, pipeline_index, smems_metadata_1);

            accelerator_bwt_interval ik;
            ACCELERATOR_BWT_SET_INTV(L2, smems_metadata_1, ik);
            store_ack(smem_buffer, pipeline_index, smems_metadata_1.start_index, ik);

            forward_extend_task.pipeline_index = pipeline_index;
            forward_extend_task.task_min_intv = smems_metadata_1.min_intv;
            forward_extend_task.current_global_sequence_index =
                smems_metadata_1.sequence_offset + smems_metadata_1.start_position + 1;
            forward_extend_task.remaining_elements_in_current_direction =
                smems_metadata_1.sequence_length - smems_metadata_1.start_position - 1;
            forward_extend_task.forward_extension_end_index = smems_metadata_1.end_index;
            forward_extend_task.forward_extension_max_end_index = interval_vector_max_end_index;
            forward_extend_task.interval_cacheline = static_cast<accelerator_bwt_interval::cacheline_t>(ik);

            forward_extend_task_stream << forward_extend_task;
        }
    }
}

void smem_forward_step2_extend(
    ap_stream<smem_forward_extend_task>& forward_extend_task_stream,
    hls::stream<sequence_request_element_t>& sequence_request_stream,
    hls::stream<sequence_section_t>& sequence_response_stream,
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_forward_stream,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_forward_stream,
    smem_buffer_t& smem_buffer,
    ap_stream<smem_backward_extend_task>& backward_extend_task_stream,
    hls::stream<bool>& termination_signal_stream) {

    smem_forward_state_t::cacheline_t states[SMEM_KERNEL_PIPELINE_DEPTH];

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline
#pragma HLS dependence variable = states inter false
        smem_kernel_pipeline_index_t pipeline_index;
        bwt_extend_stream_element stream_element;
#pragma HLS data_pack variable = stream_element
        smem_forward_state_t state;
        smem_forward_extend_task new_task_element;

        if (ret_bwt_extend_forward_stream.read_nb(stream_element)) {  // continue existing task
            pipeline_index = stream_element.pipeline_index;
            state = static_cast<smem_forward_state_t>(states[pipeline_index]);

            if (stream_element.has_interval_size_changed) {
                // Don't overwrite old interval if interval size has changed
                state.forward_extension_end_index++;

                // the interval size is too small to be extended further
                bool intervalSizeHasReachedMinimum =
                    stream_element.interval.x[2] < (reference_index_t)state.task_min_intv;
                // Too many intervals to store inside interval vector => mark as failed
                bool hasIntervalSizeOverflow =
                    state.forward_extension_end_index + 1 == state.forward_extension_max_end_index;
                if (intervalSizeHasReachedMinimum || hasIntervalSizeOverflow) {
                    ack(smem_buffer);

                    smem_backward_extend_task backward_task;
                    backward_task.pipeline_index = pipeline_index;
                    backward_task.end_index = state.forward_extension_end_index;
                    backward_task.forward_extension_has_failed = hasIntervalSizeOverflow;

                    backward_extend_task_stream << backward_task;
                    continue;
                }
            }

            state.remaining_elements_in_current_direction--;
            state.current_global_sequence_index++;
            store(smem_buffer, pipeline_index, state.forward_extension_end_index, stream_element.interval);
        } else if (forward_extend_task_stream.read_nb(new_task_element)) {  // start new task
            pipeline_index = new_task_element.pipeline_index;
            state.task_min_intv = new_task_element.task_min_intv;
            state.current_global_sequence_index = new_task_element.current_global_sequence_index;
            state.remaining_elements_in_current_direction = new_task_element.remaining_elements_in_current_direction;
            state.forward_extension_end_index = new_task_element.forward_extension_end_index;
            state.forward_extension_max_end_index = new_task_element.forward_extension_max_end_index;
            state.current_sequence_section = new_task_element.current_sequence_section;

            stream_element.pipeline_index = pipeline_index;
            stream_element.is_backward_extension = false;
            stream_element.interval = static_cast<accelerator_bwt_interval>(new_task_element.interval_cacheline);
        } else
            continue;

        if (state.remaining_elements_in_current_direction > 0) {
            if ((state.current_global_sequence_index & SEQUENCE_READ_BUFFER_OFFSET_MASK) == 0) {
                GET_SEQUENCE_SECTION(
                    state.current_sequence_section,
                    sequence_request_stream,
                    sequence_response_stream,
                    state.current_global_sequence_index);
            }
            states[pipeline_index] = static_cast<smem_forward_state_t::cacheline_t>(state);
            sequence_element_t current_sequence_element =
                GET_SEQUENCE_ELEMENT(state.current_sequence_section, state.current_global_sequence_index);
            bool isAmbiguousBase = current_sequence_element > 3;
            if (!isAmbiguousBase) {  // an A/C/G/T base
                stream_element.current_sequence_element = current_sequence_element;
                req_bwt_extend_forward_stream << stream_element;
                continue;
            } else
                ;  // an ambiguous base
        } else
            ;  // reached end of query sequence
        {
            ack(smem_buffer);

            smem_backward_extend_task backward_task;
            backward_task.pipeline_index = pipeline_index;
            backward_task.end_index = state.forward_extension_end_index + 1;
            backward_task.forward_extension_has_failed = false;

            backward_extend_task_stream << backward_task;
        }
    }
}

void smem_backward_step1_prepare_new_extension_iteration(
    ap_stream<smem_backward_extend_task>& backward_extend_task_stream,
    ap_stream<smem_new_backward_iteration_task>& new_backward_iteration_stream,
    hls::stream<sequence_request_element_t>& sequence_request_stream,
    hls::stream<sequence_section_t>& sequence_response_stream,
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_backward_longest_candidate_stream,
    smem_buffer_t& smem_buffer,
    hls::stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    hls::stream<bool>& termination_signal_stream) {
    smem_backward_state_t states[SMEM_KERNEL_PIPELINE_DEPTH];

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline
        smem_kernel_pipeline_index_t pipeline_index;
        smem_backward_state_t state;
        accelerator_bwt_interval_vector_metadata_1 smems_metadata;

        smem_new_backward_iteration_task new_iteration_task;
        smem_backward_extend_task backward_task;
        if (new_backward_iteration_stream.read_nb(new_iteration_task)) {
            // continue next loop iteration of existing task
            pipeline_index = new_iteration_task.pipeline_index;
            state = states[pipeline_index];
            state.current_global_sequence_index--;
            state.remaining_elements_in_current_direction--;

            if (state.remaining_elements_in_current_direction > 0
                && (state.current_global_sequence_index & SEQUENCE_READ_BUFFER_OFFSET_MASK)
                    == SEQUENCE_READ_BUFFER_OFFSET_MASK) {
                GET_SEQUENCE_SECTION(
                    state.current_sequence_section,
                    sequence_request_stream,
                    sequence_response_stream,
                    state.current_global_sequence_index);
            }

            smems_metadata = load<accelerator_bwt_interval_vector_metadata_1>(smem_buffer, pipeline_index);
            smems_metadata.filtered_candidates_end_index = new_iteration_task.current_candidate_insert_index + 1;
        } else if (backward_extend_task_stream.read_nb(backward_task)) {
            pipeline_index = backward_task.pipeline_index;
            smems_metadata = load<accelerator_bwt_interval_vector_metadata_1>(smem_buffer, pipeline_index);
            smems_metadata.start_index = backward_task.end_index;
            smems_metadata.end_index = backward_task.end_index;
            smems_metadata.task_has_failed = backward_task.forward_extension_has_failed;

            // push falied task back to host
            if (smems_metadata.task_has_failed) {
                store_ack(smem_buffer, pipeline_index, smems_metadata);
                completed_task_stream << pipeline_index;
                continue;
            }

            state.remaining_elements_in_current_direction = smems_metadata.start_position;
            state.current_global_sequence_index = smems_metadata.sequence_offset + smems_metadata.start_position - 1;
            if (state.remaining_elements_in_current_direction > 0) {
                GET_SEQUENCE_SECTION(
                    state.current_sequence_section,
                    sequence_request_stream,
                    sequence_response_stream,
                    state.current_global_sequence_index);
            }
        } else
            continue;
        states[pipeline_index] = state;

        if (smems_metadata.filtered_candidates_end_index <= (smems_metadata.start_index - 1)) {
            // Has remaining candidates
            // Is always true when reading from backward_extend_task_stream, since forward_step1 always inserted an interval at this point
            if (state.remaining_elements_in_current_direction != 0) {
                smems_metadata.current_candidate_index = smems_metadata.start_index - 1;
                smems_metadata.current_candidate_insert_index = smems_metadata.start_index - 1;

                smems_metadata.current_sequence_element =
                    GET_SEQUENCE_ELEMENT(state.current_sequence_section, state.current_global_sequence_index);
                bool isAmbiguousBase = smems_metadata.current_sequence_element > 3;
                if (!isAmbiguousBase) {
                    store(smem_buffer, pipeline_index, smems_metadata);
                    accelerator_bwt_interval longest_candidate = load<accelerator_bwt_interval>(
                        smem_buffer, pipeline_index, smems_metadata.current_candidate_index);

                    bwt_extend_stream_element bwt_request(
                        pipeline_index,
                        (sequence_element_t)smems_metadata.current_sequence_element,
                        false,
                        true,
                        longest_candidate);
                    req_bwt_extend_backward_longest_candidate_stream << bwt_request;
                    continue;
                } else
                    ;  // reached an ambiguous base
            } else
                ;  // reached beginning of query sequence
            // store the longest remaining candidate as match (Push result)
            smems_metadata.start_index--;
            store_ack(smem_buffer, pipeline_index, smems_metadata);
        }
        // complete task
        completed_task_stream << pipeline_index;
    }
}

void smem_backward_step2_discard_contained_in_match(
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_backward_longest_candidate_stream,
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_backward_stream,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_backward_stream,
    smem_buffer_t& smem_buffer_0,
    smem_buffer_t& smem_buffer_1,
    ap_stream<smem_extend_remaining_candidates_task>& extend_remaining_candidates_stream,
    ap_stream<smem_new_backward_iteration_task>& new_backward_iteration_stream,
    hls::stream<bool>& termination_signal_stream) {

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline
        bwt_extend_stream_element bwt_response;
#pragma HLS data_pack variable = bwt_response
        smem_kernel_pipeline_index_t pipeline_index;
        accelerator_bwt_interval_vector_metadata_1 smems_metadata;
        accelerator_bwt_interval ok;
        bool hasReachedMinIntervalSize;
        if (ret_bwt_extend_backward_stream.read_nb(bwt_response)) {
            pipeline_index = bwt_response.pipeline_index;
            ok = bwt_response.interval;
            smems_metadata = load<accelerator_bwt_interval_vector_metadata_1>(smem_buffer_0, pipeline_index);

            hasReachedMinIntervalSize = ok.x[2] < smems_metadata.min_intv;
        } else if (ret_bwt_extend_backward_longest_candidate_stream.read_nb(bwt_response)) {
            pipeline_index = bwt_response.pipeline_index;
            ok = bwt_response.interval;
            smems_metadata = load<accelerator_bwt_interval_vector_metadata_1>(smem_buffer_0, pipeline_index);

            // Since the SMEM candidates are iterated by length in decreasing order,
            // once an interval is above min_intv, all following intervals are above as well.
            // Therefore, hasReachedMinIntervalSize is either true for the first candidate (and potentially following ones)
            // or it is false for all candidates.
            // Once this value was false, it never becomes true.
            hasReachedMinIntervalSize = ok.x[2] < smems_metadata.min_intv;
            if (hasReachedMinIntervalSize) {
                // Push result
                smems_metadata.start_index--;
                smems_metadata.current_candidate_insert_index--;
            }
        } else
            continue;

        if (!hasReachedMinIntervalSize) {
            store(smem_buffer_1, pipeline_index, smems_metadata.current_candidate_insert_index, ok);
            smems_metadata.current_candidate_insert_index--;
        }
        smems_metadata.current_candidate_index--;
        store(smem_buffer_1, pipeline_index, smems_metadata);

        bool hasRemainingCandidates =
            smems_metadata.filtered_candidates_end_index <= smems_metadata.current_candidate_index;
        if (hasRemainingCandidates) {
            if (hasReachedMinIntervalSize) {
                // Discard all candidates with hasReachedMinIntervalSize that are shorter than the match we pushed out
                // These are already contained in the match we pushed out.
                accelerator_bwt_interval ik = load<accelerator_bwt_interval>(
                    smem_buffer_1, pipeline_index, smems_metadata.current_candidate_index);
                bwt_extend_stream_element bwt_request(
                    pipeline_index, bwt_response.current_sequence_element, false, true, ik);
                req_bwt_extend_backward_stream << bwt_request;
            } else {
                ack(smem_buffer_1);
                smem_extend_remaining_candidates_task extend_remaining_candidates_task;
                extend_remaining_candidates_task.pipeline_index = pipeline_index;
                extend_remaining_candidates_task.current_candidate_index = smems_metadata.current_candidate_index;
                extend_remaining_candidates_task.current_candidate_insert_index =
                    smems_metadata.current_candidate_insert_index;
                extend_remaining_candidates_task.filtered_candidates_end_index =
                    smems_metadata.filtered_candidates_end_index;
                extend_remaining_candidates_task.current_sequence_element = bwt_response.current_sequence_element;
                // At this point, the last inserted interval is always 'ok'
                extend_remaining_candidates_task.last_inserted_candidate_interval_size = ok.x[2];

                extend_remaining_candidates_stream << extend_remaining_candidates_task;
            }
        } else {
            ack(smem_buffer_1);
            smem_new_backward_iteration_task new_iteration_task;
            new_iteration_task.pipeline_index = pipeline_index;
            new_iteration_task.current_candidate_insert_index = smems_metadata.current_candidate_insert_index;
            new_backward_iteration_stream << new_iteration_task;
        }
    }
}

void smem_backward_step3_extend_and_discard_contained_in_longer_candidate(
    ap_stream<smem_extend_remaining_candidates_task>& extend_remaining_candidates_stream,
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_backward_stream,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_backward_stream,
    // ap_stream<smem_buffer_request_stream_element>& smem_buffer_request_stream,
    // ap_stream<smem_step3_request_scheduler_task>& step3_request_scheduler_task_stream,
    smem_buffer_t& smem_buffer,
    ap_stream<smem_new_backward_iteration_task>& new_backward_iteration_stream,
    hls::stream<bool>& termination_signal_stream) {
    reference_index_t last_inserted_candidate_interval_size_buffer[SMEM_KERNEL_PIPELINE_DEPTH];
    bwt_interval_vector_index_t current_candidate_index_buffer[SMEM_KERNEL_PIPELINE_DEPTH];
    bwt_interval_vector_index_t current_candidate_insert_index_buffer[SMEM_KERNEL_PIPELINE_DEPTH];
    bwt_interval_vector_index_t filtered_candidates_end_index_buffer[SMEM_KERNEL_PIPELINE_DEPTH];

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline
#pragma HLS dependence variable = last_inserted_candidate_interval_size inter false
#pragma HLS dependence variable = current_candidate_index_buffer inter false
#pragma HLS dependence variable = current_candidate_insert_index_buffer inter false
#pragma HLS dependence variable = filtered_candidates_end_index_buffer inter false
        smem_kernel_pipeline_index_t pipeline_index;
        sequence_element_t current_sequence_element;

        bwt_extend_stream_element bwt_response;
#pragma HLS data_pack variable = bwt_response
        bwt_interval_vector_index_t current_candidate_index, current_candidate_insert_index,
            filtered_candidates_end_index;
        smem_extend_remaining_candidates_task extend_remaining_candidates_task;

        if (ret_bwt_extend_backward_stream.read_nb(bwt_response)) {
            pipeline_index = bwt_response.pipeline_index;
            accelerator_bwt_interval ok = bwt_response.interval;
            current_candidate_index = current_candidate_index_buffer[pipeline_index];
            current_candidate_insert_index = current_candidate_insert_index_buffer[pipeline_index];
            filtered_candidates_end_index = filtered_candidates_end_index_buffer[pipeline_index];
            current_sequence_element = bwt_response.current_sequence_element;

            bool isContainedInLongerCandidate = ok.x[2] == last_inserted_candidate_interval_size_buffer[pipeline_index];
            if (!isContainedInLongerCandidate) {
                // Keep & update candidate for next iteration
                store(smem_buffer, pipeline_index, current_candidate_insert_index, ok);

                // smem_buffer_request_stream_element request_element;
                // request_element.write = true;
                // request_element.write_ack = false;
                // request_element.req_wdata = static_cast<accelerator_bwt_interval::cacheline_t>(ok);
                // request_element.req_addr =
                //     (accelerator_bwt_interval_vector_address_t)NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128
                //         * pipeline_index
                //     + (accelerator_bwt_interval::interval_vector_offset + current_candidate_insert_index);
                // smem_buffer_request_stream << request_element;

                current_candidate_insert_index--;
            } else
                ;  // Discard contained Candidate
            current_candidate_index--;

            last_inserted_candidate_interval_size_buffer[pipeline_index] = ok.x[2];
            current_candidate_index_buffer[pipeline_index] = current_candidate_index;
            current_candidate_insert_index_buffer[pipeline_index] = current_candidate_insert_index;
        } else if (extend_remaining_candidates_stream.read_nb(extend_remaining_candidates_task)) {
            pipeline_index = extend_remaining_candidates_task.pipeline_index;
            current_candidate_index_buffer[pipeline_index] = current_candidate_index =
                extend_remaining_candidates_task.current_candidate_index;
            current_candidate_insert_index_buffer[pipeline_index] = current_candidate_insert_index =
                extend_remaining_candidates_task.current_candidate_insert_index;
            filtered_candidates_end_index_buffer[pipeline_index] = filtered_candidates_end_index =
                extend_remaining_candidates_task.filtered_candidates_end_index;
            current_sequence_element = extend_remaining_candidates_task.current_sequence_element;
            last_inserted_candidate_interval_size_buffer[pipeline_index] =
                extend_remaining_candidates_task.last_inserted_candidate_interval_size;
        } else
            continue;

        // Discard all candidates contained in longer candidate
        if (filtered_candidates_end_index <= current_candidate_index) {
            accelerator_bwt_interval request_interval =
                load<accelerator_bwt_interval>(smem_buffer, pipeline_index, current_candidate_index);
            bwt_extend_stream_element bwt_request(
                pipeline_index, current_sequence_element, false, true, request_interval);
            req_bwt_extend_backward_stream << bwt_request;
        } else {
            ack(smem_buffer);
            smem_new_backward_iteration_task new_iteration_task;
            new_iteration_task.pipeline_index = pipeline_index;
            new_iteration_task.current_candidate_insert_index = current_candidate_insert_index;
            new_backward_iteration_stream << new_iteration_task;
        }        
        // smem_step3_request_scheduler_task step3_request_scheduler_task;
        // step3_request_scheduler_task.pipeline_index = pipeline_index;
        // step3_request_scheduler_task.current_candidate_insert_index = current_candidate_insert_index;
        // step3_request_scheduler_task.current_sequence_element = current_sequence_element;
        // step3_request_scheduler_task.send_to_bwt_extend_stream =
        //     filtered_candidates_end_index <= current_candidate_index;
        // step3_request_scheduler_task_stream << step3_request_scheduler_task;

        // smem_buffer_request_stream_element request_element;
        // request_element.write = false;
        // request_element.write_ack = false;
        // request_element.req_wdata = 0;
        // request_element.req_addr =
        //     (accelerator_bwt_interval_vector_address_t)NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128
        //         * pipeline_index
        //     + (accelerator_bwt_interval::interval_vector_offset + current_candidate_index);
        // smem_buffer_request_stream << request_element;
    }
}

// void smem_backward_step3_extend_and_discard_contained_in_longer_candidate_request_scheduler(
//     ap_stream<bwt_extend_stream_element>& req_bwt_extend_backward_stream,
//     ap_stream<smem_buffer_response_stream_element>& smem_buffer_response_stream,
//     ap_stream<smem_step3_request_scheduler_task>& step3_request_scheduler_task_stream,
//     ap_stream<smem_new_backward_iteration_task>& new_backward_iteration_stream,
//     hls::stream<bool>& termination_signal_stream) {
//     // Processing the response of the smem buffer has been outsourced from
//     // smem_backward_step3_extend_and_discard_contained_in_longer_candidate to increase pipelinization
//     // (The component used to wait for the response before scheduling the next request...)

//     bool terminate;
//     while (!termination_signal_stream.read_nb(terminate) || !terminate) {
// #pragma HLS pipeline
//         smem_step3_request_scheduler_task step3_request_scheduler_task;
//         if (!step3_request_scheduler_task_stream.read_nb(step3_request_scheduler_task)) continue;
//         smem_buffer_response_stream_element response_element;
//         smem_buffer_response_stream >> response_element;

//         if (step3_request_scheduler_task.send_to_bwt_extend_stream) {
//             accelerator_bwt_interval request_interval = accelerator_bwt_interval(response_element.resp_rdata);
//             bwt_extend_stream_element bwt_request(
//                 step3_request_scheduler_task.pipeline_index,
//                 step3_request_scheduler_task.current_sequence_element,
//                 false,
//                 true,
//                 request_interval);
//             req_bwt_extend_backward_stream << bwt_request;
//         } else {
//             smem_new_backward_iteration_task new_iteration_task;
//             new_iteration_task.pipeline_index = step3_request_scheduler_task.pipeline_index;
//             new_iteration_task.current_candidate_insert_index =
//                 step3_request_scheduler_task.current_candidate_insert_index;
//             new_backward_iteration_stream << new_iteration_task;
//         }
//     }
// }

void sequence_request_arbiter(
    sequence_section_t* sequence_buffer,
    hls::stream<sequence_request_element_t> request_streams[3],
    hls::stream<sequence_section_t> response_streams[3],
    hls::stream<bool>& termination_signal_stream) {
#pragma HLS INTERFACE ap_bus port = sequence_buffer

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline
#pragma HLS dependence variable = sequence_buffer inter false
        for (int current_request_stream = 0; current_request_stream < 3; current_request_stream++) {
#pragma HLS unroll
            sequence_request_element_t request;
            if (request_streams[current_request_stream].read_nb(request)) {
                sequence_section_t response = sequence_buffer[request];
                response_streams[current_request_stream] << response;
            }
        }
    }
}

void bwt_smem(
    ap_uint<320> bwt_L2,
    ap_stream<task>& new_task_stream,
    ap_stream<follow_up_task>& follow_up_task_stream,
    ap_stream<bwt_extend_stream_element> req_bwt_extend_streams[4],
    ap_stream<bwt_extend_stream_element> ret_bwt_extend_streams[4],
    hls::stream<smem_kernel_pipeline_index_t>& freed_pipeline_index_stream,
    hls::stream<smem_kernel_pipeline_index_t>& completed_task_stream,
    sequence_section_t* sequence_buffer,
    smem_buffer_t smem_buffer[6],
    hls::stream<bool>& termination_signal_stream) {
    // stable-pragma prevents Vivado from creating expensive IPC structures inside the dataflow region
#pragma HLS stable variable = bwt_L2

#pragma HLS INTERFACE ap_bus port = sequence_buffer

    hls::stream<smem_kernel_pipeline_index_t> completed_task_streams[2];
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = completed_task_streams

    ap_stream<smem_forward_extend_task> forward_extend_task_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = forward_extend_task_stream
#pragma HLS resource variable = forward_extend_task_stream core = FIFO_LUTRAM
    ap_stream<smem_backward_extend_task> backward_extend_task_stream;
#pragma HLS STREAM depth = SMEM_KERNEL_PIPELINE_DEPTH variable = backward_extend_task_stream

    ap_stream<smem_new_backward_iteration_task> new_backward_iteration_stream;
#pragma HLS STREAM depth = SMEM_KERNEL_PIPELINE_DEPTH variable = new_backward_iteration_stream
    ap_stream<smem_new_backward_iteration_task> new_backward_iteration_streams[2];
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = new_backward_iteration_streams

    ap_stream<smem_extend_remaining_candidates_task> extend_remaining_candidates_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = extend_remaining_candidates_stream

    ap_stream<smem_step3_request_scheduler_task> step3_request_scheduler_task_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = step3_request_scheduler_task_stream

    hls::stream<sequence_request_element_t> sequence_request_streams[3];
#pragma HLS STREAM depth = 1 variable = sequence_request_streams
    hls::stream<sequence_section_t> sequence_response_streams[3];
#pragma HLS STREAM depth = 1 variable = sequence_response_streams

#pragma HLS dataflow

    hls::stream<bool> termination_signal_streams[8];
#pragma HLS STREAM depth = 1 variable = termination_signal_streams
    termination_signal_distributor<8>(termination_signal_stream, termination_signal_streams);

    arbiter_N_to_1<hls::stream, smem_kernel_pipeline_index_t, 2>(
        completed_task_streams, completed_task_stream, termination_signal_streams[0]);
    arbiter_N_to_1<ap_stream, smem_new_backward_iteration_task, 2>(
        new_backward_iteration_streams, new_backward_iteration_stream, termination_signal_streams[1]);

    sequence_request_arbiter(
        sequence_buffer, sequence_request_streams, sequence_response_streams, termination_signal_streams[2]);

    smem_forward_step1_prepare(
        new_task_stream,
        follow_up_task_stream,
        freed_pipeline_index_stream,
        bwt_L2,
        sequence_request_streams[0],
        sequence_response_streams[0],
        smem_buffer[0],
        forward_extend_task_stream,
        completed_task_streams[0],
        termination_signal_streams[3]);

    smem_forward_step2_extend(
        forward_extend_task_stream,
        sequence_request_streams[1],
        sequence_response_streams[1],
        req_bwt_extend_streams[0],
        ret_bwt_extend_streams[0],
        smem_buffer[1],
        backward_extend_task_stream,
        termination_signal_streams[4]);

    smem_backward_step1_prepare_new_extension_iteration(
        backward_extend_task_stream,
        new_backward_iteration_stream,
        sequence_request_streams[2],
        sequence_response_streams[2],
        req_bwt_extend_streams[1],
        smem_buffer[2],
        completed_task_streams[1],
        termination_signal_streams[5]);

    smem_backward_step2_discard_contained_in_match(
        ret_bwt_extend_streams[1],
        req_bwt_extend_streams[2],
        ret_bwt_extend_streams[2],
        smem_buffer[3],
        smem_buffer[4],
        extend_remaining_candidates_stream,
        new_backward_iteration_streams[0],
        termination_signal_streams[6]);

    smem_backward_step3_extend_and_discard_contained_in_longer_candidate(
        extend_remaining_candidates_stream,
        req_bwt_extend_streams[3],
        ret_bwt_extend_streams[3],
        // smem_buffer[5].request_stream,
        smem_buffer[5],
        new_backward_iteration_streams[1],
        // step3_request_scheduler_task_stream,
        termination_signal_streams[7]);

    // smem_backward_step3_extend_and_discard_contained_in_longer_candidate_request_scheduler(
    //     req_bwt_extend_streams[3],
    //     smem_buffer[5].response_stream,
    //     step3_request_scheduler_task_stream,
    //     new_backward_iteration_streams[1],
    //     termination_signal_streams[8]);
}
