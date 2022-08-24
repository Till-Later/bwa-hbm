#include "hls_init_sequences.h"

#include "hls_ap_utils.h"

sequence_element_t sequence_byte_to_sequence_element(ap_uint<8> sequence_byte) {
    switch (sequence_byte) {
    case 'a':
    case 'A':
        return 0;
    case 'c':
    case 'C':
        return 1;
    case 'g':
    case 'G':
        return 2;
    case 't':
    case 'T':
        return 3;
    case '-':
        return 5;
    default:
        return 4;
    }
}

void membus_to_sequence_buffer(
    snap_membus_1024_t* buffer_1024,
    sequence_write_section_t* sequence_buffer,
    uint32_t num_bytes) {
    uint32_t num_words_1024 = (num_bytes >> ADDR_RIGHT_SHIFT_1024) + ((num_bytes % BPERDW_1024 != 0) ? 1 : 0);

    sequence_write_section_t converted_sequence;

    for (int k = 0; k < num_words_1024; k++) {
        for (int j = 0; j < BPERDW_1024; j++) {
#pragma HLS unroll
            SLICE(converted_sequence, j, SEQUENCE_ELEMENT_SIZE_BITS) =
                sequence_byte_to_sequence_element(SLICE(buffer_1024[k], j, 8));
        }
        sequence_buffer[k] = converted_sequence;
    }
}

void init_sequences(
//    action_reg* act_reg,
    const snapu64_t sequences_host_address,
    const snapu32_t sequences_size_bytes,
    snap_membus_1024_t* din_gmem,
    sequence_write_section_t sequences[MAX_NB_OF_WORDS_READ_1024 * 4]) {
//#pragma HLS DATA_PACK variable = act_reg
//#pragma HLS INTERFACE s_axilite port = act_reg bundle = ctrl_reg offset = 0x100
#pragma HLS INTERFACE ap_ctrl_hs port = return

#pragma HLS INTERFACE m_axi port = din_gmem bundle = host_mem offset = off depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64

    snap_membus_1024_t buffer1024[MAX_NB_OF_WORDS_READ_1024];

//    const snapu64_t sequences_host_address = act_reg->Data.sequences_addr;
//    const snapu32_t sequences_size_bytes = act_reg->Data.sequences_size;

    const snapu32_t sequences_num_transfers =
        (sequences_size_bytes / MAX_NB_OF_BYTES_READ) + ((sequences_size_bytes % MAX_NB_OF_BYTES_READ != 0) ? 1 : 0);

    snapu32_t sequences_address_transfer_offset = 0;
    snapu32_t sequences_remaining_transfer_size_bytes = sequences_size_bytes;
    snapu32_t sequences_current_transfer_size_bytes;

    for (uint16_t i = 0; i < sequences_num_transfers; i++) {
        sequences_current_transfer_size_bytes =
            MIN(sequences_remaining_transfer_size_bytes, (snapu32_t)MAX_NB_OF_BYTES_READ);

        // Read burst of data from Host DRAM into Buffer
        __builtin_memcpy(
            buffer1024,
            (snap_membus_1024_t*)(din_gmem + ((sequences_host_address + sequences_address_transfer_offset) >> ADDR_RIGHT_SHIFT_1024)),
            sequences_current_transfer_size_bytes);

        membus_to_sequence_buffer(
            buffer1024, &sequences[MAX_NB_OF_WORDS_READ_1024 * i], sequences_current_transfer_size_bytes);

        sequences_remaining_transfer_size_bytes -= (snapu32_t)sequences_current_transfer_size_bytes;
        sequences_address_transfer_offset += (snapu32_t)sequences_current_transfer_size_bytes;
    }
}