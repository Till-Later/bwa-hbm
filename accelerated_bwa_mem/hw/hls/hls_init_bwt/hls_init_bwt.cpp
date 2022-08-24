#include "hls_init_bwt.h"

#include <cmath>
#include <stdio.h>
#include <string.h>

#include "hls_snap_1024.H"

// Convert a 1024 bits buffer to a 256 bits buffer
void membus_to_HBMbus(snap_membus_1024_t* buffer_1024, snap_membus_256_t* buffer_256, uint32_t num_bytes) {
    ap_int<MEMDW_256> mask_full = -1;
    snap_membus_1024_t mask_256 = snap_membus_256_t(mask_full);
    uint32_t num_words_1024 = (num_bytes >> ADDR_RIGHT_SHIFT_1024) + ((num_bytes % BPERDW_1024 != 0) ? 1 : 0);

    for (int k = 0; k < num_words_1024; k++) {
#pragma HLS unroll factor = 8
        for (int j = 0; j < MEMDW_1024 / MEMDW_256; j++) {
#pragma HLS unroll
            buffer_256[k * MEMDW_1024 / MEMDW_256 + j] =
                (snap_membus_256_t)((buffer_1024[k] >> j * MEMDW_256) & mask_256);
        }
    }
}

void write_burst_of_data_to_HBM(
    const HBM hbm,
    uint8_t hbm_selector,
    snapu64_t output_address,
    snap_membus_256_t buffer256[INIT_BWT_NUM_WORDS_READ_256],
    snapu64_t transfer_size_bytes) {
    switch (hbm_selector) {
    case 0:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p0 + output_address), buffer256, transfer_size_bytes);
        return;
    case 1:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p1 + output_address), buffer256, transfer_size_bytes);
        return;
    case 2:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p2 + output_address), buffer256, transfer_size_bytes);
        return;
    case 3:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p3 + output_address), buffer256, transfer_size_bytes);
        return;
    case 4:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p4 + output_address), buffer256, transfer_size_bytes);
        return;
    case 5:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p5 + output_address), buffer256, transfer_size_bytes);
        return;
    case 6:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p6 + output_address), buffer256, transfer_size_bytes);
        return;
    case 7:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p7 + output_address), buffer256, transfer_size_bytes);
        return;
    case 8:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p8 + output_address), buffer256, transfer_size_bytes);
        return;
    case 9:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p9 + output_address), buffer256, transfer_size_bytes);
        return;
    case 10:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p10 + output_address), buffer256, transfer_size_bytes);
        return;
    case 11:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p11 + output_address), buffer256, transfer_size_bytes);
        return;
    case 12:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p12 + output_address), buffer256, transfer_size_bytes);
        return;
    case 13:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p13 + output_address), buffer256, transfer_size_bytes);
        return;
    case 14:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p14 + output_address), buffer256, transfer_size_bytes);
        return;
    case 15:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p15 + output_address), buffer256, transfer_size_bytes);
        return;
    case 16:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p16 + output_address), buffer256, transfer_size_bytes);
        return;
    case 17:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p17 + output_address), buffer256, transfer_size_bytes);
        return;
    case 18:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p18 + output_address), buffer256, transfer_size_bytes);
        return;
    case 19:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p19 + output_address), buffer256, transfer_size_bytes);
        return;
    case 20:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p20 + output_address), buffer256, transfer_size_bytes);
        return;
    case 21:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p21 + output_address), buffer256, transfer_size_bytes);
        return;
    case 22:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p22 + output_address), buffer256, transfer_size_bytes);
        return;
    case 23:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p23 + output_address), buffer256, transfer_size_bytes);
        return;
    case 24:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p24 + output_address), buffer256, transfer_size_bytes);
        return;
    case 25:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p25 + output_address), buffer256, transfer_size_bytes);
        return;
    case 26:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p26 + output_address), buffer256, transfer_size_bytes);
        return;
    case 27:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p27 + output_address), buffer256, transfer_size_bytes);
        return;
    case 28:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p28 + output_address), buffer256, transfer_size_bytes);
        return;
    case 29:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p29 + output_address), buffer256, transfer_size_bytes);
        return;
    case 30:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p30 + output_address), buffer256, transfer_size_bytes);
        return;
    case 31:
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p31 + output_address), buffer256, transfer_size_bytes);
        return;
    default:
        return;
    }
}

void init_bwt(const snapu64_t bwt_host_address, const snapu32_t bwt_size, snap_membus_1024_t* host_mem, const HBM hbm) {
#pragma HLS INTERFACE ap_ctrl_hs port = return

#pragma HLS INTERFACE m_axi port = host_mem offset = off max_read_burst_length = 16 max_write_burst_length = 2

    // HBM interfaces
#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p0 bundle = card_hbm_0 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p1 bundle = card_hbm_1 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p2 bundle = card_hbm_2 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p3 bundle = card_hbm_3 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p4 bundle = card_hbm_4 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p5 bundle = card_hbm_5 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p6 bundle = card_hbm_6 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p7 bundle = card_hbm_7 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p8 bundle = card_hbm_8 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p9 bundle = card_hbm_9 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p10 bundle = card_hbm_10 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p11 bundle = card_hbm_11 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p12 bundle = card_hbm_12 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p13 bundle = card_hbm_13 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p14 bundle = card_hbm_14 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p15 bundle = card_hbm_15 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p16 bundle = card_hbm_16 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p17 bundle = card_hbm_17 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p18 bundle = card_hbm_18 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p19 bundle = card_hbm_19 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p20 bundle = card_hbm_20 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p21 bundle = card_hbm_21 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p22 bundle = card_hbm_22 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p23 bundle = card_hbm_23 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p24 bundle = card_hbm_24 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p25 bundle = card_hbm_25 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p26 bundle = card_hbm_26 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p27 bundle = card_hbm_27 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p28 bundle = card_hbm_28 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p29 bundle = card_hbm_29 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p30 bundle = card_hbm_30 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p31 bundle = card_hbm_31 offset = off max_read_burst_length = \
    2 max_write_burst_length = 32 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

    snap_membus_1024_t buffer1024[INIT_BWT_NUM_WORDS_READ_1024];
    snap_membus_256_t buffer256[INIT_BWT_NUM_WORDS_READ_256];
    snap_membus_256_t distribution_buffers[NUM_DISTRIBUTION_BUFFERS][INIT_BWT_NUM_WORDS_READ_256];
#pragma HLS array_partition variable = distribution_buffers complete dim = 1

    const snapu64_t hbm_base_address = 0x0;
    const snapu64_t bwt_size_bytes = bwt_size * sizeof(uint32_t);
    const snapu32_t bwt_num_transfers =
        (bwt_size_bytes / INIT_BWT_NUM_BYTES_READ) + ((bwt_size_bytes % INIT_BWT_NUM_BYTES_READ) ? 1 : 0);

    snapu64_t bwt_address_transfer_offset = 0;
    snapu32_t bwt_remaining_transfer_size_bytes = bwt_size_bytes;
    snapu32_t bwt_current_transfer_size_bytes;

    for (uint32_t i = 0; i < bwt_num_transfers; i++) {
        bwt_current_transfer_size_bytes = MIN(bwt_remaining_transfer_size_bytes, (snapu32_t)INIT_BWT_NUM_BYTES_READ);

        // Read burst of data from Host DRAM into Buffer
        __builtin_memcpy(
            buffer1024,
            (snap_membus_1024_t*)(host_mem + ((bwt_host_address + bwt_address_transfer_offset) >> ADDR_RIGHT_SHIFT_1024)),
            bwt_current_transfer_size_bytes);

        membus_to_HBMbus(buffer1024, buffer256, bwt_current_transfer_size_bytes);

        snapu64_t ceiled_transfer_size = ((bwt_current_transfer_size_bytes + (BPERDW_256 - 1)) & ~(BPERDW_256 - 1));
        uint32_t num_words_256 = (bwt_current_transfer_size_bytes >> ADDR_RIGHT_SHIFT_256)
            + ((bwt_current_transfer_size_bytes % BPERDW_256 != 0) ? 1 : 0);
        snapu64_t local_hbm_address =
            BWT_ADDRESS_TO_HARDWARE_ADDRESS(hbm_base_address + bwt_address_transfer_offset) >> ADDR_RIGHT_SHIFT_256;
#if defined(GLOBAL_ADDRESSING) and defined(IMPLEMENT_FOR_REAL_HBM)
        // Only write to d_hbm_p0, propagation through global addressing
        __builtin_memcpy((snap_HBMbus_t*)(hbm.d_hbm_p0 + local_hbm_address), buffer256, ceiled_transfer_size);
#elif defined(HBM_2ND_LAYER_CROSSBAR)
        for (int selector_offset = 0; selector_offset < NUM_HBM_STREAMS / 16; selector_offset++) {
            write_burst_of_data_to_HBM(
                hbm,
                16 * selector_offset + BWT_ADDRESS_TO_HBM_SELECTOR(hbm_base_address + bwt_address_transfer_offset),
                local_hbm_address & TO_MASK(HBM_BASE_ADDR_SIZE_BITS),
                buffer256,
                ceiled_transfer_size);
        }
#elif defined(HBM_1ST_LAYER_CROSSBAR)
        // If no global addressing available, write to the targeted hbm directly
        for (int selector_offset = 0; selector_offset < NUM_HBM_STREAMS / 4; selector_offset++) {
            write_burst_of_data_to_HBM(
                hbm,
                4 * selector_offset + BWT_ADDRESS_TO_HBM_SELECTOR(hbm_base_address + bwt_address_transfer_offset),
                local_hbm_address & TO_MASK(HBM_BASE_ADDR_SIZE_BITS),
                buffer256,
                ceiled_transfer_size);
        }
#else
        for (uint8_t j = 0; j < NUM_DISTRIBUTION_BUFFERS; j++) {
            for (uint32_t k = 0; k < num_words_256; k++) {
                distribution_buffers[j][k] = buffer256[k];
            }
        }

        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p0 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);

#if NUM_SMEM_CORES > 1
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p1 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 2
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p2 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 3
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p3 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 4
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p4 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p5 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p6 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p7 + local_hbm_address), distribution_buffers[0], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 8
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p8 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p9 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p10 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p11 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 12
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p12 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p13 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p14 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p15 + local_hbm_address), distribution_buffers[1], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 16
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p16 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p17 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p18 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p19 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 20
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p20 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p21 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p22 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p23 + local_hbm_address), distribution_buffers[2], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 24
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p24 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p25 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p26 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p27 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
#endif

#if NUM_SMEM_CORES > 28
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p28 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p29 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p30 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
        __builtin_memcpy(
            (snap_HBMbus_t*)(hbm.d_hbm_p31 + local_hbm_address), distribution_buffers[3], ceiled_transfer_size);
#endif
#endif
        bwt_remaining_transfer_size_bytes -= (snapu32_t)bwt_current_transfer_size_bytes;
        bwt_address_transfer_offset += (snapu32_t)bwt_current_transfer_size_bytes;
    }
}
