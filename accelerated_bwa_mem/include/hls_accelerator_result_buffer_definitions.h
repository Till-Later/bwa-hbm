#ifndef ACCELERATED_BWA_MEM_HLS_ACCELERATOR_RESULT_BUFFER_DEFINITIONS_H
#define ACCELERATED_BWA_MEM_HLS_ACCELERATOR_RESULT_BUFFER_DEFINITIONS_H

#include "hls_bwt_definitions.h"

#define ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES_BITS (3)
#define ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES (1 << ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES_BITS)
#define ACCELERATOR_RESULT_BUFFER_SIZE (ACCELERATOR_RESULT_BUFFER_ENTRIES * NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128)
#define IOTA_ACCELERATOR_RESULT_BUFFER_ENTRIES IOTA(8)

typedef ap_uint<ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES_BITS + 1> accelerator_result_buffer_index_t;

struct filled_result_buffer_stream_element
{
    static const int width = accelerator_result_buffer_index_t::width + bwt_interval_vector_index_t::width;
    typedef ap_uint<width> cacheline_t;

    accelerator_result_buffer_index_t result_buffer_index;
    bwt_interval_vector_index_t results_end_index;

    filled_result_buffer_stream_element() {}
    filled_result_buffer_stream_element(cacheline_t ap_element);
    operator cacheline_t() const;
};

#endif  //ACCELERATED_BWA_MEM_HLS_ACCELERATOR_RESULT_BUFFER_DEFINITIONS_H