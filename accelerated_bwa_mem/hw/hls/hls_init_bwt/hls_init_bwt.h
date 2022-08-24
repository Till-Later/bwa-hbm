#ifndef ACCELERATED_BWA_MEM_HLS_INIT_BWT_H
#define ACCELERATED_BWA_MEM_HLS_INIT_BWT_H

#include "hls_action_reg.h"
#include "hls_definitions.h"
#include "hls_hbm_definitions.h"
#include "hls_snap_1024.H"

#define NUM_HBM_SLOTS 32
#define NUM_DISTRIBUTION_BUFFERS 4

#define MIN(X, Y) (((X) < (Y)) ? (X) : (Y))
#define INIT_BWT_NUM_BYTES_READ (1 << MIN(HBM_ADDR_SELECTOR_OFFSET_BITS, 14))

#define NUM_HBM_SLOTS_PER_DISTRIBUTION_BUFFER (NUM_HBM_SLOTS / NUM_DISTRIBUTION_BUFFERS)
#define INIT_BWT_NUM_WORDS_READ_256 (INIT_BWT_NUM_BYTES_READ / BPERDW_256)
#define INIT_BWT_NUM_WORDS_READ_1024 (INIT_BWT_NUM_BYTES_READ / BPERDW_1024)

void init_bwt(
    //action_reg* act_reg,
    const snapu64_t bwt_host_address,
    const snapu32_t bwt_size_bytes,
    snap_membus_1024_t* din_gmem,
    const HBM hbm);

#endif  //ACCELERATED_BWA_MEM_HLS_INIT_BWT_H
