#include "hls_bwt_request_processor.h"

#include "hls_ap_utils.h"
#include "hls_snap_1024.H"
#include "hls_stream_processing.h"

hbm_bwt_entry_t HBMbus_to_BWTEntry(snap_HBMbus_t buffer256[HBM_CACHE_LINES_PER_BWT_ENTRY]) {
    hbm_bwt_entry_t bwt_entry;
    for (int i = 0; i < HBM_CACHE_LINES_PER_BWT_ENTRY; i++) {
#pragma HLS unroll
        SLICE(bwt_entry, i, MEMDW_256) = buffer256[i];
    }

    return bwt_entry;
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

void bwt_request_processor_instance(
    const HBM hbm,
    ap_stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream) {
#pragma HLS pipeline
    reference_index_t k;
    while (true) {
        req_bwt_position_stream >> k;
        if (k == STREAM_TERMINATION<reference_index_t>::SIGNAL) {
            ret_bwt_entry_stream << STREAM_TERMINATION<hbm_bwt_entry_t>::SIGNAL;
            return;
        }
        hbm_bwt_entry_t bwt_entry = read_hbm_bwt_entry(hbm, k);
        ret_bwt_entry_stream << bwt_entry;
    }
}

void bwt_request_processor(
    //    action_reg* act_reg,
    const HBM hbm,
    ap_stream<reference_index_t> req_bwt_position_streams[NUM_SMEM_KERNELS],
    hls::stream<hbm_bwt_entry_t> ret_bwt_entry_streams[NUM_SMEM_KERNELS]) {
#pragma HLS INTERFACE ap_ctrl_hs port = return
    //#pragma HLS DATA_PACK variable = act_reg
    //#pragma HLS INTERFACE s_axilite port = act_reg bundle = ctrl_reg offset = 0x100
    //#pragma HLS INTERFACE s_axilite port = return bundle = ctrl_reg

    // HBM interfaces
#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p0 bundle = card_hbm_p0 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p1 bundle = card_hbm_p1 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p2 bundle = card_hbm_p2 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p3 bundle = card_hbm_p3 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p4 bundle = card_hbm_p4 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p5 bundle = card_hbm_p5 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p6 bundle = card_hbm_p6 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p7 bundle = card_hbm_p7 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p8 bundle = card_hbm_p8 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p9 bundle = card_hbm_p9 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p10 bundle = card_hbm_p10 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p11 bundle = card_hbm_p11 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p12 bundle = card_hbm_p12 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p13 bundle = card_hbm_p13 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p14 bundle = card_hbm_p14 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p15 bundle = card_hbm_p15 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p16 bundle = card_hbm_p16 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p17 bundle = card_hbm_p17 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p18 bundle = card_hbm_p18 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p19 bundle = card_hbm_p19 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p20 bundle = card_hbm_p20 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p21 bundle = card_hbm_p21 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p22 bundle = card_hbm_p22 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p23 bundle = card_hbm_p23 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p24 bundle = card_hbm_p24 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p25 bundle = card_hbm_p25 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p26 bundle = card_hbm_p26 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p27 bundle = card_hbm_p27 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p28 bundle = card_hbm_p28 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p29 bundle = card_hbm_p29 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p30 bundle = card_hbm_p30 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = hbm.d_hbm_p31 bundle = card_hbm_p31 offset = off depth = \
    512 max_read_burst_length = 64 max_write_burst_length = 64 num_write_outstanding = \
        HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = HBM_NUM_READ_OUTSTANDING

#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = req_bwt_position_streams
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = ret_bwt_entry_streams

    ap_stream<reference_index_t> req_bwt_position_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = req_bwt_position_stream
    hls::stream<hbm_bwt_entry_t> ret_bwt_entry_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = ret_bwt_entry_stream

#pragma HLS dataflow
    bidirectional_arbiter_N_to_1<ap_stream, reference_index_t, ap_stream, hbm_bwt_entry_t, NUM_SMEM_KERNELS>(
        req_bwt_position_streams, ret_bwt_entry_streams, req_bwt_position_stream, ret_bwt_entry_stream);
    bwt_request_processor_instance(hbm, req_bwt_position_stream, ret_bwt_entry_stream);
}