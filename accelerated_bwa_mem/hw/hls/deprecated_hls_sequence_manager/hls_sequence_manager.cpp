#include "hls_sequence_manager.h"

#include "hls_definitions.h"
#include "hls_stream_processing.h"

void process_sequence_requests(
    sequence_buffer_t sequences[MAX_NB_OF_WORDS_READ_1024 * 16],
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream) {
    global_sequence_index_t global_sequence_index;
    sequence_buffer_t sequence_section;
    while (true) {
        req_sequence_stream >> global_sequence_index;
        if (global_sequence_index == STREAM_TERMINATION<global_sequence_index_t>::SIGNAL) {
            // ret_sequence_stream.write(STREAM_TERMINATION<sequence_buffer_t>::SIGNAL);
            return;
        }
        sequence_section = sequences[global_sequence_index];
        ret_sequence_stream << sequence_section;
    }
}

void sequence_manager(
    sequence_buffer_t sequences[MAX_NB_OF_WORDS_READ_1024 * 16],
    hls::stream<global_sequence_index_t> req_sequence_streams[NUM_SMEM_KERNELS],
    hls::stream<sequence_buffer_t> ret_sequence_streams[NUM_SMEM_KERNELS]) {

#pragma HLS INTERFACE ap_ctrl_hs port = return

//#pragma HLS RESOURCE variable = sequences core = XPM_MEMORY uram
    // The RTL component that provides the URAM currently has a latency of 2. Vivado HLS needs to
    // know that in order to generate memory accesses accordingly.
#pragma HLS RESOURCE variable = sequences core = RAM_1P_URAM latency = 2
#pragma HLS INTERFACE ap_memory port = sequences
    hls::stream<global_sequence_index_t> req_sequence_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = req_sequence_stream
    hls::stream<sequence_buffer_t> ret_sequence_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = ret_sequence_stream

#pragma HLS dataflow
    bidirectional_arbiter_N_to_1<hls::stream, global_sequence_index_t, hls::stream, sequence_buffer_t, NUM_SMEM_KERNELS>(
        req_sequence_streams, ret_sequence_streams, req_sequence_stream, ret_sequence_stream);

    process_sequence_requests(sequences, req_sequence_stream, ret_sequence_stream);
}