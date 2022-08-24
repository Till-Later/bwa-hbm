#include "hw_hbm.h"

#include <hls_stream.h>


//// Convert a 1024 bits buffer to a 256 bits buffer
//void membus_to_HBMbus(snap_membus_1024_t* buffer_1024, snap_membus_256_t* buffer_256, uint32_t num_bytes) {
//    ap_int<MEMDW_256> mask_full = -1;
//    snap_membus_1024_t mask_256 = snap_membus_256_t(mask_full);
//    uint32_t num_words_1024 = (num_bytes >> ADDR_RIGHT_SHIFT_1024) + ((num_bytes % BPERDW_1024 != 0) ? 1 : 0);
//
//    for (int k = 0; k < num_words_1024; k++) {
//#pragma HLS unroll factor=8
//        for (int j = 0; j < MEMDW_1024 / MEMDW_256; j++) {
//#pragma HLS unroll
//            buffer_256[k * MEMDW_1024 / MEMDW_256 + j] =
//                (snap_membus_256_t)((buffer_1024[k] >> j * MEMDW_256) & mask_256);
//        }
//    }
//}

hbm_bwt_entry_t HBMbus_to_BWTEntry(snap_HBMbus_t buffer256[HBM_CACHE_LINES_PER_BWT_ENTRY]) {
    hbm_bwt_entry_t bwt_entry;
    for (int i = 0; i < HBM_CACHE_LINES_PER_BWT_ENTRY; i++) {
#pragma HLS unroll
        SLICE(bwt_entry, i, MEMDW_256) = buffer256[i];
    }

    return bwt_entry;
}

void bwt_request_processor(
    const HBM hbm,
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream) {
#pragma HLS pipeline
    reference_index_t k;
    while (true) {
        req_bwt_position_stream >> k;
        if (k == 0xffffffffffffffff) {
            ret_bwt_entry_stream.write(STREAM_TERMINATION<hbm_bwt_entry_t>::SIGNAL);
            return;
        }
        hbm_bwt_entry_t bwt_entry = read_hbm_bwt_entry(hbm, k);
        ret_bwt_entry_stream << bwt_entry;
    }
}

hbm_bwt_entry_t read_hbm_bwt_entry(const HBM hbm, reference_index_t k) {
#pragma HLS inline
    // HBM_BWT_ENTRY_SAMPLING_INTERVAL Bases per HBM_BWT_ENTRY_DATA_SIZE_BYTES chunk
    snapu64_t global_hbm_address = k >> HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS << HBM_ADDR_BWT_ENTRY_SIZE_BITS;
    snapu64_t local_hbm_address = GLOBAL_TO_LOCAL_BWT_ADDRESS(global_hbm_address);
    snap_HBMbus_t buffer256[HBM_CACHE_LINES_PER_BWT_ENTRY] = {0};
    hbm_selector_t hbm_selector = (global_hbm_address & HBM_ADDR_SELECTOR_MASK) >> HBM_ADDR_SELECTOR_RIGHT_SHIFT;

    for (uint8_t i = 0; i < HBM_BWT_ENTRY_DATA_SIZE_BYTES >> ADDR_RIGHT_SHIFT_256; i++) {
#pragma HLS unroll
        switch (hbm_selector) {
        case 0:
            buffer256[i] = *(hbm.d_hbm_p0 + (local_hbm_address + i));
            break;
        case 1:
            buffer256[i] = *(hbm.d_hbm_p1 + (local_hbm_address + i));
            break;
        case 2:
            buffer256[i] = *(hbm.d_hbm_p2 + (local_hbm_address + i));
            break;
        case 3:
            buffer256[i] = *(hbm.d_hbm_p3 + (local_hbm_address + i));
            break;
        case 4:
            buffer256[i] = *(hbm.d_hbm_p4 + (local_hbm_address + i));
            break;
        case 5:
            buffer256[i] = *(hbm.d_hbm_p5 + (local_hbm_address + i));
            break;
        case 6:
            buffer256[i] = *(hbm.d_hbm_p6 + (local_hbm_address + i));
            break;
        case 7:
            buffer256[i] = *(hbm.d_hbm_p7 + (local_hbm_address + i));
            break;
        case 8:
            buffer256[i] = *(hbm.d_hbm_p8 + (local_hbm_address + i));
            break;
        case 9:
            buffer256[i] = *(hbm.d_hbm_p9 + (local_hbm_address + i));
            break;
        case 10:
            buffer256[i] = *(hbm.d_hbm_p10 + (local_hbm_address + i));
            break;
        case 11:
            buffer256[i] = *(hbm.d_hbm_p11 + (local_hbm_address + i));
            break;
        case 12:
            buffer256[i] = *(hbm.d_hbm_p12 + (local_hbm_address + i));
            break;
        case 13:
            buffer256[i] = *(hbm.d_hbm_p13 + (local_hbm_address + i));
            break;
        case 14:
            buffer256[i] = *(hbm.d_hbm_p14 + (local_hbm_address + i));
            break;
        case 15:
            buffer256[i] = *(hbm.d_hbm_p15 + (local_hbm_address + i));
            break;
        case 16:
            buffer256[i] = *(hbm.d_hbm_p16 + (local_hbm_address + i));
            break;
        case 17:
            buffer256[i] = *(hbm.d_hbm_p17 + (local_hbm_address + i));
            break;
        case 18:
            buffer256[i] = *(hbm.d_hbm_p18 + (local_hbm_address + i));
            break;
        case 19:
            buffer256[i] = *(hbm.d_hbm_p19 + (local_hbm_address + i));
            break;
        case 20:
            buffer256[i] = *(hbm.d_hbm_p20 + (local_hbm_address + i));
            break;
        case 21:
            buffer256[i] = *(hbm.d_hbm_p21 + (local_hbm_address + i));
            break;
        case 22:
            buffer256[i] = *(hbm.d_hbm_p22 + (local_hbm_address + i));
            break;
        case 23:
            buffer256[i] = *(hbm.d_hbm_p23 + (local_hbm_address + i));
            break;
        case 24:
            buffer256[i] = *(hbm.d_hbm_p24 + (local_hbm_address + i));
            break;
        case 25:
            buffer256[i] = *(hbm.d_hbm_p25 + (local_hbm_address + i));
            break;
        case 26:
            buffer256[i] = *(hbm.d_hbm_p26 + (local_hbm_address + i));
            break;
        case 27:
            buffer256[i] = *(hbm.d_hbm_p27 + (local_hbm_address + i));
            break;
        case 28:
            buffer256[i] = *(hbm.d_hbm_p28 + (local_hbm_address + i));
            break;
        case 29:
            buffer256[i] = *(hbm.d_hbm_p29 + (local_hbm_address + i));
            break;
        case 30:
            buffer256[i] = *(hbm.d_hbm_p30 + (local_hbm_address + i));
            break;
        case 31:
            buffer256[i] = *(hbm.d_hbm_p31 + (local_hbm_address + i));
            break;
        default:
            break;
        }
    }

    return HBMbus_to_BWTEntry(buffer256);
}

// Convert a 256 bits buffer to a 1024 bits buffer
void HBMbus_to_membus(snap_membus_256_t* buffer_256, snap_membus_1024_t* buffer_1024, int size_in_words_1024) {
    snap_membus_1024_t data_entry_1024 = 0;

wb_dbuf2gbuf_loop:
    for (int k = 0; k < size_in_words_1024; k++) {
        for (int j = 0; j < MEMDW_1024 / MEMDW_256; j++) {
#pragma HLS PIPELINE
            data_entry_1024 |= ((snap_membus_1024_t)(buffer_256[k * MEMDW_1024 / MEMDW_256 + j])) << j * MEMDW_256;
        }
        buffer_1024[k] = data_entry_1024;
        data_entry_1024 = 0;
    }
    return;
}
