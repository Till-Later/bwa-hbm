#ifndef ACCELERATED_BWA_MEM_HLS_TASK_H
#define ACCELERATED_BWA_MEM_HLS_TASK_H

#include "action_aligner.h"
#include "hls_ap_utils.h"
#include "hls_bwt_definitions.h"
#include "hls_definitions.h"
#include "hls_sequence_definitions.h"
#include "hls_snap_1024.H"

struct task
{
    static const int width =
        8 * sizeof(task_index_t) + global_sequence_index_t::width + local_sequence_index_t::width;
    typedef ap_uint<width> cacheline_t;

    task(){};

    task(cacheline_t ap_element);
    operator cacheline_t() const;

    task_index_t task_index;
    global_sequence_index_t sequence_offset;
    local_sequence_index_t sequence_length;
};

struct follow_up_task
{
    static const int width = smem_kernel_pipeline_index_t::width + global_sequence_index_t::width
        + 2 * local_sequence_index_t::width + min_intv_t::width + 2 * bwt_interval_vector_index_t::width;
    typedef ap_uint<width> cacheline_t;

    follow_up_task(){};

    follow_up_task(cacheline_t ap_element);
    operator cacheline_t() const;

    smem_kernel_pipeline_index_t pipeline_index;
    global_sequence_index_t sequence_offset;
    local_sequence_index_t start_position;
    local_sequence_index_t sequence_length;
    min_intv_t min_intv;
    bwt_interval_vector_index_t min_start_index;
    bwt_interval_vector_index_t max_end_index;
};

#endif  //ACCELERATED_BWA_MEM_HLS_TASK_H
