#ifndef ACCELERATED_BWA_MEM_HLS_BWT_REQUEST_PROCESSOR_H
#define ACCELERATED_BWA_MEM_HLS_BWT_REQUEST_PROCESSOR_H

#include "action_aligner.h"
#include "hls_action_reg.h"
#include "hls_bwt_definitions.h"
#include "hls_definitions.h"
#include "hls_hbm_definitions.h"
#include "hls_stream_processing.h"

#define HBM_CACHE_LINES_PER_BWT_ENTRY (HBM_BWT_ENTRY_DATA_SIZE_BYTES / BPERDW_256)

void bwt_request_processor(
    //action_reg* act_reg,
    const HBM hbm,
    ap_stream<reference_index_t> req_bwt_position_streams[NUM_SMEM_KERNELS],
    hls::stream<hbm_bwt_entry_t> ret_bwt_entry_streams[NUM_SMEM_KERNELS]);

#endif  //ACCELERATED_BWA_MEM_HLS_BWT_REQUEST_PROCESSOR_H
