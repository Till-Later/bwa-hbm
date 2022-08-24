#include "hls_task.h"

task::task(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BYTES(task_index);
    INIT_FROM_AP_ELEMENT_BITS(sequence_offset);
    INIT_FROM_AP_ELEMENT_BITS(sequence_length);
};

task::operator cacheline_t() const {
    int offset = 0;
    cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BYTES(task_index);
    STORE_INTO_AP_ELEMENT_BITS(sequence_offset);
    STORE_INTO_AP_ELEMENT_BITS(sequence_length);

    return ap_element;
}

follow_up_task::follow_up_task(cacheline_t ap_element) {
    int offset = 0;

    INIT_FROM_AP_ELEMENT_BITS(pipeline_index);
    INIT_FROM_AP_ELEMENT_BITS(sequence_offset);
    INIT_FROM_AP_ELEMENT_BITS(start_position);
    INIT_FROM_AP_ELEMENT_BITS(sequence_length);
    INIT_FROM_AP_ELEMENT_BITS(min_intv);
    INIT_FROM_AP_ELEMENT_BITS(min_start_index);
    INIT_FROM_AP_ELEMENT_BITS(max_end_index);
};

follow_up_task::operator cacheline_t() const {
    int offset = 0;
    cacheline_t ap_element;

    STORE_INTO_AP_ELEMENT_BITS(pipeline_index);
    STORE_INTO_AP_ELEMENT_BITS(sequence_offset);
    STORE_INTO_AP_ELEMENT_BITS(start_position);
    STORE_INTO_AP_ELEMENT_BITS(sequence_length);
    STORE_INTO_AP_ELEMENT_BITS(min_intv);
    STORE_INTO_AP_ELEMENT_BITS(min_start_index);
    STORE_INTO_AP_ELEMENT_BITS(max_end_index);
    
    return ap_element;
}