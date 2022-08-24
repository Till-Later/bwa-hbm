#include "hls_bwt.h"

#include <hls_stream.h>
#include <iostream>
#include <osnap_types.h>

#include "../../../include/hls_ap_utils.h"

bwt_extend_state::bwt_extend_state(cacheline_t ap_element) {
    int offset = 0;
    INIT_FROM_AP_ELEMENT_BITS(_l);
    INIT_FROM_AP_ELEMENT_BITS(new_reverse_extended_end_position);
    INIT_FROM_AP_ELEMENT_BITS(old_interval_size);
    INIT_FROM_AP_ELEMENT_BITS(query_begin_position);
    INIT_FROM_AP_ELEMENT_BITS(query_end_position);
    INIT_FROM_AP_ELEMENT_BYTES(phase);
    INIT_FROM_AP_ELEMENT_BITS(is_backward_extension);
    INIT_FROM_AP_ELEMENT_BITS(current_sequence_element);
};

bwt_extend_state_t::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(_l);
    STORE_INTO_AP_ELEMENT_BITS(new_reverse_extended_end_position);
    STORE_INTO_AP_ELEMENT_BITS(old_interval_size);
    STORE_INTO_AP_ELEMENT_BITS(query_begin_position);
    STORE_INTO_AP_ELEMENT_BITS(query_end_position);
    STORE_INTO_AP_ELEMENT_BYTES(phase);
    STORE_INTO_AP_ELEMENT_BITS(is_backward_extension);
    STORE_INTO_AP_ELEMENT_BITS(current_sequence_element);

    return ap_element;
};

hbm_bwt_position::hbm_bwt_position(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(l_section_counter);
    INIT_FROM_AP_ELEMENT_BITS(k_section_counter);
    INIT_FROM_AP_ELEMENT_BITS(address);
    INIT_FROM_AP_ELEMENT_BITS_WIDTH(pipeline_index, SMEM_KERNEL_PIPELINE_LOG2_DEPTH);
};

hbm_bwt_position::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(l_section_counter);
    STORE_INTO_AP_ELEMENT_BITS(k_section_counter);
    STORE_INTO_AP_ELEMENT_BITS(address);
    STORE_INTO_AP_ELEMENT_BITS_WIDTH(pipeline_index, SMEM_KERNEL_PIPELINE_LOG2_DEPTH);
    return ap_element;
};

hbm_bwt_entry::hbm_bwt_entry(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(l_section_counter_row);
    INIT_FROM_AP_ELEMENT_BITS(k_section_counter_row);
    INIT_FROM_AP_ELEMENT_BITS(occ_row);
    INIT_FROM_AP_ELEMENT_BITS_WIDTH(pipeline_index, SMEM_KERNEL_PIPELINE_LOG2_DEPTH);
};

hbm_bwt_entry::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(l_section_counter_row);
    STORE_INTO_AP_ELEMENT_BITS(k_section_counter_row);
    STORE_INTO_AP_ELEMENT_BITS(occ_row);
    STORE_INTO_AP_ELEMENT_BITS_WIDTH(pipeline_index, SMEM_KERNEL_PIPELINE_LOG2_DEPTH);
    return ap_element;
};

void send_bwt_request(
    ap_stream<hbm_bwt_position_t>& req_bwt_position_stream,
    smem_kernel_pipeline_index_t pipeline_index,
    reference_index_t entry_position,
    reference_section_counter_t k_section_counter,
    reference_section_counter_t l_section_counter) {
    hbm_bwt_position_t request;
    request.l_section_counter = l_section_counter;
    request.k_section_counter = k_section_counter;
    request.address = BWT_ADDRESS_TO_HARDWARE_ADDRESS(
                          entry_position >> (HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS - HBM_ADDR_BWT_ENTRY_SIZE_BITS))
        >> HBM_ADDR_BWT_ENTRY_SIZE_BITS;
    request.pipeline_index = pipeline_index;

    req_bwt_position_stream << request;
}

void send_bwt_extend_response(
    occ_row_t L2,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_stream,
    smem_kernel_pipeline_index_t pipeline_index,
    bwt_extend_state_t state,
    occ_row_t tk,
    occ_row_t tl) {
#pragma HLS pipeline
    occ_row_t ok[3];
#pragma HLS array_partition variable = ok complete
    bool is_back = state.is_backward_extension;
    sequence_element_t base =
        is_back ? state.current_sequence_element : sequence_element_t(3 - state.current_sequence_element);

    ok[0] = L2 + tk + OCC_ROW_ONE_EACH;
    ok[2] = tl - tk;

    SLICE(ok[1], 3, occ_cell_t::width) = state.new_reverse_extended_end_position;
    SLICE(ok[1], 2, occ_cell_t::width) = SLICE(ok[1], 3, occ_cell_t::width) + SLICE(ok[2], 3, occ_cell_t::width);
    SLICE(ok[1], 1, occ_cell_t::width) = SLICE(ok[1], 2, occ_cell_t::width) + SLICE(ok[2], 2, occ_cell_t::width);
    SLICE(ok[1], 0, occ_cell_t::width) = SLICE(ok[1], 1, occ_cell_t::width) + SLICE(ok[2], 1, occ_cell_t::width);

    accelerator_bwt_interval response_interval;
    response_interval.x[0] = (reference_index_t)SLICE(ok[!is_back], base, occ_cell_t::width);
    response_interval.x[1] = (reference_index_t)SLICE(ok[is_back], base, occ_cell_t::width);
    response_interval.x[2] = (reference_index_t)SLICE(ok[2], base, occ_cell_t::width);
    response_interval.query_begin_position = state.query_begin_position - (is_back ? 1 : 0);
    response_interval.query_end_position = state.query_end_position + (is_back ? 0 : 1);
    bwt_extend_stream_element bwt_response(
        pipeline_index, base, state.old_interval_size != response_interval.x[2], is_back, response_interval);
    ret_bwt_extend_stream << bwt_response;
}

void bwt_extend_request_processor(
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_stream,
    ap_stream<hbm_bwt_position_t>& req_bwt_position_stream,
    bwtint_t bwt_primary,
    hls::stream<bool>& termination_signal_stream,
    bwt_extend_state_t::cacheline_t states[SMEM_KERNEL_PIPELINE_DEPTH]) {
#pragma HLS resource variable = states core = RAM_1P latency = 1
    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline
        bwt_extend_stream_element bwt_request;
#pragma HLS data_pack variable = bwt_request
        if (!req_bwt_extend_stream.read_nb(bwt_request)) continue;

        // Issue new request
        reference_index_t k, l, _k, _l;
        k = bwt_request.interval.x[!bwt_request.is_backward_extension] - 1;
        l = bwt_request.interval.x[!bwt_request.is_backward_extension] - 1 + bwt_request.interval.x[2];
        _k = k - (k >= bwt_primary);  // because $ is not in bwt
        _l = l - (l >= bwt_primary);

        bwt_extend_phase_t phase;
        if (k == (reference_index_t)(-1) || l == (reference_index_t)(-1)) {
            if (k != (reference_index_t)(-1)) {
                phase = ONLY_K;
            } else if (l != (reference_index_t)(-1)) {
                phase = ONLY_L;
            }
        } else if ((_k >> HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS) == (_l >> HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS)) {
            phase = COMBINED_K_L;
        } else {
            phase = K_L;
        }

        states[bwt_request.pipeline_index] = (bwt_extend_state_t::cacheline_t)(bwt_extend_state_t(
            _l,
            bwt_request.interval.x[bwt_request.is_backward_extension] + (k < bwt_primary && l >= bwt_primary),
            bwt_request.interval.x[2],
            bwt_request.interval.query_begin_position,
            bwt_request.interval.query_end_position,
            phase,
            bwt_request.is_backward_extension,
            bwt_request.current_sequence_element));

        if (phase == ONLY_K || phase == K_L) {
            send_bwt_request(
                req_bwt_position_stream, bwt_request.pipeline_index, _k, _k & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK, 0);
        } else if (phase == ONLY_L) {
            send_bwt_request(
                req_bwt_position_stream, bwt_request.pipeline_index, _l, 0, _l & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK);
        } else {  // (phase == COMBINED_K_L)
            send_bwt_request(
                req_bwt_position_stream,
                bwt_request.pipeline_index,
                _k,
                _k & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK,
                _l & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK);
        }
    }
}

occ_row_t add_section_counter_row_to_occ_row(occ_row_t occ_row, reference_section_counter_row_t section_counter_row) {
    for (uint8_t i = 0; i < NUM_REFERENCE_SYMBOLS; i++) {
#pragma HLS unroll
        SLICE(occ_row, i, occ_cell_t::width) = (reference_index_t)SLICE(occ_row, i, occ_cell_t::width)
            + SLICE(section_counter_row, i, reference_section_counter_t::width);
    }
    return occ_row;
}

void bwt_extend_response_processor(
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_stream,
    ap_stream<hbm_bwt_position_t>& req_bwt_position_stream,
    ap_stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    ap_uint<320> bwt_L2,
    hls::stream<bool>& termination_signal_stream,
    bwt_extend_state_t::cacheline_t states[SMEM_KERNEL_PIPELINE_DEPTH]) {
#pragma HLS resource variable = states core = RAM_1P latency = 1
    occ_row_t countk_buffer[SMEM_KERNEL_PIPELINE_DEPTH];
    bool final_stage_tasks[SMEM_KERNEL_PIPELINE_DEPTH] = {false};

    occ_row_t L2;
    for (int i = 0; i < NUM_REFERENCE_SYMBOLS; i++) {
        SLICE(L2, i, occ_cell_t::width) = (occ_cell_t)SLICE(bwt_L2, i, 64);
    }

    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline
#pragma HLS dependence variable = final_stage_tasks inter false
#pragma HLS dependence variable = countk_buffer inter false
        hbm_bwt_entry_t hbm_bwt_entry;
        if (!ret_bwt_entry_stream.read_nb(hbm_bwt_entry)) continue;
        occ_row_t countl =
            add_section_counter_row_to_occ_row(hbm_bwt_entry.occ_row, hbm_bwt_entry.l_section_counter_row);
        occ_row_t countk =
            add_section_counter_row_to_occ_row(hbm_bwt_entry.occ_row, hbm_bwt_entry.k_section_counter_row);

        smem_kernel_pipeline_index_t pipeline_index = hbm_bwt_entry.pipeline_index;
        bwt_extend_state_t state = bwt_extend_state_t(states[pipeline_index]);

        bool is_final_stage = final_stage_tasks[pipeline_index];
        final_stage_tasks[pipeline_index] = state.phase == K_L && !is_final_stage;
        if (state.phase == K_L && !is_final_stage) {
            countk_buffer[pipeline_index] = countk;
            send_bwt_request(
                req_bwt_position_stream, pipeline_index, state._l, 0, state._l & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK);
        } else {
            if (state.phase == K_L) countk = countk_buffer[pipeline_index];
            if (state.phase == ONLY_K) countl = 0;
            if (state.phase == ONLY_L) countk = 0;

            send_bwt_extend_response(L2, ret_bwt_extend_stream, pipeline_index, state, countk, countl);
        }
    }
}

void bwt_extend(
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_stream,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_stream,
    ap_stream<hbm_bwt_position_t>& req_bwt_position_stream,
    ap_stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    bwtint_t bwt_primary,
    ap_uint<320> bwt_L2,
    hls::stream<bool>& termination_signal_stream,
    bwt_extend_state_t::cacheline_t states_1[SMEM_KERNEL_PIPELINE_DEPTH],
    bwt_extend_state_t::cacheline_t states_2[SMEM_KERNEL_PIPELINE_DEPTH]) {
    hls::stream<bool> termination_signal_streams[3];
#pragma HLS STREAM depth = 1 variable = termination_signal_streams
#pragma HLS stable variable = bwt_L2

    ap_stream<hbm_bwt_position_t> req_bwt_position_streams[2];
#pragma HLS STREAM depth = 4 variable = req_bwt_position_streams

#pragma HLS dataflow
    termination_signal_distributor<3>(termination_signal_stream, termination_signal_streams);
    burst_arbiter_N_to_1<ap_stream, hbm_bwt_position_t, 2>(
        req_bwt_position_streams, req_bwt_position_stream, termination_signal_streams[2]);
    bwt_extend_request_processor(
        req_bwt_extend_stream, req_bwt_position_streams[0], bwt_primary, termination_signal_streams[0], states_1);
    bwt_extend_response_processor(
        ret_bwt_extend_stream,
        req_bwt_position_streams[1],
        ret_bwt_entry_stream,
        bwt_L2,
        termination_signal_streams[1],
        states_2);
}
