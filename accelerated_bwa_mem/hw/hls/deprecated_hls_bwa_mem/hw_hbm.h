#ifndef ACCELERATED_BWA_MEM_HW_HBM_H
#define ACCELERATED_BWA_MEM_HW_HBM_H

#include <ap_int.h>

#include "hls_snap_1024.H"
#include "hw_definitions.h"
#include "hls_hbm_definitions.h"

//void membus_to_HBMbus(snap_membus_1024_t* buffer_1024, snap_membus_256_t* buffer_256, uint32_t num_bytes);
//snapu64_t global_to_local_bwt_address(snapu64_t global_bwt_address);
//void write_burst_of_data_to_HBM_striped(
//    const HBM hbm,
//    snapu64_t output_address,
//    snap_HBMbus_t* buffer256,
//    snapu64_t transfer_size_bytes);
void bwt_request_processor(
    const HBM hbm,
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream);
hbm_bwt_entry_t read_hbm_bwt_entry(const HBM hbm, reference_index_t k);

#endif  //ACCELERATED_BWA_MEM_HW_HBM_H
