#include "hls_bwt_definitions.h"

#include "hls_ap_utils.h"

void ack(smem_buffer_t& smem_buffer) {
#pragma HLS inline
    load<accelerator_bwt_interval_vector_metadata_1>(smem_buffer, 0);
}

smem_buffer_request_stream_element::smem_buffer_request_stream_element(
    smem_buffer_request_stream_element::cacheline_t ap_element) {
    int offset = 0;
    INIT_FROM_AP_ELEMENT_BITS(write);
    INIT_FROM_AP_ELEMENT_BITS(write_ack);
    INIT_FROM_AP_ELEMENT_BITS(req_wdata);
    INIT_FROM_AP_ELEMENT_BITS(req_addr);
}

smem_buffer_request_stream_element::operator cacheline_t() const {
    int offset = 0;
    cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BITS(write);
    STORE_INTO_AP_ELEMENT_BITS(write_ack);
    STORE_INTO_AP_ELEMENT_BITS(req_wdata);
    STORE_INTO_AP_ELEMENT_BITS(req_addr);

    return ap_element;
}

smem_buffer_response_stream_element::smem_buffer_response_stream_element(
    smem_buffer_response_stream_element::cacheline_t ap_element) {
    int offset = 0;
    INIT_FROM_AP_ELEMENT_BITS(resp_rdata);
}

smem_buffer_response_stream_element::operator cacheline_t() const {
    int offset = 0;
    cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BITS(resp_rdata);

    return ap_element;
}

accelerator_bwt_interval::accelerator_bwt_interval(accelerator_bwt_interval::cacheline_t ap_element) {
    int offset = 0;
    INIT_FROM_AP_ELEMENT_BITS(x[0]);
    INIT_FROM_AP_ELEMENT_BITS(x[1]);
    INIT_FROM_AP_ELEMENT_BITS(x[2]);
    INIT_FROM_AP_ELEMENT_BITS(query_begin_position);
    INIT_FROM_AP_ELEMENT_BITS(query_end_position);
}

accelerator_bwt_interval::operator cacheline_t() const {
    int offset = 0;
    cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BITS(x[0]);
    STORE_INTO_AP_ELEMENT_BITS(x[1]);
    STORE_INTO_AP_ELEMENT_BITS(x[2]);
    STORE_INTO_AP_ELEMENT_BITS(query_begin_position);
    STORE_INTO_AP_ELEMENT_BITS(query_end_position);

    return ap_element;
}

accelerator_bwt_interval_vector_metadata_1::accelerator_bwt_interval_vector_metadata_1(
    accelerator_bwt_interval_vector_metadata_1::cacheline_t ap_element) {
    int offset = 0;
    INIT_FROM_AP_ELEMENT_BITS(sequence_offset);
    INIT_FROM_AP_ELEMENT_BITS(start_position);
    INIT_FROM_AP_ELEMENT_BITS(sequence_length);
    INIT_FROM_AP_ELEMENT_BITS(min_intv);
    INIT_FROM_AP_ELEMENT_BITS(filtered_candidates_end_index);
    INIT_FROM_AP_ELEMENT_BITS(current_candidate_index);
    INIT_FROM_AP_ELEMENT_BITS(current_candidate_insert_index);
    INIT_FROM_AP_ELEMENT_BITS(start_index);
    INIT_FROM_AP_ELEMENT_BITS(end_index);
    INIT_FROM_AP_ELEMENT_BITS(current_sequence_element);
    INIT_FROM_AP_ELEMENT_BITS(task_has_failed);
}

accelerator_bwt_interval_vector_metadata_1::operator cacheline_t() const {
    int offset = 0;
    cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BITS(sequence_offset);
    STORE_INTO_AP_ELEMENT_BITS(start_position);
    STORE_INTO_AP_ELEMENT_BITS(sequence_length);
    STORE_INTO_AP_ELEMENT_BITS(min_intv);
    STORE_INTO_AP_ELEMENT_BITS(filtered_candidates_end_index);
    STORE_INTO_AP_ELEMENT_BITS(current_candidate_index);
    STORE_INTO_AP_ELEMENT_BITS(current_candidate_insert_index);
    STORE_INTO_AP_ELEMENT_BITS(start_index);
    STORE_INTO_AP_ELEMENT_BITS(end_index);
    STORE_INTO_AP_ELEMENT_BITS(current_sequence_element);
    STORE_INTO_AP_ELEMENT_BITS(task_has_failed);

    return ap_element;
}

accelerator_bwt_interval_vector_metadata_2::accelerator_bwt_interval_vector_metadata_2(
    accelerator_bwt_interval_vector_metadata_2::cacheline_t ap_element) {
    int offset = 0;
    INIT_FROM_AP_ELEMENT_BYTES(task_index);
    INIT_FROM_AP_ELEMENT_BITS(is_first_pass_task);
    INIT_FROM_AP_ELEMENT_BITS(unflushed_intervals_end_index);
    INIT_FROM_AP_ELEMENT_BITS(unscheduled_second_pass_tasks_start_index);
    INIT_FROM_AP_ELEMENT_BITS(next_first_pass_task_start_position);
}

accelerator_bwt_interval_vector_metadata_2::operator cacheline_t() const {
    int offset = 0;
    cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BYTES(task_index);
    STORE_INTO_AP_ELEMENT_BITS(is_first_pass_task);
    STORE_INTO_AP_ELEMENT_BITS(unflushed_intervals_end_index);
    STORE_INTO_AP_ELEMENT_BITS(unscheduled_second_pass_tasks_start_index);
    STORE_INTO_AP_ELEMENT_BITS(next_first_pass_task_start_position);

    return ap_element;
}

host_bwt_interval_vector_cacheline_t to_host_bwt_interval_vector_cacheline(accelerator_bwt_interval interval) {
    int offset = 0;
    host_bwt_interval_vector_cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BYTES((bwtint_t)interval.x[0]);
    STORE_INTO_AP_ELEMENT_BYTES((bwtint_t)interval.x[1]);
    STORE_INTO_AP_ELEMENT_BYTES((bwtint_t)interval.x[2]);
    STORE_INTO_AP_ELEMENT_BYTES((uint32_t)interval.query_begin_position);
    STORE_INTO_AP_ELEMENT_BYTES((uint32_t)interval.query_end_position);

    return ap_element;
}

smem_forward_state::smem_forward_state(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(task_min_intv);
    INIT_FROM_AP_ELEMENT_BITS(current_global_sequence_index);
    INIT_FROM_AP_ELEMENT_BITS(remaining_elements_in_current_direction);
    INIT_FROM_AP_ELEMENT_BITS(forward_extension_end_index);
    INIT_FROM_AP_ELEMENT_BITS(forward_extension_max_end_index);
    INIT_FROM_AP_ELEMENT_BITS(current_sequence_section);
}

smem_forward_state::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(task_min_intv);
    STORE_INTO_AP_ELEMENT_BITS(current_global_sequence_index);
    STORE_INTO_AP_ELEMENT_BITS(remaining_elements_in_current_direction);
    STORE_INTO_AP_ELEMENT_BITS(forward_extension_end_index);
    STORE_INTO_AP_ELEMENT_BITS(forward_extension_max_end_index);
    STORE_INTO_AP_ELEMENT_BITS(current_sequence_section);

    return ap_element;
}

smem_forward_extend_task::smem_forward_extend_task(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(pipeline_index);
    INIT_FROM_AP_ELEMENT_BITS(task_min_intv);
    INIT_FROM_AP_ELEMENT_BITS(current_global_sequence_index);
    INIT_FROM_AP_ELEMENT_BITS(remaining_elements_in_current_direction);
    INIT_FROM_AP_ELEMENT_BITS(forward_extension_end_index);
    INIT_FROM_AP_ELEMENT_BITS(forward_extension_max_end_index);
    INIT_FROM_AP_ELEMENT_BITS(current_sequence_section);
    INIT_FROM_AP_ELEMENT_BITS(interval_cacheline);
}

smem_forward_extend_task::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(pipeline_index);
    STORE_INTO_AP_ELEMENT_BITS(task_min_intv);
    STORE_INTO_AP_ELEMENT_BITS(current_global_sequence_index);
    STORE_INTO_AP_ELEMENT_BITS(remaining_elements_in_current_direction);
    STORE_INTO_AP_ELEMENT_BITS(forward_extension_end_index);
    STORE_INTO_AP_ELEMENT_BITS(forward_extension_max_end_index);
    STORE_INTO_AP_ELEMENT_BITS(current_sequence_section);
    STORE_INTO_AP_ELEMENT_BITS(interval_cacheline);

    return ap_element;
}

smem_backward_extend_task::smem_backward_extend_task(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(pipeline_index);
    INIT_FROM_AP_ELEMENT_BITS(end_index);
    INIT_FROM_AP_ELEMENT_BITS(forward_extension_has_failed);
}

smem_backward_extend_task::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(pipeline_index);
    STORE_INTO_AP_ELEMENT_BITS(end_index);
    STORE_INTO_AP_ELEMENT_BITS(forward_extension_has_failed);

    return ap_element;
}

smem_extend_remaining_candidates_task::smem_extend_remaining_candidates_task(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(pipeline_index);
    INIT_FROM_AP_ELEMENT_BITS(current_candidate_index);
    INIT_FROM_AP_ELEMENT_BITS(current_candidate_insert_index);
    INIT_FROM_AP_ELEMENT_BITS(filtered_candidates_end_index);
    INIT_FROM_AP_ELEMENT_BITS(current_sequence_element);
    INIT_FROM_AP_ELEMENT_BITS(last_inserted_candidate_interval_size);
}

smem_extend_remaining_candidates_task::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(pipeline_index);
    STORE_INTO_AP_ELEMENT_BITS(current_candidate_index);
    STORE_INTO_AP_ELEMENT_BITS(current_candidate_insert_index);
    STORE_INTO_AP_ELEMENT_BITS(filtered_candidates_end_index);
    STORE_INTO_AP_ELEMENT_BITS(current_sequence_element);
    STORE_INTO_AP_ELEMENT_BITS(last_inserted_candidate_interval_size);

    return ap_element;
}

smem_step3_request_scheduler_task::smem_step3_request_scheduler_task(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(pipeline_index);
    INIT_FROM_AP_ELEMENT_BITS(current_candidate_insert_index);
    INIT_FROM_AP_ELEMENT_BITS(current_sequence_element);
    INIT_FROM_AP_ELEMENT_BITS(send_to_bwt_extend_stream);
}

smem_step3_request_scheduler_task::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(pipeline_index);
    STORE_INTO_AP_ELEMENT_BITS(current_candidate_insert_index);
    STORE_INTO_AP_ELEMENT_BITS(current_sequence_element);
    STORE_INTO_AP_ELEMENT_BITS(send_to_bwt_extend_stream);

    return ap_element;
}

smem_new_backward_iteration_task::smem_new_backward_iteration_task(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(pipeline_index);
    INIT_FROM_AP_ELEMENT_BITS(current_candidate_insert_index);
}

smem_new_backward_iteration_task::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(pipeline_index);
    STORE_INTO_AP_ELEMENT_BITS(current_candidate_insert_index);

    return ap_element;
}

bwt_extend_stream_element::bwt_extend_stream_element(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(current_sequence_element);
    INIT_FROM_AP_ELEMENT_BITS(has_interval_size_changed);
    INIT_FROM_AP_ELEMENT_BITS(is_backward_extension);
    INIT_FROM_AP_ELEMENT_BITS(interval.x[0]);
    INIT_FROM_AP_ELEMENT_BITS(interval.x[1]);
    INIT_FROM_AP_ELEMENT_BITS(interval.x[2]);
    INIT_FROM_AP_ELEMENT_BITS(interval.query_begin_position);
    INIT_FROM_AP_ELEMENT_BITS(interval.query_end_position);
    INIT_FROM_AP_ELEMENT_BITS(pipeline_index);
};

bwt_extend_stream_element::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(current_sequence_element);
    STORE_INTO_AP_ELEMENT_BITS(has_interval_size_changed);
    STORE_INTO_AP_ELEMENT_BITS(is_backward_extension);
    STORE_INTO_AP_ELEMENT_BITS(interval.x[0]);
    STORE_INTO_AP_ELEMENT_BITS(interval.x[1]);
    STORE_INTO_AP_ELEMENT_BITS(interval.x[2]);
    STORE_INTO_AP_ELEMENT_BITS(interval.query_begin_position);
    STORE_INTO_AP_ELEMENT_BITS(interval.query_end_position);
    STORE_INTO_AP_ELEMENT_BITS(pipeline_index);

    return ap_element;
};