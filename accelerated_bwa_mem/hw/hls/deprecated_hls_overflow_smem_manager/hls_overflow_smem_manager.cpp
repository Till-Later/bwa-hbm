#include "hls_overflow_smem_manager.h"

#include "hls_ap_utils.h"
#include "hls_stream_processing.h"

void overflow_smem_manager(
    snap_membus_1024_t* gmem,
    snapu64_t smem_results_overflow_addr,
    ap_stream<bool>& req_overflow_buffer_stream,
    ap_stream<uint32_t>& ret_overflow_buffer_stream) {

#pragma HLS INTERFACE ap_ctrl_hs port = return

#pragma HLS INTERFACE m_axi port = gmem bundle = host_mem depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64

#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = req_overflow_buffer_stream
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = ret_overflow_buffer_stream

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
            __builtin_memcpy(
                &free_list_section,
                gmem
                    + (smem_results_overflow_addr + (next_free_element_index * sizeof(uint32_t))
                       >> ADDR_RIGHT_SHIFT_1024),
                sizeof(snap_membus_1024_t));
            next_free_element_index = SLICE(free_list_section, next_free_element_index & 0x7F, sizeof(uint32_t) * 8);
        } while (next_free_element_index == 0xffffffff);

        ret_overflow_buffer_stream << next_free_element_index;
    }
}
