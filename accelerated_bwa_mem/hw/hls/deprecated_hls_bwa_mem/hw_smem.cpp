#include "hw_smem.h"

#include <hls_stream.h>

#include "hls_stream_processing.h"
#include "hw_dynamic_memory.h"

#define accelerator_bwt_set_intv(bwt_aux, c, ik) \
    ((ik).x[0] = bwt_aux.L2[(int)(c)] + 1, \
     (ik).x[2] = bwt_aux.L2[(int)(c) + 1] - bwt_aux.L2[(int)(c)], \
     (ik).x[1] = bwt_aux.L2[3 - (c)] + 1, \
     (ik).info = 0)

#define get_sequence_element(query, index) \
    SLICE(query, index& SEQUENCE_ELEMENT_BUFFER_OFFSET_MASK, SEQUENCE_ELEMENT_SIZE_BITS)

void advance_sequence_forward(
    sequence_buffer_t& sequence_buffer,
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream,
    global_sequence_index_t global_sequence_index) {
    if ((global_sequence_index & SEQUENCE_ELEMENT_BUFFER_OFFSET_MASK) == 0) {
        bidirectional_stream_access<global_sequence_index_t, sequence_buffer_t>(
            req_sequence_stream, ret_sequence_stream, global_sequence_index, sequence_buffer);
    }
}

void advance_sequence_backward(
    sequence_buffer_t sequence_buffer,
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream,
    global_sequence_index_t global_sequence_index) {
    if ((global_sequence_index ^ SEQUENCE_ELEMENT_BUFFER_OFFSET_MASK) == 0) {
        bidirectional_stream_access<global_sequence_index_t, sequence_buffer_t>(
            req_sequence_stream, ret_sequence_stream, global_sequence_index, sequence_buffer);
    }
}

// TODO-TIL: Implement bounds check or vector extension!
#define push_bwt_interval(bwt_interval_vector, bwt_interval) \
    (bwt_interval_vector).a[(bwt_interval_vector).n++] = bwt_interval
#define back(bwt_interval) bwt_interval->a[smem_candidates->n - 1]

void accelerator_smem_forward(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    const BWT_Aux bwt_aux,
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream,
    Task task,
    bwt_interval_vector_t* smem_candidates) {
    global_sequence_index_t current_global_sequence_index = task.sequence_offset + task.start_position;

    sequence_buffer_t current_sequence_section;
    bidirectional_stream_access<global_sequence_index_t, sequence_buffer_t>(
        req_sequence_stream, ret_sequence_stream, current_global_sequence_index, current_sequence_section);

    bwt_interval_t ik, ok;
    accelerator_bwt_set_intv(
        bwt_aux, get_sequence_element(current_sequence_section, current_global_sequence_index), ik);
    ik.info = task.start_position + 1;

    current_global_sequence_index++;
    sequence_element_t current_sequence_element;
    local_sequence_index_t current_local_sequence_index = task.start_position + 1;
    for (; current_local_sequence_index < task.sequence_length;
         current_global_sequence_index++, current_local_sequence_index++) {
        advance_sequence_forward(
            current_sequence_section, req_sequence_stream, ret_sequence_stream, current_global_sequence_index);
        current_sequence_element = get_sequence_element(current_sequence_section, current_global_sequence_index);
        if (current_sequence_element < 4) {  // an A/C/G/T base
            ok = accelerator_bwt_extend_forward(
                req_bwt_position_stream, ret_bwt_entry_stream, bwt_aux, ik, current_sequence_element);
            if (ok.x[2] != ik.x[2]) {  // change of the interval size
                push_bwt_interval(*smem_candidates, ik);
                if (ok.x[2] < task.min_intv) break;  // the interval size is too small to be extended further
            }
            ik = ok;
            ik.info = current_local_sequence_index + 1;
        } else {  // an ambiguous base
            push_bwt_interval(*smem_candidates, ik);
            break;  // always terminate extension at an ambiguous base; in this case, i<len always stands
        }
    }

    if (current_local_sequence_index == task.sequence_length) push_bwt_interval(*smem_candidates, ik);
}

void accelerator_smem_backward(
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    hls::stream<SMEM_Result>& smem_result_stream,
    const BWT_Aux bwt_aux,
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream,
    Task* task,
    bwt_interval_vector_t* smem_candidates) {
    global_sequence_index_t current_global_sequence_index = task->sequence_offset + task->start_position - 1;
    local_sequence_index_t filtered_candidates_end_index = 0;
    bwt_interval_t ik, ok;

    int current_local_sequence_index = task->start_position - 1, current_insert_index, current_candidate_index;
    sequence_buffer_t current_sequence_section;
    if (current_local_sequence_index >= 0) {
        bidirectional_stream_access<global_sequence_index_t, sequence_buffer_t>(
            req_sequence_stream, ret_sequence_stream, current_global_sequence_index, current_sequence_section);
    }

    sequence_element_t current_sequence_element;
    for (; current_local_sequence_index != -1 && filtered_candidates_end_index < smem_candidates->n;
         current_global_sequence_index--, current_local_sequence_index--) {
        advance_sequence_backward(
            current_sequence_section, req_sequence_stream, ret_sequence_stream, current_global_sequence_index);

        current_sequence_element = get_sequence_element(current_sequence_section, current_global_sequence_index);
        current_candidate_index = smem_candidates->n - 1;
        current_insert_index = smem_candidates->n - 1;

        ik = back(smem_candidates);

        bool isAmbiguousBase = current_sequence_element >= 4;
        if (isAmbiguousBase) {
            // When reaching an ambiguous base, store the longest remaining candidate as match and return
            ik.info |= (uint64_t)(current_local_sequence_index + 1) << 32;
            push_smem_result(smem_result_stream, ik);
            return;
        }
        ok = accelerator_bwt_extend_backward(
            req_bwt_position_stream, ret_bwt_entry_stream, bwt_aux, ik, current_sequence_element);

        // Since SMEM candidates are ordered decreasingly, once an interval was above min_intv, it stays above.
        // Therefore, hasReachedMinIntervalSize is either true for the first candidate (and potentially following ones) or never.
        // Once this value was false, it never becomes true.
        bool hasReachedMinIntervalSize = ok.x[2] < task->min_intv;
        if (hasReachedMinIntervalSize) {
            ik.info |= (uint64_t)(current_local_sequence_index + 1) << 32;
            push_smem_result(smem_result_stream, ik);
            current_candidate_index--;

            // Discard all candidates with hasReachedMinIntervalSize that are shorter than the match we pushed out
            // These are already contained in the match we pushed out.
            for (; current_candidate_index >= filtered_candidates_end_index; current_candidate_index--) {
                ik = smem_candidates->a[current_candidate_index];
                ok = accelerator_bwt_extend_backward(
                    req_bwt_position_stream, ret_bwt_entry_stream, bwt_aux, ik, current_sequence_element);
                hasReachedMinIntervalSize = ok.x[2] < task->min_intv;
                if (!hasReachedMinIntervalSize) break;
            }
        }

        while (current_candidate_index >= filtered_candidates_end_index) {
            smem_candidates->a[current_insert_index--] = ok;
            current_candidate_index--;

            // Discard all candidates contained in longer candidate
            bool isContainedInLongerCandidate = true;
            for (; current_candidate_index >= filtered_candidates_end_index; current_candidate_index--) {
                ik = smem_candidates->a[current_candidate_index];
                ok = accelerator_bwt_extend_backward(
                    req_bwt_position_stream, ret_bwt_entry_stream, bwt_aux, ik, current_sequence_element);
                isContainedInLongerCandidate = ok.x[2] == smem_candidates->a[current_insert_index + 1].x[2];
                if (!isContainedInLongerCandidate) break;
            }
        }

        filtered_candidates_end_index = current_insert_index + 1;
    }

    // If reaching beginning of query sequence push longest remaining interval out
    if (filtered_candidates_end_index < smem_candidates->n) push_smem_result(smem_result_stream, back(smem_candidates));
}

void accelerator_bwt_smem(
    const BWT_Aux bwt_aux,
    Task task,
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream,
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    hls::stream<SMEM_Result>& smem_result_stream) {
    bwt_interval_vector_t smem_candidates;
    smem_candidates.n = 0;
    smem_candidates.x = 0;

    reset_smem_results(smem_result_stream, task.smems, task.start_position + 1);

    task.min_intv = task.min_intv < 1 ? 1 : task.min_intv;

    global_sequence_index_t current_global_sequence_index = task.sequence_offset + task.start_position;

    sequence_buffer_t current_sequence_section;
    bidirectional_stream_access<global_sequence_index_t, sequence_buffer_t>(
        req_sequence_stream, ret_sequence_stream, current_global_sequence_index, current_sequence_section);

    // ambiguous base
    if (get_sequence_element(current_sequence_section, current_global_sequence_index) > 3) return;

    accelerator_smem_forward(
        req_bwt_position_stream,
        ret_bwt_entry_stream,
        bwt_aux,
        req_sequence_stream,
        ret_sequence_stream,
        task,
        &smem_candidates);
    accelerator_smem_backward(
        req_bwt_position_stream,
        ret_bwt_entry_stream,
        smem_result_stream,
        bwt_aux,
        req_sequence_stream,
        ret_sequence_stream,
        &task,
        &smem_candidates);

    finalize_smem_results(smem_result_stream, task.task_index);
    return;
}