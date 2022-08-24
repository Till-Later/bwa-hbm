#include "hw_bwt.h"

#include <hls_stream.h>
#include <iostream>
#include <osnap_types.h>

#include "hw_definitions.h"
#include "hw_dynamic_memory.h"
#include "hw_hbm.h"

reference_section_counter_row_t bwt_occ_add_subsections_alt1(
    const reference_section_t reference_section,
    const reference_index_t k) {
    static const snapu32_t count_table[256] = {
        0x00000004, 0x00000103, 0x00010003, 0x01000003, 0x00000103, 0x00000202, 0x00010102, 0x01000102, 0x00010003,
        0x00010102, 0x00020002, 0x01010002, 0x01000003, 0x01000102, 0x01010002, 0x02000002, 0x00000103, 0x00000202,
        0x00010102, 0x01000102, 0x00000202, 0x00000301, 0x00010201, 0x01000201, 0x00010102, 0x00010201, 0x00020101,
        0x01010101, 0x01000102, 0x01000201, 0x01010101, 0x02000101, 0x00010003, 0x00010102, 0x00020002, 0x01010002,
        0x00010102, 0x00010201, 0x00020101, 0x01010101, 0x00020002, 0x00020101, 0x00030001, 0x01020001, 0x01010002,
        0x01010101, 0x01020001, 0x02010001, 0x01000003, 0x01000102, 0x01010002, 0x02000002, 0x01000102, 0x01000201,
        0x01010101, 0x02000101, 0x01010002, 0x01010101, 0x01020001, 0x02010001, 0x02000002, 0x02000101, 0x02010001,
        0x03000001, 0x00000103, 0x00000202, 0x00010102, 0x01000102, 0x00000202, 0x00000301, 0x00010201, 0x01000201,
        0x00010102, 0x00010201, 0x00020101, 0x01010101, 0x01000102, 0x01000201, 0x01010101, 0x02000101, 0x00000202,
        0x00000301, 0x00010201, 0x01000201, 0x00000301, 0x00000400, 0x00010300, 0x01000300, 0x00010201, 0x00010300,
        0x00020200, 0x01010200, 0x01000201, 0x01000300, 0x01010200, 0x02000200, 0x00010102, 0x00010201, 0x00020101,
        0x01010101, 0x00010201, 0x00010300, 0x00020200, 0x01010200, 0x00020101, 0x00020200, 0x00030100, 0x01020100,
        0x01010101, 0x01010200, 0x01020100, 0x02010100, 0x01000102, 0x01000201, 0x01010101, 0x02000101, 0x01000201,
        0x01000300, 0x01010200, 0x02000200, 0x01010101, 0x01010200, 0x01020100, 0x02010100, 0x02000101, 0x02000200,
        0x02010100, 0x03000100, 0x00010003, 0x00010102, 0x00020002, 0x01010002, 0x00010102, 0x00010201, 0x00020101,
        0x01010101, 0x00020002, 0x00020101, 0x00030001, 0x01020001, 0x01010002, 0x01010101, 0x01020001, 0x02010001,
        0x00010102, 0x00010201, 0x00020101, 0x01010101, 0x00010201, 0x00010300, 0x00020200, 0x01010200, 0x00020101,
        0x00020200, 0x00030100, 0x01020100, 0x01010101, 0x01010200, 0x01020100, 0x02010100, 0x00020002, 0x00020101,
        0x00030001, 0x01020001, 0x00020101, 0x00020200, 0x00030100, 0x01020100, 0x00030001, 0x00030100, 0x00040000,
        0x01030000, 0x01020001, 0x01020100, 0x01030000, 0x02020000, 0x01010002, 0x01010101, 0x01020001, 0x02010001,
        0x01010101, 0x01010200, 0x01020100, 0x02010100, 0x01020001, 0x01020100, 0x01030000, 0x02020000, 0x02010001,
        0x02010100, 0x02020000, 0x03010000, 0x01000003, 0x01000102, 0x01010002, 0x02000002, 0x01000102, 0x01000201,
        0x01010101, 0x02000101, 0x01010002, 0x01010101, 0x01020001, 0x02010001, 0x02000002, 0x02000101, 0x02010001,
        0x03000001, 0x01000102, 0x01000201, 0x01010101, 0x02000101, 0x01000201, 0x01000300, 0x01010200, 0x02000200,
        0x01010101, 0x01010200, 0x01020100, 0x02010100, 0x02000101, 0x02000200, 0x02010100, 0x03000100, 0x01010002,
        0x01010101, 0x01020001, 0x02010001, 0x01010101, 0x01010200, 0x01020100, 0x02010100, 0x01020001, 0x01020100,
        0x01030000, 0x02020000, 0x02010001, 0x02010100, 0x02020000, 0x03010000, 0x02000002, 0x02000101, 0x02010001,
        0x03000001, 0x02000101, 0x02000200, 0x02010100, 0x03000100, 0x02010001, 0x02010100, 0x02020000, 0x03010000,
        0x03000001, 0x03000100, 0x03010000, 0x04000000,
    };
    // TODO-TILL: Remove magic number
    uint16_t k_num_full_reference_subsections = (k & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK) >> 4;
    reference_section_counter_row_t counter_row;
    reference_section_counter_t count[NUM_REFERENCE_SYMBOLS] = {0, 0, 0, 0};


    for (uint8_t i = 0; i < 7; i++) {
        // Use continue instead of break to enable HLS loop unrolling
        if (i >= k_num_full_reference_subsections) continue;
        snapu32_t subsection_sum =
            /*count_subsections[i] = */ count_table[SLICE(reference_section, (i << 2) | 0, 8)]
            + count_table[SLICE(reference_section, (i << 2) | 1, 8)]
            + count_table[SLICE(reference_section, (i << 2) | 2, 8)]
            + count_table[SLICE(reference_section, (i << 2) | 3, 8)];

        count[0] += (reference_index_t)SLICE(subsection_sum, 0, 8);
        count[1] += (reference_index_t)SLICE(subsection_sum, 1, 8);
        count[2] += (reference_index_t)SLICE(subsection_sum, 2, 8);
        count[3] += (reference_index_t)SLICE(subsection_sum, 3, 8);
    }

    SLICE(counter_row, 0, reference_section_counter_t::width) = count[0];
    SLICE(counter_row, 1, reference_section_counter_t::width) = count[1];
    SLICE(counter_row, 2, reference_section_counter_t::width) = count[2];
    SLICE(counter_row, 3, reference_section_counter_t::width) = count[3];
    return counter_row;
}

reference_section_counter_row_t bwt_occ_add_subsections(
    const reference_section_t reference_section,
    const reference_index_t k) {
    static const ap_uint<3> count_table[NUM_REFERENCE_SYMBOLS][256] = {
        {
            4, 3, 3, 3, 3, 2, 2, 2, 3, 2, 2, 2, 3, 2, 2, 2, 3, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1,
            3, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 3, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1,
            3, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
            2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
            3, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
            2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
            3, 2, 2, 2, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
            2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 2, 1, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0,
        },
        {
            0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 2, 1, 1, 2, 3, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1,
            0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0,
            1, 2, 1, 1, 2, 3, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1, 2, 3, 2, 2, 3, 4, 3, 3, 2, 3, 2, 2, 2, 3, 2, 2,
            1, 2, 1, 1, 2, 3, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 2, 3, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1,
            0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 2, 1, 1, 2, 3, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1,
            0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0,
            0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 2, 1, 1, 2, 3, 2, 2, 1, 2, 1, 1, 1, 2, 1, 1,
            0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 2, 1, 1, 0, 1, 0, 0, 0, 1, 0, 0,
        },
        {
            0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0,
            1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0,
            0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0,
            1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0,
            1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1,
            2, 2, 3, 2, 2, 2, 3, 2, 3, 3, 4, 3, 2, 2, 3, 2, 1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1,
            0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0,
            1, 1, 2, 1, 1, 1, 2, 1, 2, 2, 3, 2, 1, 1, 2, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 2, 1, 0, 0, 1, 0,
        },
        {
            0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2,
            0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 3,
            0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2,
            0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 3,
            0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2,
            0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 3,
            1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 3, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 3,
            1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 2, 2, 2, 3, 2, 2, 2, 3, 2, 2, 2, 3, 2, 2, 2, 3, 3, 3, 3, 4,
        },
    };

    uint16_t k_num_full_reference_subsections = (k & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK) >> 4;

    reference_section_counter_t count[NUM_REFERENCE_SYMBOLS] = {0, 0, 0, 0};

    for (uint8_t i = 0; i < 7; i++) {
#pragma HLS unroll
        // Use continue instead of break to enable HLS loop unrolling
        if (i >= k_num_full_reference_subsections) continue;

        count[0] += count_table[0][SLICE(reference_section, (i << 2) | 0, 8)]
            + count_table[0][SLICE(reference_section, (i << 2) | 1, 8)]
            + count_table[0][SLICE(reference_section, (i << 2) | 2, 8)]
            + count_table[0][SLICE(reference_section, (i << 2) | 3, 8)];

        count[1] += count_table[1][SLICE(reference_section, (i << 2) | 0, 8)]
            + count_table[1][SLICE(reference_section, (i << 2) | 1, 8)]
            + count_table[1][SLICE(reference_section, (i << 2) | 2, 8)]
            + count_table[1][SLICE(reference_section, (i << 2) | 3, 8)];

        count[2] += count_table[2][SLICE(reference_section, (i << 2) | 0, 8)]
            + count_table[2][SLICE(reference_section, (i << 2) | 1, 8)]
            + count_table[2][SLICE(reference_section, (i << 2) | 2, 8)]
            + count_table[2][SLICE(reference_section, (i << 2) | 3, 8)];

        count[3] += count_table[3][SLICE(reference_section, (i << 2) | 0, 8)]
            + count_table[3][SLICE(reference_section, (i << 2) | 1, 8)]
            + count_table[3][SLICE(reference_section, (i << 2) | 2, 8)]
            + count_table[3][SLICE(reference_section, (i << 2) | 3, 8)];
    }

    reference_section_counter_row_t counter_row;
    SLICE(counter_row, 0, reference_section_counter_t::width) = count[0];
    SLICE(counter_row, 1, reference_section_counter_t::width) = count[1];
    SLICE(counter_row, 2, reference_section_counter_t::width) = count[2];
    SLICE(counter_row, 3, reference_section_counter_t::width) = count[3];
    return counter_row;
}


reference_subsection_counter_row_t bwt_occ_add_remainder_subsection(
    const reference_subsection_t reference_subsection,
    const reference_subsection_counter_t k) {
#pragma HLS pipeline

    reference_subsection_counter_t count[NUM_REFERENCE_SYMBOLS] = {0, 0, 0, 0};
    reference_subsection_counter_row_t counter_row;
    for (reference_subsection_counter_t i = 0; i < REFERENCE_ELEMENTS_PER_REFERENCE_SUBSECTION; i++) {
#pragma HLS unroll
        if (i > k) continue;

        count[SLICE(
            reference_subsection,
            REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK - i,
            REFERENCE_ELEMENT_SIZE_BITS)]++;
    }

    SLICE(counter_row, 0, reference_subsection_counter_t::width) = count[0];
    SLICE(counter_row, 1, reference_subsection_counter_t::width) = count[1];
    SLICE(counter_row, 2, reference_subsection_counter_t::width) = count[2];
    SLICE(counter_row, 3, reference_subsection_counter_t::width) = count[3];
    return counter_row;
}


void bwt_occ_all(const HBM hbm, reference_index_t k, reference_index_t count[NUM_REFERENCE_SYMBOLS]) {
    // TODO-TIL: Enable values of HBM_NUM_REFERENCE_ELEMENTS_PER_BWT_ENTRY that are not a power of 2
    hbm_bwt_entry_t hbm_bwt_entry = read_hbm_bwt_entry(hbm, k);
    reference_section_t reference_section = SLICE_OFFSET(
        hbm_bwt_entry,
        HBM_OCC_ROW_SIZE_BITS,
        0,
        REFERENCE_ELEMENT_SIZE_BITS * HBM_NUM_REFERENCE_ELEMENTS_PER_BWT_ENTRY);

    reference_section_counter_row_t section_counter = bwt_occ_add_subsections(reference_section, k);
    reference_subsection_counter_row_t subsection_counter = bwt_occ_add_remainder_subsection(
        GET_REMAINDER_SUBSECTION(reference_section, k),
        (reference_subsection_counter_t)k & REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK);

    for (uint8_t i = 0; i < NUM_REFERENCE_SYMBOLS; i++) {
#pragma HLS unroll
        count[i] = SLICE(hbm_bwt_entry, i, HBM_OCC_CELL_SIZE_BITS)
            + SLICE(section_counter, i, reference_section_counter_t::width)
            + SLICE(subsection_counter, i, reference_subsection_counter_t::width);
    }
}

void bwt_occ_all_streamed(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    reference_index_t k,
    reference_index_t count[NUM_REFERENCE_SYMBOLS]) {
    // TODO-TIL: Enable values of HBM_NUM_REFERENCE_ELEMENTS_PER_BWT_ENTRY that are not a power of 2
    hbm_bwt_entry_t hbm_bwt_entry;
    req_bwt_position_stream.write(k);
    ret_bwt_entry_stream.read(hbm_bwt_entry);
    reference_section_t reference_section = SLICE_OFFSET(
        hbm_bwt_entry,
        HBM_OCC_ROW_SIZE_BITS,
        0,
        REFERENCE_ELEMENT_SIZE_BITS * HBM_NUM_REFERENCE_ELEMENTS_PER_BWT_ENTRY);

    reference_section_counter_row_t section_counter = bwt_occ_add_subsections(reference_section, k);
    reference_subsection_counter_row_t subsection_counter = bwt_occ_add_remainder_subsection(
        GET_REMAINDER_SUBSECTION(reference_section, k),
        (reference_subsection_counter_t)k & REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK);

    for (uint8_t i = 0; i < NUM_REFERENCE_SYMBOLS; i++) {
#pragma HLS unroll
        count[i] = SLICE(hbm_bwt_entry, i, HBM_OCC_CELL_SIZE_BITS)
            + SLICE(section_counter, i, reference_section_counter_t::width)
            + SLICE(subsection_counter, i, reference_subsection_counter_t::width);
    }
}

void bwt_occ_all_streamed_req(hls::stream<reference_index_t>& req_bwt_position_stream, reference_index_t k) {
    //#pragma HLS inline off // not necessary
    req_bwt_position_stream.write(k);
}

void bwt_occ_all_streamed_ret(
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    reference_index_t k,
    reference_index_t count[NUM_REFERENCE_SYMBOLS]) {
    hbm_bwt_entry_t hbm_bwt_entry;
    ret_bwt_entry_stream.read(hbm_bwt_entry);
    reference_section_t reference_section = SLICE_OFFSET(
        hbm_bwt_entry,
        HBM_OCC_ROW_SIZE_BITS,
        0,
        REFERENCE_ELEMENT_SIZE_BITS * HBM_NUM_REFERENCE_ELEMENTS_PER_BWT_ENTRY);

    reference_section_counter_row_t section_counter = bwt_occ_add_subsections(reference_section, k);
    reference_subsection_counter_row_t subsection_counter = bwt_occ_add_remainder_subsection(
        GET_REMAINDER_SUBSECTION(reference_section, k),
        (reference_subsection_counter_t)k & REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK);

    for (uint8_t i = 0; i < NUM_REFERENCE_SYMBOLS; i++) {
#pragma HLS unroll
        count[i] = SLICE(hbm_bwt_entry, i, HBM_OCC_CELL_SIZE_BITS)
            + SLICE(section_counter, i, reference_section_counter_t::width)
            + SLICE(subsection_counter, i, reference_subsection_counter_t::width);
    }
}

void bwt_occ_all_streamed_dataflow(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    reference_index_t k,
    reference_index_t count[NUM_REFERENCE_SYMBOLS]) {
    // Vivado combines read and write into one FSM-Step, resulting in a deadlock => split read/write into two functions
#pragma HLS dataflow
    bwt_occ_all_streamed_req(req_bwt_position_stream, k);
    bwt_occ_all_streamed_ret(ret_bwt_entry_stream, k, count);
}

void bwt_2occ_all(
    const HBM hbm,
    const reference_index_t primary,
    reference_index_t k,
    reference_index_t l,
    reference_index_t cntk[NUM_REFERENCE_SYMBOLS],
    reference_index_t cntl[NUM_REFERENCE_SYMBOLS]) {
    reference_index_t _k, _l;
    _k = k - (k >= primary);  // because $ is not in bwt
    _l = l - (l >= primary);

    // TODO-TIL: Remove cases where k == -1
    if (k == (reference_index_t)(-1) || l == (reference_index_t)(-1)) {
        // Make sure cntk and cntl are 0-initialized!
        if (k != (reference_index_t)(-1))
            bwt_occ_all(hbm, _k, cntk);
        else if (l != (reference_index_t)(-1))
            bwt_occ_all(hbm, _l, cntl);
    } else if (_l >> HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS != _k >> HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS) {
        bwt_occ_all(hbm, _k, cntk);
        bwt_occ_all(hbm, _l, cntl);
    } else {
        hbm_bwt_entry_t hbm_bwt_entry = read_hbm_bwt_entry(hbm, _k);
        reference_section_t reference_section = SLICE_OFFSET(
            hbm_bwt_entry,
            HBM_OCC_ROW_SIZE_BITS,
            0,
            REFERENCE_ELEMENT_SIZE_BITS * HBM_NUM_REFERENCE_ELEMENTS_PER_BWT_ENTRY);

        reference_section_counter_row_t section_counter_k = bwt_occ_add_subsections(reference_section, _k);
        reference_section_counter_row_t section_counter_l = bwt_occ_add_subsections(reference_section, _l);
        reference_subsection_counter_row_t subsection_counter_k = bwt_occ_add_remainder_subsection(
            GET_REMAINDER_SUBSECTION(reference_section, _k),
            (reference_subsection_counter_t)(_k & REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK));
        reference_subsection_counter_row_t subsection_counter_l = bwt_occ_add_remainder_subsection(
            GET_REMAINDER_SUBSECTION(reference_section, _l),
            (reference_subsection_counter_t)(_l & REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK));

        for (uint8_t i = 0; i < NUM_REFERENCE_SYMBOLS; i++) {
#pragma HLS unroll
            cntk[i] = SLICE(hbm_bwt_entry, i, HBM_OCC_CELL_SIZE_BITS)
                + SLICE(section_counter_k, i, reference_section_counter_t::width)
                + SLICE(subsection_counter_k, i, reference_subsection_counter_t::width);

            cntl[i] = SLICE(hbm_bwt_entry, i, HBM_OCC_CELL_SIZE_BITS)
                + SLICE(section_counter_l, i, reference_section_counter_t::width)
                + SLICE(subsection_counter_l, i, reference_subsection_counter_t::width);
        }
    }
}


void bwt_2occ_all_streamed(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    const reference_index_t primary,
    reference_index_t k,
    reference_index_t l,
    reference_index_t cntk[NUM_REFERENCE_SYMBOLS],
    reference_index_t cntl[NUM_REFERENCE_SYMBOLS]) {
    reference_index_t _k, _l;
    _k = k - (k >= primary);  // because $ is not in bwt
    _l = l - (l >= primary);

    // TODO-TIL: Remove cases where k == -1
    if (k == (reference_index_t)(-1) || l == (reference_index_t)(-1)) {
        // Make sure cntk and cntl are 0-initialized!
        if (k != (reference_index_t)(-1))
            bwt_occ_all_streamed_dataflow(req_bwt_position_stream, ret_bwt_entry_stream, _k, cntk);
        else if (l != (reference_index_t)(-1))
            bwt_occ_all_streamed(req_bwt_position_stream, ret_bwt_entry_stream, _l, cntl);
    } else /*if (_l >> HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS != _k >> HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS)*/ {
        bwt_occ_all_streamed_dataflow(req_bwt_position_stream, ret_bwt_entry_stream, _k, cntk);
        bwt_occ_all_streamed_dataflow(req_bwt_position_stream, ret_bwt_entry_stream, _l, cntl);
    } /*else {
        hbm_bwt_entry_t hbm_bwt_entry;
        req_bwt_position_stream.write(_k);
        ret_bwt_entry_stream.read(hbm_bwt_entry);
        reference_section_t reference_section = SLICE_OFFSET(
            hbm_bwt_entry,
            HBM_OCC_ROW_SIZE_BITS,
            0,
            REFERENCE_ELEMENT_SIZE_BITS * HBM_NUM_REFERENCE_ELEMENTS_PER_BWT_ENTRY);

        reference_section_counter_row_t section_counter_k = bwt_occ_add_subsections(reference_section, _k);
        reference_section_counter_row_t section_counter_l = bwt_occ_add_subsections(reference_section, _l);
        reference_subsection_counter_row_t subsection_counter_k = bwt_occ_add_remainder_subsection(
            GET_REMAINDER_SUBSECTION(reference_section, _k),
            (reference_subsection_counter_t)(_k & REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK));
        reference_subsection_counter_row_t subsection_counter_l = bwt_occ_add_remainder_subsection(
            GET_REMAINDER_SUBSECTION(reference_section, _l),
            (reference_subsection_counter_t)(_l & REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK));

        for (uint8_t i = 0; i < NUM_REFERENCE_SYMBOLS; i++) {
#pragma HLS unroll
            cntk[i] = SLICE(hbm_bwt_entry, i, HBM_OCC_CELL_SIZE_BITS)
                + SLICE(section_counter_k, i, reference_section_counter_t::width)
                + SLICE(subsection_counter_k, i, reference_subsection_counter_t::width);

            cntl[i] = SLICE(hbm_bwt_entry, i, HBM_OCC_CELL_SIZE_BITS)
                + SLICE(section_counter_l, i, reference_section_counter_t::width)
                + SLICE(subsection_counter_l, i, reference_subsection_counter_t::width);
        }
    }*/
}


bwt_interval_t accelerator_bwt_extend_forward(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    const BWT_Aux bwt_aux,
    bwt_interval_t ik,
    sequence_element_t base) {
    bwt_interval_t ok[4];
    base = 3 - base;

    reference_index_t tk[4] = {0}, tl[4] = {0};
    bwt_2occ_all_streamed(
        req_bwt_position_stream, ret_bwt_entry_stream, bwt_aux.primary, ik.x[1] - 1, ik.x[1] - 1 + ik.x[2], tk, tl);
    for (uint8_t i = 0; i < 4; ++i) {
        ok[i].x[1] = bwt_aux.L2[i] + 1 + tk[i];
        ok[i].x[2] = tl[i] - tk[i];
    }
    ok[3].x[0] = ik.x[0] + (ik.x[1] <= bwt_aux.primary && ik.x[1] + ik.x[2] - 1 >= bwt_aux.primary);
    ok[2].x[0] = ok[3].x[0] + ok[3].x[2];
    ok[1].x[0] = ok[2].x[0] + ok[2].x[2];
    ok[0].x[0] = ok[1].x[0] + ok[1].x[2];
    return ok[base];
}

bwt_interval_t accelerator_bwt_extend_backward(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    const BWT_Aux bwt_aux,
    bwt_interval_t ik,
    sequence_element_t base) {
    bwt_interval_t ok[4];
    ok[base].info = ik.info;

    reference_index_t tk[4], tl[4];
    bwt_2occ_all_streamed(
        req_bwt_position_stream, ret_bwt_entry_stream, bwt_aux.primary, ik.x[0] - 1, ik.x[0] - 1 + ik.x[2], tk, tl);
    for (uint8_t i = 0; i < 4; ++i) {
        ok[i].x[0] = bwt_aux.L2[i] + 1 + tk[i];
        ok[i].x[2] = tl[i] - tk[i];
    }
    ok[3].x[1] = ik.x[1] + (ik.x[0] <= bwt_aux.primary && ik.x[0] + ik.x[2] - 1 >= bwt_aux.primary);
    ok[2].x[1] = ok[3].x[1] + ok[3].x[2];
    ok[1].x[1] = ok[2].x[1] + ok[2].x[2];
    ok[0].x[1] = ok[1].x[1] + ok[1].x[2];
    return ok[base];
}
