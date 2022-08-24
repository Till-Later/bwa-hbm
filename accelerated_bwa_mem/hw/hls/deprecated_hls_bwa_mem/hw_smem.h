#ifndef ACCELERATED_BWA_MEM_HW_SMEM_H
#define ACCELERATED_BWA_MEM_HW_SMEM_H

#include "hls_snap_1024.H"
#include "hw_bwt.h"
#include "hw_definitions.h"
#include "hw_dynamic_memory.h"

void accelerator_bwt_smem(
    const BWT_Aux bwt_aux,
    Task task,
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream,
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    hls::stream<SMEM_Result>& smem_result_stream);

#endif  //ACCELERATED_BWA_MEM_HW_SMEM_H
