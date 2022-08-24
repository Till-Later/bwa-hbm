#include "hw_dynamic_memory.h"

#include "hls_stream_processing.h"

void bwt_interval_vector_to_membus(
    bwt_interval_vector_t interval_vector,
    snap_membus_1024_t buffer1024[HOST_MEMORY_DATA_WORDS_PER_BWT_INTERVAL_VECTOR]) {

    SLICE(buffer1024[0], 0, sizeof(local_sequence_index_t) * 8) = interval_vector.n;
    SLICE(buffer1024[0], 1, sizeof(local_sequence_index_t) * 8) = interval_vector.x;
    SLICE(buffer1024[0], 1, sizeof(uint32_t) * 8) = interval_vector.next_overflow_index;

    // TODO-TILL: Maybe only copy valid intervals?
    for (int i = 1; i < 32; i++) {
        snap_membus_256_t buffer256;
        SLICE(buffer256, 0, 64) = interval_vector.a[i - 1].x[0];
        SLICE(buffer256, 1, 64) = interval_vector.a[i - 1].x[1];
        SLICE(buffer256, 2, 64) = interval_vector.a[i - 1].x[2];
        SLICE(buffer256, 3, 64) = interval_vector.a[i - 1].info;

        // TODO-TILL: Fix Magic Value HOST_MEMORY_BWT_INTERVALS_PER_DATA_WORD == 4 equals 2 bits right shift
        SLICE(buffer1024[i >> 2], i & (HOST_MEMORY_BWT_INTERVALS_PER_DATA_WORD - 1), sizeof(bwt_interval_t) * 8) =
            buffer256;
    }
}

void push_local_result_buffer_to_host(
    hls::stream<SMEM_Result_Buffer>& result_buffer_stream,
    snapu64_t host_result_buffer,
    bwt_interval_vector_t* local_result_buffer) {
    SMEM_Result_Buffer result_buffer = {(host_result_buffer >> ADDR_RIGHT_SHIFT_1024), *local_result_buffer};
    result_buffer_stream << result_buffer;
}

void push_bwt_interval_to_results(
    hls::stream<uint32_t>& ret_overflow_buffer_stream,
    hls::stream<SMEM_Result_Buffer>& result_buffer_stream,
    bwt_interval_vector_t* local_result_buffer,
    snapu64_t* host_result_buffer,
    const snapu64_t overflow_buffer_start_address,
    bwt_interval_t bwt_interval) {
    uint32_t next_free_element_index;
    if (local_result_buffer->n == 31) {
        ret_overflow_buffer_stream >> next_free_element_index;
        snapu64_t overflow_buffer_address =
            overflow_buffer_start_address + (next_free_element_index * sizeof(bwt_interval_vector_t));

        // Before pushing the full result buffer to host, set the address of the (next) overflow buffer
        local_result_buffer->next_overflow_index = next_free_element_index;

        // Push full result buffer to host
        push_local_result_buffer_to_host(result_buffer_stream, *host_result_buffer, local_result_buffer);

        // Set address of (next) overflow buffer as new result buffer on host
        *host_result_buffer = overflow_buffer_address;

        local_result_buffer->n = 0;
        local_result_buffer->next_overflow_index = 0xffffffff;
    }
    local_result_buffer->a[local_result_buffer->n++] = bwt_interval;
}

void local_smem_manager(
    hls::stream<bool>& req_overflow_buffer_stream,
    hls::stream<uint32_t>& ret_overflow_buffer_stream,
    hls::stream<SMEM_Result_Buffer>& result_buffer_stream,
    hls::stream<SMEM_Result>& smem_result_stream,
    const snapu64_t overflow_buffer_start_address,
    hls::stream<task_index_t>& smem_task_completion_stream) {

    bwt_interval_vector_t local_result_buffer = {0};
    snapu64_t host_result_buffer = NULL;

    SMEM_Result smem_result;
    while (true) {
        smem_result_stream >> smem_result;
        switch (smem_result.instruction) {
        case TERMINATE:
            req_overflow_buffer_stream << STREAM_TERMINATION<bool>::SIGNAL;
            smem_task_completion_stream << STREAM_TERMINATION<task_index_t>::SIGNAL;
            return;
        case RESET:
            host_result_buffer = smem_result.host_result_buffer;
            local_result_buffer.n = 0;
            local_result_buffer.x = smem_result.smem.info;
            break;
        case PUSH_RESULT:
            if (local_result_buffer.n == 0) {
                // The value of x is the end position of longest smem candidate after forward extension.
                // This smem candidate will always be pushed to results as first during backward extension.
                local_result_buffer.x = smem_result.smem.info;
            }

            push_bwt_interval_to_results(
                ret_overflow_buffer_stream,
                result_buffer_stream,
                &local_result_buffer,
                &host_result_buffer,
                overflow_buffer_start_address,
                smem_result.smem);
            break;
        case FINALIZE:
            push_local_result_buffer_to_host(result_buffer_stream, host_result_buffer, &local_result_buffer);
            smem_task_completion_stream << ((task_index_t)(smem_result.host_result_buffer) + 1);
            break;
        default:
            break;
        }
    }
}

void overflow_smem_manager(
    hls::stream<snapu64_t>& req_free_list_section_stream,
    hls::stream<snap_membus_1024_t>& ret_free_list_section_stream,
    snapu64_t free_list_start_address,
    hls::stream<bool>& req_overflow_buffer_stream,
    hls::stream<uint32_t>& ret_overflow_buffer_stream) {
    bool request;
    uint32_t next_free_element_index = 0;
    while (true) {
        if (!req_overflow_buffer_stream.empty()) {
            req_overflow_buffer_stream >> request;
            if (request == STREAM_TERMINATION<bool>::SIGNAL) {
                return;
            }
        }

        if (ret_overflow_buffer_stream.full())
            continue;  // Prevent stalling on output stream, in order to correctly register TERMINATION_SIGNAL

        // Aquire & store index of next overflow buffer (poll until available)
        do {
            snap_membus_1024_t free_list_section;
            bidirectional_stream_access<snapu64_t, snap_membus_1024_t>(
                req_free_list_section_stream,
                ret_free_list_section_stream,
                (free_list_start_address + (next_free_element_index * sizeof(uint32_t))
                 >> ADDR_RIGHT_SHIFT_1024),
                free_list_section);
            next_free_element_index = SLICE(free_list_section, next_free_element_index & 0x7F, sizeof(uint32_t) * 8);
        } while (next_free_element_index == 0xffffffff);

        ret_overflow_buffer_stream << next_free_element_index;
    }
}


void reset_smem_results(
    hls::stream<SMEM_Result>& smem_result_stream,
    snapu64_t host_result_buffer,
    local_sequence_index_t initial_x) {
    SMEM_Result smem_reset = {RESET, host_result_buffer, {{0, 0, 0}, initial_x}};
    smem_result_stream << smem_reset;
}

void push_smem_result(hls::stream<SMEM_Result>& smem_result_stream, bwt_interval_t bwt_interval) {
    SMEM_Result smem_result = {PUSH_RESULT, NULL, bwt_interval};
    smem_result_stream << smem_result;
}

void finalize_smem_results(hls::stream<SMEM_Result>& smem_result_stream, task_index_t task_index) {
    // TODO-TILL: double use of variable - not really pretty
    SMEM_Result smem_finalize = {FINALIZE, (snapu64_t)task_index, {}};
    smem_result_stream << smem_finalize;
}