#include "hls_accelerator_result_buffer_definitions.h"

#include "hls_ap_utils.h"

filled_result_buffer_stream_element::filled_result_buffer_stream_element(cacheline_t ap_element) {
    int offset = 0;
    INIT_FROM_AP_ELEMENT_BITS(result_buffer_index);
    INIT_FROM_AP_ELEMENT_BITS(results_end_index);
};

filled_result_buffer_stream_element::operator cacheline_t() const {
    cacheline_t ap_element;
    int offset = 0;

    STORE_INTO_AP_ELEMENT_BITS(result_buffer_index);
    STORE_INTO_AP_ELEMENT_BITS(results_end_index);

    return ap_element;
};