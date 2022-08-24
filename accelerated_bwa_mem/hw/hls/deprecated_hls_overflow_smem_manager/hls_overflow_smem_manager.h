#ifndef ACCELERATED_BWA_MEM_HLS_OVERFLOW_SMEM_MANAGER_H
#define ACCELERATED_BWA_MEM_HLS_OVERFLOW_SMEM_MANAGER_H

#include <hls_stream.h>

#include "hls_definitions.h"
#include "hls_snap_1024.H"

void overflow_smem_manager(
    snap_membus_1024_t* gmem,
    snapu64_t smem_results_overflow_addr,
    ap_stream<bool>& req_overflow_buffer_stream,
    ap_stream<uint32_t>& ret_overflow_buffer_stream);

#endif  //ACCELERATED_BWA_MEM_HLS_OVERFLOW_SMEM_MANAGER_H
