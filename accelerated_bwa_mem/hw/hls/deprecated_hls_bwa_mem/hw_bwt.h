#ifndef ACCELERATED_BWA_MEM_HW_BWT_H
#define ACCELERATED_BWA_MEM_HW_BWT_H

#include "hls_snap_1024.H"
#include "hw_definitions.h"
#include "hw_hbm.h"

void bwt_occ_all(const HBM hbm, reference_index_t k, reference_index_t cnt[NUM_REFERENCE_SYMBOLS]);
void bwt_2occ_all(
    const HBM hbm,
    const reference_index_t primary,
    reference_index_t k,
    reference_index_t l,
    reference_index_t cntk[NUM_REFERENCE_SYMBOLS],
    reference_index_t cntl[NUM_REFERENCE_SYMBOLS]);

bwt_interval_t accelerator_bwt_extend_forward(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    const BWT_Aux bwt_aux,
    bwt_interval_t ik,
    sequence_element_t base);

bwt_interval_t accelerator_bwt_extend_backward(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    const BWT_Aux bwt_aux,
    bwt_interval_t ik,
    sequence_element_t base);

#endif  //ACCELERATED_BWA_MEM_HW_BWT_H
