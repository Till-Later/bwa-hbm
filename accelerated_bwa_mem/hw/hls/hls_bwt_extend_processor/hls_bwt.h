#ifndef ACCELERATED_BWA_MEM_HW_BWT_H
#define ACCELERATED_BWA_MEM_HW_BWT_H

#include "action_aligner.h"
#include "hls_bwt_definitions.h"
#include "hls_hbm_definitions.h"
#include "hls_sequence_definitions.h"
#include "hls_snap_1024.H"
#include "hls_stream_processing.h"

typedef ap_uint<5> reference_subsection_counter_t;
typedef ap_uint<8> reference_section_counter_t;

typedef ap_uint<reference_subsection_counter_t::width * NUM_REFERENCE_SYMBOLS> reference_subsection_counter_row_t;
typedef ap_uint<reference_section_counter_t::width * NUM_REFERENCE_SYMBOLS> reference_section_counter_row_t;
typedef ap_uint<sizeof(reference_index_t) * 8 * NUM_REFERENCE_SYMBOLS> reference_index_row_t;

#define REFERENCE_SUBSECTION_SIZE_BITS 32
#define REFERENCE_ELEMENTS_PER_REFERENCE_SUBSECTION (REFERENCE_SUBSECTION_SIZE_BITS / REFERENCE_ELEMENT_SIZE_BITS)
#define REFERENCE_ELEMENT_IN_REFERENCE_SUBSECTION_OFFSET_MASK (REFERENCE_ELEMENTS_PER_REFERENCE_SUBSECTION - 1)

#define GET_REMAINDER_SUBSECTION(reference_section, k) \
    ((reference_subsection_t)SLICE( \
        reference_section, (k & HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK) >> 4, REFERENCE_SUBSECTION_SIZE_BITS))

typedef ap_uint<HBM_OCC_CELL_SIZE_BITS> occ_cell_t;
typedef ap_uint<HBM_OCC_ROW_SIZE_BITS> occ_row_t;

#define OCC_ROW_ONE_EACH \
    ((occ_row_t(1) << (3 * occ_cell_t::width)) | (occ_row_t(1) << (2 * occ_cell_t::width)) \
     | (occ_row_t(1) << (occ_cell_t::width)) | 1)

enum bwt_extend_phase
{
    IDLE = 0,
    K_L = 1,
    ONLY_K = 2,
    ONLY_L = 4,
    COMBINED_K_L = 8
};
typedef uint8_t bwt_extend_phase_t;


typedef ap_uint<HBM_ADDR_SIZE_BITS - HBM_ADDR_BWT_ENTRY_SIZE_BITS> hbm_bwt_position_address_t;
struct hbm_bwt_position
{
    static const int width = SMEM_KERNEL_PIPELINE_LOG2_DEPTH + hbm_bwt_position_address_t::width + 2 * reference_section_counter_t::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    hbm_bwt_position_address_t address;
    reference_section_counter_t k_section_counter;
    reference_section_counter_t l_section_counter;

    hbm_bwt_position() {}
    hbm_bwt_position(cacheline_t ap_element);
    operator cacheline_t() const;
};
typedef struct hbm_bwt_position hbm_bwt_position_t;

struct hbm_bwt_entry
{
    static const int width = SMEM_KERNEL_PIPELINE_LOG2_DEPTH + occ_row_t::width + 2 * reference_section_counter_row_t::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    occ_row_t occ_row;
    reference_section_counter_row_t k_section_counter_row;
    reference_section_counter_row_t l_section_counter_row;

    hbm_bwt_entry() {}
    hbm_bwt_entry(cacheline_t ap_element);
    operator cacheline_t() const;
};
typedef struct hbm_bwt_entry hbm_bwt_entry_t;

struct bwt_extend_state
{
    static const int width = 3 * reference_index_t::width
        + 2 * (local_sequence_index_t::width) + (sizeof(bwt_extend_phase_t) * 8) + ap_bool_t::width
        + sequence_element_t::width;
    typedef ap_uint<width> cacheline_t;

    reference_index_t _l;
    reference_index_t new_reverse_extended_end_position;
    reference_index_t old_interval_size;
    local_sequence_index_t query_begin_position;
    local_sequence_index_t query_end_position;
    bwt_extend_phase_t phase;
    ap_bool_t is_backward_extension;
    sequence_element_t current_sequence_element;

    bwt_extend_state(
        reference_index_t _l,
        reference_index_t new_reverse_extended_end_position,
        reference_index_t old_interval_size,
        local_sequence_index_t query_begin_position,
        local_sequence_index_t query_end_position,
        bwt_extend_phase_t phase,
        ap_bool_t is_backward_extension,
        sequence_element_t current_sequence_element)
        : _l(_l)
        , new_reverse_extended_end_position(new_reverse_extended_end_position)
        , old_interval_size(old_interval_size)
        , query_begin_position(query_begin_position)
        , query_end_position(query_end_position)
        , phase(phase)
        , is_backward_extension(is_backward_extension)
        , current_sequence_element(current_sequence_element){};
    bwt_extend_state(cacheline_t ap_element);

    operator cacheline_t() const;
};
typedef struct bwt_extend_state bwt_extend_state_t;

void bwt_extend(
    ap_stream<bwt_extend_stream_element>& req_bwt_extend_stream,
    ap_stream<bwt_extend_stream_element>& ret_bwt_extend_stream,
    ap_stream<hbm_bwt_position_t>& req_bwt_position_stream,
    ap_stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    bwtint_t bwt_primary,
    ap_uint<320> bwt_L2,
    hls::stream<bool>& termination_signal_stream,
    bwt_extend_state_t::cacheline_t states_1[SMEM_KERNEL_PIPELINE_DEPTH],
    bwt_extend_state_t::cacheline_t states_2[SMEM_KERNEL_PIPELINE_DEPTH]);

#endif  //ACCELERATED_BWA_MEM_HW_BWT_H
