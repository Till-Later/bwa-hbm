#ifndef ACCELERATED_BWA_MEM_HLS_HBM_DEFINITIONS_H
#define ACCELERATED_BWA_MEM_HLS_HBM_DEFINITIONS_H

#include "hls_definitions.h"
#include "hls_snap_1024.H"

static const int HBM_NUM_WRITE_OUTSTANDING = 2;
static const int HBM_NUM_READ_OUTSTANDING = 2;

#define HBM_ADDR_BWT_ENTRY_SIZE_BITS 6
#define HBM_BWT_ENTRY_DATA_SIZE_BYTES (1 << HBM_ADDR_BWT_ENTRY_SIZE_BITS)
#define HBM_BWT_ENTRY_DATA_SIZE_BITS (HBM_BWT_ENTRY_DATA_SIZE_BYTES * 8)

#if defined(HBM_2ND_LAYER_CROSSBAR)
#define NUM_HBM_STREAMS (NUM_SMEM_CORES <= 8 ? 16 : 32) 
#else
#define NUM_HBM_STREAMS (NUM_SMEM_CORES)
#endif

#ifdef IMPLEMENT_FOR_REAL_HBM
#define HBM_BASE_ADDR_SIZE_BITS 28
#define HBM_ADDR_SELECTOR_OFFSET_BITS 17
#else
#define HBM_BASE_ADDR_SIZE_BITS 15
#define HBM_ADDR_SELECTOR_OFFSET_BITS 11
#endif

#if defined(GLOBAL_ADDRESSING) 
#define GLOBAL_ADDRESSING_EXTENSION_BITS 4
#else
#define GLOBAL_ADDRESSING_EXTENSION_BITS 0
#endif

#if defined(HBM_2ND_LAYER_CROSSBAR)
#define CROSSBAR_EXTENSION_BITS 4
#elif defined(HBM_1ST_LAYER_CROSSBAR)
#define CROSSBAR_EXTENSION_BITS 2
#else
#define CROSSBAR_EXTENSION_BITS 0
#endif

#define HBM_ADDR_SELECTOR_SIZE_BITS (CROSSBAR_EXTENSION_BITS + GLOBAL_ADDRESSING_EXTENSION_BITS)
#define HBM_ADDR_SIZE_BITS (HBM_BASE_ADDR_SIZE_BITS + HBM_ADDR_SELECTOR_SIZE_BITS)

#define BWT_ADDRESS_TO_HBM_SELECTOR(bwt_address) \
    ((bwt_address >> HBM_ADDR_SELECTOR_OFFSET_BITS) & TO_MASK(HBM_ADDR_SELECTOR_SIZE_BITS))

#define BWT_ADDRESS_TO_HARDWARE_ADDRESS(bwt_address) \
    (((bwt_address & TO_MASK(HBM_ADDR_SELECTOR_OFFSET_BITS) & ~TO_MASK(HBM_ADDR_BWT_ENTRY_SIZE_BITS)) \
        | ((bwt_address >> HBM_ADDR_SELECTOR_SIZE_BITS) & ~TO_MASK(HBM_ADDR_SELECTOR_OFFSET_BITS)) \
        | ((bwt_address & (TO_MASK(HBM_ADDR_SELECTOR_SIZE_BITS) << HBM_ADDR_SELECTOR_OFFSET_BITS)) \
           << (HBM_ADDR_SIZE_BITS - HBM_ADDR_SELECTOR_OFFSET_BITS - HBM_ADDR_SELECTOR_SIZE_BITS))))

struct HBM
{
    snap_HBMbus_t *d_hbm_p0, *d_hbm_p1, *d_hbm_p2, *d_hbm_p3, *d_hbm_p4, *d_hbm_p5, *d_hbm_p6, *d_hbm_p7, *d_hbm_p8,
        *d_hbm_p9, *d_hbm_p10, *d_hbm_p11, *d_hbm_p12, *d_hbm_p13, *d_hbm_p14, *d_hbm_p15, *d_hbm_p16, *d_hbm_p17,
        *d_hbm_p18, *d_hbm_p19, *d_hbm_p20, *d_hbm_p21, *d_hbm_p22, *d_hbm_p23, *d_hbm_p24, *d_hbm_p25, *d_hbm_p26,
        *d_hbm_p27, *d_hbm_p28, *d_hbm_p29, *d_hbm_p30, *d_hbm_p31;
};

#endif  //ACCELERATED_BWA_MEM_HLS_HBM_DEFINITIONS_H
