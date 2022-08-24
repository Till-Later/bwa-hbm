#ifndef ACCELERATED_BWA_MEM_HLS_BWT_DEFINITIONS_H
#define ACCELERATED_BWA_MEM_HLS_BWT_DEFINITIONS_H

#include <ap_int.h>

#include "action_aligner.h"
#include "hls_definitions.h"
#include "hls_hbm_definitions.h"
#include "hls_sequence_definitions.h"
#include "hls_stream_processing.h"

#define HBM_OCC_CELL_SIZE_BITS (34)
#define HBM_OCC_ROW_SIZE_BITS (NUM_REFERENCE_SYMBOLS * HBM_OCC_CELL_SIZE_BITS)

typedef ap_uint<SMEM_KERNEL_PIPELINE_LOG2_DEPTH + 1> smem_kernel_pipeline_index_t;

//  HBM_BWT_ENTRY_T
//  ┏━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━...━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━...━━━━...━━┓
//  ┃ PIPELINE ┃ HBM_OCC_ROW                                    ...  ┃ REFERENCE_SECTION               ...    ...  ┃
//  ┃ _INDEX   ┃ ╔══════════════╦══════════════╦══════════════╦═...═╗┃ ╔══════════════╦══════════════╦═...═╦══...═╗┃
//  ┃          ┃ ║ HBM_OCC_CELL ║ (*NUM_REFERE ║ NCE_SYMBOLS) ║ ... ║┃ ║ REFERENCE_SUB║ SECTION      ║ ... ║  ... ║┃
//  ┃          ┃ ╚══════════════╩══════════════╩══════════════╩═...═╝┃ ╚══════════════╩══════════════╩═...═╩══...═╝┃
//  ┗━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━...━━┻━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━...━━━━...━━┛

#define HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS 7
#define HBM_BWT_ENTRY_SAMPLING_INTERVAL (1 << HBM_BWT_ENTRY_SAMPLING_INTERVAL_BITS)
#define HBM_BWT_ENTRY_SAMPLING_INTERVAL_MASK (HBM_BWT_ENTRY_SAMPLING_INTERVAL - 1)

#define NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_ENTRIES 62
#define NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 (NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_ENTRIES + 2)
#define LOG2_NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 (6)
#define NUM_SMEM_BUFFER_ENTRIES_128 (NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 * SMEM_KERNEL_PIPELINE_DEPTH)

typedef ap_int<sizeof(int8_t) * 8> bwt_interval_vector_index_t;
typedef ap_uint<34> reference_index_t;
typedef ap_uint<13> local_sequence_index_t;
typedef ap_uint<sizeof(uint32_t) * 8> min_intv_t;
typedef ap_uint<NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER_BITS + ADDR_RIGHT_SHIFT_256> global_sequence_index_t;

/**
 * accelerator_bwt_interval_vector during backward extension iteration
 *                       <- current_candidate_index                            start_index     end_index
 *                                   ┇                                              ┇              ┇
 * ┏━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━┳━━━━━━┓
 * ┃ RELEASED ┃ UNEXTENDED CANDIDATES ┃ DISCARDED CANDIDATES ┃ EXTENDED CANDIDATES ┃ SMEM RESULTS ┃ FREE ┃
 * ┗━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━━━━━━━━┻━━━━━━━━━━━━━━┻━━━━━━┛
 *  ┇          ┇                                            ┇                                             ┇
 *  0   filtered_candidates_end_index       <- current_candidate_insert_index                             62
 * 
 */

typedef ap_uint<256> host_bwt_interval_vector_cacheline_t;
typedef ap_uint<128> accelerator_bwt_interval_vector_cacheline_t;

struct accelerator_bwt_interval;

host_bwt_interval_vector_cacheline_t to_host_bwt_interval_vector_cacheline(
    host_bwt_interval_vector_metadata_t metadata);
accelerator_bwt_interval_vector_cacheline_t to_accelerator_bwt_interval_vector_cacheline(
    host_bwt_interval_vector_metadata_t metadata);

host_bwt_interval_vector_cacheline_t to_host_bwt_interval_vector_cacheline(accelerator_bwt_interval interval);


template<typename RESULT_TYPE>
RESULT_TYPE to(host_bwt_interval_vector_metadata_t metadata) {
    int offset = 0;
    RESULT_TYPE ap_element;

    STORE_INTO_AP_ELEMENT_BYTES(metadata.task_index);
    STORE_INTO_AP_ELEMENT_BYTES(metadata.end_index);
    STORE_INTO_AP_ELEMENT_BYTES(metadata.is_last_task);
    STORE_INTO_AP_ELEMENT_BYTES(metadata.has_task_failed);

    return ap_element;
}

typedef ap_uint<SMEM_KERNEL_PIPELINE_LOG2_DEPTH + LOG2_NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128>
    accelerator_bwt_interval_vector_address_t;


struct smem_buffer_request_stream_element
{
    static const int width = 2 * ap_bool_t::width + accelerator_bwt_interval_vector_cacheline_t::width
        + accelerator_bwt_interval_vector_address_t::width;
    typedef ap_uint<width> cacheline_t;

    ap_bool_t write;
    ap_bool_t write_ack;
    accelerator_bwt_interval_vector_cacheline_t req_wdata;
    accelerator_bwt_interval_vector_address_t req_addr;

    smem_buffer_request_stream_element() {}
    smem_buffer_request_stream_element(cacheline_t ap_element);
    operator cacheline_t() const;
};

struct smem_buffer_response_stream_element
{
    static const int width = accelerator_bwt_interval_vector_cacheline_t::width;
    typedef ap_uint<width> cacheline_t;

    accelerator_bwt_interval_vector_cacheline_t resp_rdata;

    smem_buffer_response_stream_element() {}
    smem_buffer_response_stream_element(cacheline_t ap_element);
    operator cacheline_t() const;
};

struct smem_buffer
{
    ap_stream<smem_buffer_request_stream_element> request_stream;
    ap_stream<smem_buffer_response_stream_element> response_stream;
};
typedef smem_buffer smem_buffer_t;

struct accelerator_bwt_interval
{
    static const int width = 3 * reference_index_t::width + 2 * local_sequence_index_t::width;
    static const int interval_vector_offset = 2;
    typedef ap_uint<width> cacheline_t;

    reference_index_t x[3];
    local_sequence_index_t query_begin_position, query_end_position;  // [query_begin_position, query_end_position[

    accelerator_bwt_interval() {}
    accelerator_bwt_interval(cacheline_t ap_element);
    operator cacheline_t() const;
}; /* 16 Bytes */

struct accelerator_bwt_interval_vector_metadata_1
{
    static const int width = 128;
    static const int interval_vector_offset = 0;
    typedef ap_uint<width> cacheline_t;

    global_sequence_index_t sequence_offset;
    local_sequence_index_t start_position;
    local_sequence_index_t sequence_length;
    min_intv_t min_intv;
    bwt_interval_vector_index_t filtered_candidates_end_index;
    bwt_interval_vector_index_t current_candidate_index;
    bwt_interval_vector_index_t current_candidate_insert_index;
    bwt_interval_vector_index_t start_index;
    bwt_interval_vector_index_t end_index;
    sequence_element_t current_sequence_element;
    ap_bool_t task_has_failed;

    accelerator_bwt_interval_vector_metadata_1() {}
    accelerator_bwt_interval_vector_metadata_1(cacheline_t ap_element);
    operator cacheline_t() const;
};

struct accelerator_bwt_interval_vector_metadata_2
{
    static const int width = 128;
    static const int interval_vector_offset = 1;
    typedef ap_uint<width> cacheline_t;

    task_index_t task_index;
    ap_bool_t is_first_pass_task;
    bwt_interval_vector_index_t unflushed_intervals_end_index;
    bwt_interval_vector_index_t unscheduled_second_pass_tasks_start_index;
    local_sequence_index_t next_first_pass_task_start_position;

    accelerator_bwt_interval_vector_metadata_2() {}
    accelerator_bwt_interval_vector_metadata_2(cacheline_t ap_element);
    operator cacheline_t() const;
};

template<bool write_ack, typename PAYLOAD>
void __store(
    smem_buffer_t& smem_buffer,
    smem_kernel_pipeline_index_t pipeline_index,
    bwt_interval_vector_index_t offset,
    PAYLOAD payload) {
#pragma HLS inline
    typename PAYLOAD::cacheline_t cacheline = static_cast<typename PAYLOAD::cacheline_t>(payload);
    smem_buffer_request_stream_element request_element;
    request_element.write = true;
    request_element.write_ack = write_ack;
    request_element.req_wdata = cacheline;
    request_element.req_addr =
        (accelerator_bwt_interval_vector_address_t)NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 * pipeline_index
        + (PAYLOAD::interval_vector_offset + offset);
    smem_buffer.request_stream << request_element;
}

template<typename PAYLOAD>
void store_ack(
    smem_buffer_t& smem_buffer,
    smem_kernel_pipeline_index_t pipeline_index,
    bwt_interval_vector_index_t offset,
    PAYLOAD payload) {
#pragma HLS inline
    __store<true>(smem_buffer, pipeline_index, offset, payload);
    ap_wait();
    smem_buffer_response_stream_element response_element;
    smem_buffer.response_stream >> response_element;
}

template<typename PAYLOAD>
void store_ack(smem_buffer_t& smem_buffer, smem_kernel_pipeline_index_t pipeline_index, PAYLOAD payload) {
#pragma HLS inline
    store_ack(smem_buffer, pipeline_index, 0, payload);
}

template<typename PAYLOAD>
void store(
    smem_buffer_t& smem_buffer,
    smem_kernel_pipeline_index_t pipeline_index,
    bwt_interval_vector_index_t offset,
    PAYLOAD payload) {
#pragma HLS inline
    __store<false>(smem_buffer, pipeline_index, offset, payload);
}

template<typename PAYLOAD>
void store(smem_buffer_t& smem_buffer, smem_kernel_pipeline_index_t pipeline_index, PAYLOAD payload) {
#pragma HLS inline
    store(smem_buffer, pipeline_index, 0, payload);
}

template<typename PAYLOAD>
PAYLOAD
load(smem_buffer_t& smem_buffer, smem_kernel_pipeline_index_t pipeline_index, bwt_interval_vector_index_t offset) {
#pragma HLS inline
    smem_buffer_request_stream_element request_element;
    request_element.write = false;
    request_element.write_ack = false;
    request_element.req_wdata = 0;
    request_element.req_addr =
        (accelerator_bwt_interval_vector_address_t)NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_CACHE_LINES_128 * pipeline_index
        + (PAYLOAD::interval_vector_offset + offset);
    smem_buffer.request_stream << request_element;
    ap_wait();
    smem_buffer_response_stream_element response_element;
    smem_buffer.response_stream >> response_element;

    return PAYLOAD(response_element.resp_rdata);
}

template<typename PAYLOAD>
PAYLOAD load(smem_buffer_t& smem_buffer, smem_kernel_pipeline_index_t pipeline_index) {
#pragma HLS inline
    return load<PAYLOAD>(smem_buffer, pipeline_index, 0);
}

void ack(smem_buffer_t& smem_buffer);

struct accelerator_bwt_interval_vector
{
    accelerator_bwt_interval_vector_metadata_1 m_1;
    accelerator_bwt_interval_vector_metadata_2 m_2;
    accelerator_bwt_interval a[NUM_ACCELERATOR_BWT_INTERVAL_VECTOR_ENTRIES];
}; /* 1024 Bytes */

struct smem_forward_state
{
    static const int width = min_intv_t::width + global_sequence_index_t::width + local_sequence_index_t::width
        + 2 * bwt_interval_vector_index_t::width + sequence_section_t::width;
    typedef ap_uint<width> cacheline_t;

    smem_forward_state() {}
    smem_forward_state(
        int task_min_intv,
        global_sequence_index_t current_global_sequence_index,
        local_sequence_index_t remaining_elements_in_current_direction,
        bwt_interval_vector_index_t forward_extension_end_index,
        sequence_section_t current_sequence_section)
        : task_min_intv(task_min_intv)
        , current_global_sequence_index(current_global_sequence_index)
        , remaining_elements_in_current_direction(remaining_elements_in_current_direction)
        , forward_extension_end_index(forward_extension_end_index)
        , current_sequence_section(current_sequence_section) {}

    min_intv_t task_min_intv;
    global_sequence_index_t current_global_sequence_index;
    local_sequence_index_t remaining_elements_in_current_direction;
    bwt_interval_vector_index_t forward_extension_end_index;  // Store end_index here for quicker access
    bwt_interval_vector_index_t forward_extension_max_end_index;
    sequence_section_t current_sequence_section;

    smem_forward_state(cacheline_t ap_element);
    operator cacheline_t() const;
};
typedef struct smem_forward_state smem_forward_state_t;

struct smem_forward_extend_task
{
    static const int width = smem_kernel_pipeline_index_t::width + min_intv_t::width + global_sequence_index_t::width
        + local_sequence_index_t::width + 2 * bwt_interval_vector_index_t::width + sequence_section_t::width
        + accelerator_bwt_interval::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    min_intv_t task_min_intv;
    global_sequence_index_t current_global_sequence_index;
    local_sequence_index_t remaining_elements_in_current_direction;
    bwt_interval_vector_index_t forward_extension_end_index;
    bwt_interval_vector_index_t forward_extension_max_end_index;
    sequence_section_t current_sequence_section;
    accelerator_bwt_interval::cacheline_t interval_cacheline;

    smem_forward_extend_task() {}
    smem_forward_extend_task(cacheline_t ap_element);
    operator cacheline_t() const;
};

struct smem_backward_state
{
    global_sequence_index_t current_global_sequence_index;
    local_sequence_index_t remaining_elements_in_current_direction;
    sequence_section_t current_sequence_section;
};
typedef struct smem_backward_state smem_backward_state_t;

struct smem_backward_extend_task
{
    static const int width =
        smem_kernel_pipeline_index_t::width + bwt_interval_vector_index_t::width + ap_bool_t::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    bwt_interval_vector_index_t end_index;
    ap_bool_t forward_extension_has_failed;

    smem_backward_extend_task() {}
    smem_backward_extend_task(cacheline_t ap_element);
    operator cacheline_t() const;
};

struct smem_extend_remaining_candidates_task
{
    static const int width = smem_kernel_pipeline_index_t::width + 3 * bwt_interval_vector_index_t::width
        + sequence_element_t::width + reference_index_t::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    bwt_interval_vector_index_t current_candidate_index;
    bwt_interval_vector_index_t current_candidate_insert_index;
    bwt_interval_vector_index_t filtered_candidates_end_index;
    sequence_element_t current_sequence_element;
    reference_index_t last_inserted_candidate_interval_size;

    smem_extend_remaining_candidates_task() {}
    smem_extend_remaining_candidates_task(cacheline_t ap_element);
    operator cacheline_t() const;
};


struct smem_step3_request_scheduler_task
{
    static const int width = smem_kernel_pipeline_index_t::width + bwt_interval_vector_index_t::width
        + sequence_element_t::width + ap_bool_t::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    bwt_interval_vector_index_t current_candidate_insert_index;
    sequence_element_t current_sequence_element;
    ap_bool_t send_to_bwt_extend_stream;

    smem_step3_request_scheduler_task() {}
    smem_step3_request_scheduler_task(cacheline_t ap_element);
    operator cacheline_t() const;
};

struct smem_new_backward_iteration_task
{
    static const int width = smem_kernel_pipeline_index_t::width + bwt_interval_vector_index_t::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    bwt_interval_vector_index_t current_candidate_insert_index;

    smem_new_backward_iteration_task() {}
    smem_new_backward_iteration_task(cacheline_t ap_element);
    operator cacheline_t() const;
};

struct bwt_extend_stream_element
{
    static const int width = smem_kernel_pipeline_index_t::width + sequence_element_t::width + 2 * ap_bool_t::width
        + accelerator_bwt_interval::width;
    typedef ap_uint<width> cacheline_t;

    smem_kernel_pipeline_index_t pipeline_index;
    sequence_element_t current_sequence_element;
    ap_bool_t has_interval_size_changed;
    ap_bool_t is_backward_extension;
    accelerator_bwt_interval interval;

    bwt_extend_stream_element(){};
    bwt_extend_stream_element(
        smem_kernel_pipeline_index_t pipeline_index,
        sequence_element_t current_sequence_element,
        bool has_interval_size_changed,
        bool is_backward_extension,
        accelerator_bwt_interval interval)
        : pipeline_index(pipeline_index)
        , current_sequence_element(current_sequence_element)
        , has_interval_size_changed(has_interval_size_changed)
        , is_backward_extension(is_backward_extension)
        , interval(interval) {}

    bwt_extend_stream_element(cacheline_t ap_element);

    operator cacheline_t() const;
};

#endif  //ACCELERATED_BWA_MEM_HLS_BWT_DEFINITIONS_H
