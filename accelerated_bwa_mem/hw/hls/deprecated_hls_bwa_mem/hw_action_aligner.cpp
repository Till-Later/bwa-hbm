/*
 * Copyright 2019 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/* SNAP HLS_MEMCOPY EXAMPLE */

#include "hw_action_aligner.h"

#include <hls_stream.h>
#include <iostream>  // For testbench
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include "ap_int.h"
#include "hls_stream_processing.h"
#include "hw_bwt.h"
#include "hw_definitions.h"
#include "hw_hbm.h"
#include "hw_smem.h"
#include "testbench.h"

//======================== IMPORTANT
//================================================//
// The following number defines the number of AXI interfaces for the HBM that is
// used in the HLS code below.
//    (see #pragma HLS INTERFACE m_axi port=d_hbm_pxx bundle=card_hbm_pxx)
// It is used to check the compatibility with the number of AXI interfaces in
// the wrapper (set in Kconfig menu) This number is written in the binary image
// so that the "oc_maint" command displays the number of implemented HBM.
// Minimum is 1 - Maximum is 32
//          NOTE : for VU3P chip it is not recommended to use more than 12, as
//                 timing closure is too difficult otherwise.
// You can define this number to a lower number than the number of AXI
// interfaces coded in this HLS code BUT the application shouldn't use more
// interfaces than the number you have defined in Kconfig menu. (extra
// interfaces not connected will be removed if not connected to the wrapper)

#define HBM_AXI_IF_NB 32

//===================================================================================//

task_index_t get_host_next_task_index(snap_membus_1024_t* din_gmem, uint64_t runtime_status_control_addr) {
    snap_membus_1024_t buffer1024;
    __builtin_memcpy(
        &buffer1024, din_gmem + (runtime_status_control_addr >> ADDR_RIGHT_SHIFT_1024), sizeof(snap_membus_1024_t));
    return SLICE(buffer1024, 0, sizeof(task_index_t) * 8);
}

void set_accelerator_processed_index(
    snap_membus_1024_t* dout_gmem,
    uint64_t runtime_status_control_addr,
    task_index_t index) {
    snap_membus_1024_t buffer1024 = 0;
    SLICE(buffer1024, 0, sizeof(task_index_t) * 8) = index;
    *(dout_gmem + ((runtime_status_control_addr + sizeof(snap_membus_1024_t)) >> ADDR_RIGHT_SHIFT_1024)) = buffer1024;
    //    __builtin_memcpy(
    //        dout_gmem + ((runtime_status_control_addr + sizeof(snap_membus_1024_t)) >> ADDR_RIGHT_SHIFT_1024),
    //        &buffer1024,
    //        sizeof(snap_membus_1024_t));
}

void sequence_manager(
    sequence_buffer_t sequences[MAX_NB_OF_WORDS_READ_1024 * 16],
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_write_section_t>& ret_sequence_stream) {
    global_sequence_index_t global_sequence_index;
    sequence_write_section_t sequence_section;
    while (true) {
        req_sequence_stream.read(global_sequence_index);
        if (global_sequence_index == STREAM_TERMINATION<global_sequence_index_t>::SIGNAL) {
            // ret_sequence_stream.write(STREAM_TERMINATION<sequence_buffer_t>::SIGNAL);
            return;
        }
        sequence_section = sequences[global_sequence_index >> ADDR_RIGHT_SHIFT_1024];
        ret_sequence_stream.write(sequence_section);
    }
}

void smem_task_scheduler(
    action_reg* act_reg,
    hls::stream<snapu64_t>& req_task_queue_stream,
    hls::stream<snap_membus_1024_t>& ret_task_queue_stream,
    hls::stream<Task>& smem_task_stream,
    hls::stream<bool>& req_host_next_task_index_stream,
    hls::stream<task_index_t>& ret_host_next_task_index_stream) {
    // Each 1024 bit line fits 4 task queue entries
    // TODO-TILL: Fix magic value >> 2
    snap_membus_1024_t task_queue[SMEM_TASK_QUEUE_NUM_ENTRIES >> 2];

    task_index_t host_next_task_index = 0;
    task_index_t accelerator_processed_index = 0;
    task_queue_index_t num_unprocessed_tasks, task_queue_entry_position;

    const snapu64_t task_queue_host_address = act_reg->Data.smem_task_queue_addr;

    while (true) {
        bidirectional_stream_access<bool, task_index_t>(
            req_host_next_task_index_stream, ret_host_next_task_index_stream, true, host_next_task_index);

        if (host_next_task_index == accelerator_processed_index) continue;

        task_queue_entry_position = accelerator_processed_index & SMEM_TASK_QUEUE_ENTRY_MASK;
        num_unprocessed_tasks =
            MIN(((task_queue_index_t)host_next_task_index - accelerator_processed_index),
                (SMEM_TASK_QUEUE_NUM_ENTRIES - task_queue_entry_position));
        num_unprocessed_tasks = MIN(num_unprocessed_tasks, (task_queue_index_t)4);

        snap_membus_1024_t task_queue_section;
        bidirectional_stream_access<snapu64_t, snap_membus_1024_t>(
            req_task_queue_stream,
            ret_task_queue_stream,
            ((task_queue_host_address + (task_queue_entry_position << TASK_QUEUE_ENTRY_SIZE_BITS))
             >> ADDR_RIGHT_SHIFT_1024),
            task_queue_section);

        task_queue[task_queue_entry_position >> 2] = task_queue_section;

        while (num_unprocessed_tasks) {
            snap_membus_1024_t current_tasks = task_queue[task_queue_entry_position >> 2];
            for (int j = accelerator_processed_index & 0x3; j < 4 && num_unprocessed_tasks;
                 j++, num_unprocessed_tasks--, accelerator_processed_index++, task_queue_entry_position++) {
                Task task(
                    accelerator_processed_index, (snap_membus_256_t)SLICE(current_tasks, j, sizeof(smem_task_t) * 8));
                smem_task_stream << task;

                if (task.sequence_offset == STREAM_TERMINATION<global_sequence_index_t>::SIGNAL) {
                    return;
                }
            }
        }
    }
}

void smem_task_processor(
    action_reg* act_reg,
    hls::stream<Task>& smem_task_stream,
    hls::stream<reference_index_t>& req_bwt_position_stream,
    hls::stream<hbm_bwt_entry_t>& ret_bwt_entry_stream,
    hls::stream<SMEM_Result>& smem_result_stream,
    hls::stream<global_sequence_index_t>& req_sequence_stream,
    hls::stream<sequence_buffer_t>& ret_sequence_stream) {
    BWT_Aux bwt_aux;
    bwt_aux.primary = act_reg->Data.bwt_primary;
    bwt_aux.L2[0] = act_reg->Data.bwt_L2[0];
    bwt_aux.L2[1] = act_reg->Data.bwt_L2[1];
    bwt_aux.L2[2] = act_reg->Data.bwt_L2[2];
    bwt_aux.L2[3] = act_reg->Data.bwt_L2[3];
    bwt_aux.L2[4] = act_reg->Data.bwt_L2[4];

    Task task;
    while (true) {
        smem_task_stream >> task;

        if (task == STREAM_TERMINATION<Task>::SIGNAL) {
            req_bwt_position_stream.write(STREAM_TERMINATION<reference_index_t>::SIGNAL);
            smem_result_stream.write(STREAM_TERMINATION<SMEM_Result>::SIGNAL);
            return;
        }

        accelerator_bwt_smem(
            bwt_aux,
            task,
            req_sequence_stream,
            ret_sequence_stream,
            req_bwt_position_stream,
            ret_bwt_entry_stream,
            smem_result_stream);
    }
}

template<int N>
void smem_task_finalizer(
    action_reg* act_reg,
    hls::stream<task_index_t>& accelerator_processed_index_stream,
    hls::stream<task_index_t> smem_task_completion_streams[N]) {
    task_index_t accelerator_processed_index = 0, old_accelerator_processed_index;
    int current_input_stream = 0;
    bool is_stream_terminated[N] = {false};
    int num_terminated_streams = 0;

    while (true) {
        do {
            old_accelerator_processed_index = accelerator_processed_index;
            smem_task_completion_streams[current_input_stream] >> accelerator_processed_index;

            if (accelerator_processed_index == STREAM_TERMINATION<task_index_t>::SIGNAL) {
                is_stream_terminated[current_input_stream] = true;
                num_terminated_streams++;
                accelerator_processed_index = old_accelerator_processed_index;
                if (num_terminated_streams == N) {
                    accelerator_processed_index_stream << STREAM_TERMINATION<task_index_t>::SIGNAL;
                    return;
                }
            }

            current_input_stream = (current_input_stream + 1) % N;
        } while (!smem_task_completion_streams[current_input_stream].empty());

        accelerator_processed_index_stream << accelerator_processed_index;
    }
}


void host_mem_manager(
    action_reg* act_reg,
    snap_membus_1024_t* din_gmem,
    snap_membus_1024_t* dout_gmem,
    hls::stream<snapu64_t>& req_task_queue_stream,
    hls::stream<snap_membus_1024_t>& ret_task_queue_stream,
    hls::stream<bool>& req_host_next_task_index_stream,
    hls::stream<task_index_t>& ret_host_next_task_index_stream,
    hls::stream<snapu64_t>& req_free_list_section_stream,
    hls::stream<snap_membus_1024_t>& ret_free_list_section_stream,
    hls::stream<task_index_t>& accelerator_processed_index_stream,
    hls::stream<SMEM_Result_Buffer>& result_buffer_stream) {
    // din_accesses: (READ)
    // - smem_task_scheduler: (host_next_task_index, 128B), (task_queue, 128B)
    // - overflow_smem_manager: (free_list_section, 128B)
    // dout_accesses: (WRITE)
    // - smem_task_finalizer: (accelerator_processed_index, 128B)
    // - smem_manager: (host_result_buffer, 1KB)

    snapu64_t req_task_queue_element;
    snap_membus_1024_t ret_task_queue_element;

    bool req_host_next_task_index_element;
    task_index_t ret_host_next_task_index_element;

    snapu64_t req_free_list_section_element;
    snap_membus_1024_t ret_free_list_section_element;

    task_index_t accelerator_processed_index_element;

    SMEM_Result_Buffer result_buffer_element;
    while (true) {
        if (result_buffer_stream.read_nb(result_buffer_element)) {
            // Prioritize result_buffer_stream to prevent that accelerator_processed_index is updated too early
            // TODO-TILL: Is this really safe? It is not very elegant either.
            snap_membus_1024_t buffer1024[HOST_MEMORY_DATA_WORDS_PER_BWT_INTERVAL_VECTOR] = {0};
            bwt_interval_vector_to_membus(result_buffer_element.local_result_buffer, buffer1024);
            __builtin_memcpy(
                dout_gmem + result_buffer_element.host_result_buffer, buffer1024, sizeof(bwt_interval_vector_t));

            continue;
        }

        if (req_free_list_section_stream.read_nb(req_free_list_section_element)) {
            __builtin_memcpy(
                &ret_free_list_section_element, din_gmem + req_free_list_section_element, sizeof(snap_membus_1024_t));
            ret_free_list_section_stream << ret_free_list_section_element;
            continue;
        }

        if (req_task_queue_stream.read_nb(req_task_queue_element)) {
            __builtin_memcpy(
                &ret_task_queue_element,
                (snap_membus_1024_t*)din_gmem + req_task_queue_element,
                sizeof(snap_membus_1024_t));
            ret_task_queue_stream << ret_task_queue_element;
            continue;
        }

        if (req_host_next_task_index_stream.read_nb(req_host_next_task_index_element)) {
            ret_host_next_task_index_stream
                << get_host_next_task_index(din_gmem, act_reg->Data.runtime_status_control_addr);
            continue;
        }

        if (accelerator_processed_index_stream.read_nb(accelerator_processed_index_element)) {
            if (accelerator_processed_index_element == STREAM_TERMINATION<task_index_t>::SIGNAL) {
                return;
            }
            set_accelerator_processed_index(
                dout_gmem, act_reg->Data.runtime_status_control_addr, accelerator_processed_index_element);
            continue;
        }
    }
}

template<int N>
void run_smem_task_processors(
    action_reg* act_reg,
    hls::stream<Task> smem_task_streams[N],
    hls::stream<reference_index_t> req_bwt_position_streams[N],
    hls::stream<hbm_bwt_entry_t> ret_bwt_entry_streams[N],
    hls::stream<SMEM_Result> smem_result_streams[N],
    hls::stream<global_sequence_index_t> req_sequence_streams[N],
    hls::stream<sequence_buffer_t> ret_sequence_streams[N]) {
    for (int i = 0; i < N; i++) {
#pragma HLS unroll
        smem_task_processor(
            act_reg,
            smem_task_streams[i],
            req_bwt_position_streams[i],
            ret_bwt_entry_streams[i],
            smem_result_streams[i],
            req_sequence_streams[i],
            ret_sequence_streams[i]);
    }
}

template<int N>
void run_local_smem_managers(
    hls::stream<bool> req_overflow_buffer_streams[N],
    hls::stream<uint32_t> ret_overflow_buffer_streams[N],
    hls::stream<SMEM_Result_Buffer> result_buffer_streams[N],
    hls::stream<SMEM_Result> smem_result_streams[N],
    const snapu64_t overflow_buffer_start_address,
    hls::stream<task_index_t> smem_task_completion_streams[N]) {
    for (int i = 0; i < N; i++) {
#pragma HLS unroll
        local_smem_manager(
            req_overflow_buffer_streams[i],
            ret_overflow_buffer_streams[i],
            result_buffer_streams[i],
            smem_result_streams[i],
            overflow_buffer_start_address,
            smem_task_completion_streams[i]);
    }
}

void run_smem_kernel(
    action_reg* act_reg,
    snap_membus_1024_t* din_gmem,
    snap_membus_1024_t* dout_gmem,
    const HBM hbm,
    sequence_buffer_t sequences[MAX_NB_OF_WORDS_READ_1024 * 16]) {
#pragma HLS dataflow
#pragma HLS inline off

    const int N = 1;
    const snapu64_t free_list_start_address = act_reg->Data.smem_results_overflow_addr;
    const snapu64_t overflow_buffer_start_address =
        (act_reg->Data.smem_results_overflow_addr + (sizeof(uint32_t) * SMEM_OVERFLOW_BUFFER_NUM_ENTRIES));

    hls::stream<reference_index_t> req_bwt_position_stream;
#pragma HLS STREAM depth = N variable = req_bwt_position_stream
    hls::stream<hbm_bwt_entry_t> ret_bwt_entry_stream;
#pragma HLS STREAM depth = N variable = ret_bwt_entry_stream
    hls::stream<reference_index_t> req_bwt_position_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = req_bwt_position_streams
    hls::stream<hbm_bwt_entry_t> ret_bwt_entry_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = ret_bwt_entry_streams

    hls::stream<SMEM_Result> smem_result_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = smem_result_streams

    hls::stream<bool> req_overflow_buffer_stream;
#pragma HLS STREAM depth = N variable = req_overflow_buffer_stream
    hls::stream<uint32_t> ret_overflow_buffer_stream;
#pragma HLS STREAM depth = N variable = ret_overflow_buffer_stream
    hls::stream<bool> req_overflow_buffer_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = req_overflow_buffer_streams
    hls::stream<uint32_t> ret_overflow_buffer_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = ret_overflow_buffer_streams

    hls::stream<global_sequence_index_t> req_sequence_stream;
#pragma HLS STREAM depth = N variable = req_sequence_stream
    hls::stream<sequence_buffer_t> ret_sequence_stream;
#pragma HLS STREAM depth = N variable = ret_sequence_stream
    hls::stream<global_sequence_index_t> req_sequence_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = req_sequence_streams
    hls::stream<sequence_buffer_t> ret_sequence_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = ret_sequence_streams

    hls::stream<Task> smem_task_stream;
#pragma HLS STREAM depth = N variable = smem_task_stream
    hls::stream<Task> smem_task_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = smem_task_streams

    hls::stream<task_index_t> smem_task_completion_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = smem_task_completion_streams

    // Host Mem Access streams
    hls::stream<snapu64_t> req_task_queue_stream;
#pragma HLS STREAM depth = N variable = req_task_queue_stream
    hls::stream<snap_membus_1024_t> ret_task_queue_stream;
#pragma HLS STREAM depth = N variable = ret_task_queue_stream
    hls::stream<bool> req_host_next_task_index_stream;
#pragma HLS STREAM depth = N variable = req_host_next_task_index_stream
    hls::stream<task_index_t> ret_host_next_task_index_stream;
#pragma HLS STREAM depth = N variable = ret_host_next_task_index_stream
    hls::stream<snapu64_t> req_free_list_section_stream;
#pragma HLS STREAM depth = N variable = req_free_list_section_stream
    hls::stream<snap_membus_1024_t> ret_free_list_section_stream;
#pragma HLS STREAM depth = N variable = ret_free_list_section_stream
    hls::stream<task_index_t> accelerator_processed_index_stream;
#pragma HLS STREAM depth = N variable = accelerator_processed_index_stream
    hls::stream<SMEM_Result_Buffer> result_buffer_stream;
#pragma HLS STREAM depth = N variable = result_buffer_stream
    hls::stream<SMEM_Result_Buffer> result_buffer_streams[NUM_SMEM_KERNELS];
#pragma HLS STREAM depth = N variable = result_buffer_streams

    // Arbiter
//    bidirectional_arbiter_N_to_1<bool, uint32_t, NUM_SMEM_KERNELS>(
//        req_overflow_buffer_streams,
//        ret_overflow_buffer_streams,
//        req_overflow_buffer_stream,
//        ret_overflow_buffer_stream);
//    bidirectional_arbiter_N_to_1<global_sequence_index_t, sequence_buffer_t, NUM_SMEM_KERNELS>(
//        req_sequence_streams, ret_sequence_streams, req_sequence_stream, ret_sequence_stream);
//    arbiter_1_to_N<Task, NUM_SMEM_KERNELS, true>(smem_task_stream, smem_task_streams);
//    arbiter_N_to_1<SMEM_Result_Buffer, NUM_SMEM_KERNELS, false>(result_buffer_streams, result_buffer_stream);
//    bidirectional_arbiter_N_to_1<reference_index_t, hbm_bwt_entry_t, NUM_SMEM_KERNELS>(
//        req_bwt_position_streams, ret_bwt_entry_streams, req_bwt_position_stream, ret_bwt_entry_stream);

    // Structural components
//    smem_task_scheduler(
//        act_reg,
//        req_task_queue_stream,
//        ret_task_queue_stream,
//        smem_task_stream,
//        req_host_next_task_index_stream,
//        ret_host_next_task_index_stream);

//    run_smem_task_processors<NUM_SMEM_KERNELS>(
//        act_reg,
//        smem_task_streams,
//        req_bwt_position_streams,
//        ret_bwt_entry_streams,
//        smem_result_streams,
//        req_sequence_streams,
//        ret_sequence_streams);

//    overflow_smem_manager(
//        req_free_list_section_stream,
//        ret_free_list_section_stream,
//        free_list_start_address,
//        req_overflow_buffer_stream,
//        ret_overflow_buffer_stream);

//    run_local_smem_managers<NUM_SMEM_KERNELS>(
//        req_overflow_buffer_streams,
//        ret_overflow_buffer_streams,
//        result_buffer_streams,
//        smem_result_streams,
//        overflow_buffer_start_address,
//        smem_task_completion_streams);

//    sequence_manager(sequences, req_sequence_stream, ret_sequence_stream);

//    bwt_request_processor(hbm, req_bwt_position_stream, ret_bwt_entry_stream);

//    smem_task_finalizer<NUM_SMEM_KERNELS>(act_reg, accelerator_processed_index_stream, smem_task_completion_streams);

//    host_mem_manager(
//        act_reg,
//        din_gmem,
//        dout_gmem,
//        req_task_queue_stream,
//        ret_task_queue_stream,
//        req_host_next_task_index_stream,
//        ret_host_next_task_index_stream,
//        req_free_list_section_stream,
//        ret_free_list_section_stream,
//        accelerator_processed_index_stream,
//        result_buffer_stream);

    return;
}

//----------------------------------------------------------------------
//---- MAIN PROGRAM ----------------------------------------------------
//----------------------------------------------------------------------
static void process_action(
    snap_membus_1024_t* din_gmem,
    snap_membus_1024_t* dout_gmem,
    snap_membus_256_t* d_hbm_p0,
    snap_membus_256_t* d_hbm_p1,
    snap_membus_256_t* d_hbm_p2,
    snap_membus_256_t* d_hbm_p3,
    snap_membus_256_t* d_hbm_p4,
    snap_membus_256_t* d_hbm_p5,
    snap_membus_256_t* d_hbm_p6,
    snap_membus_256_t* d_hbm_p7,
    snap_membus_256_t* d_hbm_p8,
    snap_membus_256_t* d_hbm_p9,
    snap_membus_256_t* d_hbm_p10,
    snap_membus_256_t* d_hbm_p11,
    snap_membus_256_t* d_hbm_p12,
    snap_membus_256_t* d_hbm_p13,
    snap_membus_256_t* d_hbm_p14,
    snap_membus_256_t* d_hbm_p15,
    snap_membus_256_t* d_hbm_p16,
    snap_membus_256_t* d_hbm_p17,
    snap_membus_256_t* d_hbm_p18,
    snap_membus_256_t* d_hbm_p19,
    snap_membus_256_t* d_hbm_p20,
    snap_membus_256_t* d_hbm_p21,
    snap_membus_256_t* d_hbm_p22,
    snap_membus_256_t* d_hbm_p23,
    snap_membus_256_t* d_hbm_p24,
    snap_membus_256_t* d_hbm_p25,
    snap_membus_256_t* d_hbm_p26,
    snap_membus_256_t* d_hbm_p27,
    snap_membus_256_t* d_hbm_p28,
    snap_membus_256_t* d_hbm_p29,
    snap_membus_256_t* d_hbm_p30,
    snap_membus_256_t* d_hbm_p31,
    action_reg* act_reg) {
    sequence_buffer_t sequences[MAX_NB_OF_WORDS_READ_1024 * 16];
#pragma HLS RESOURCE variable = sequences core = XPM_MEMORY uram

    const HBM hbm = {
        d_hbm_p0,  d_hbm_p1,  d_hbm_p2,  d_hbm_p3,  d_hbm_p4,  d_hbm_p5,  d_hbm_p6,  d_hbm_p7,
        d_hbm_p8,  d_hbm_p9,  d_hbm_p10, d_hbm_p11, d_hbm_p12, d_hbm_p13, d_hbm_p14, d_hbm_p15,
        d_hbm_p16, d_hbm_p17, d_hbm_p18, d_hbm_p19, d_hbm_p20, d_hbm_p21, d_hbm_p22, d_hbm_p23,
        d_hbm_p24, d_hbm_p25, d_hbm_p26, d_hbm_p27, d_hbm_p28, d_hbm_p29, d_hbm_p30, d_hbm_p31,
    };

    //init_bwt(act_reg, din_gmem, hbm);
    //    init_sequences(act_reg, din_gmem, sequences);

    run_smem_kernel(act_reg, din_gmem, dout_gmem, hbm, sequences);

    act_reg->Control.Retc = SNAP_RETC_SUCCESS;  // SNAP_RETC_FAILURE
    return;
}

//--- TOP LEVEL MODULE -------------------------------------------------
// snap_membus_1024_t and snap_membus_256_t are defined in
// actions/include/hls_snap_1024.H
void hls_action(
    snap_membus_1024_t* din_gmem,
    snap_membus_1024_t* dout_gmem,
    snap_membus_256_t* d_hbm_p0,
    snap_membus_256_t* d_hbm_p1,
    snap_membus_256_t* d_hbm_p2,
    snap_membus_256_t* d_hbm_p3,
    snap_membus_256_t* d_hbm_p4,
    snap_membus_256_t* d_hbm_p5,
    snap_membus_256_t* d_hbm_p6,
    snap_membus_256_t* d_hbm_p7,
    snap_membus_256_t* d_hbm_p8,
    snap_membus_256_t* d_hbm_p9,
    snap_membus_256_t* d_hbm_p10,
    snap_membus_256_t* d_hbm_p11,
    snap_membus_256_t* d_hbm_p12,
    snap_membus_256_t* d_hbm_p13,
    snap_membus_256_t* d_hbm_p14,
    snap_membus_256_t* d_hbm_p15,
    snap_membus_256_t* d_hbm_p16,
    snap_membus_256_t* d_hbm_p17,
    snap_membus_256_t* d_hbm_p18,
    snap_membus_256_t* d_hbm_p19,
    snap_membus_256_t* d_hbm_p20,
    snap_membus_256_t* d_hbm_p21,
    snap_membus_256_t* d_hbm_p22,
    snap_membus_256_t* d_hbm_p23,
    snap_membus_256_t* d_hbm_p24,
    snap_membus_256_t* d_hbm_p25,
    snap_membus_256_t* d_hbm_p26,
    snap_membus_256_t* d_hbm_p27,
    snap_membus_256_t* d_hbm_p28,
    snap_membus_256_t* d_hbm_p29,
    snap_membus_256_t* d_hbm_p30,
    snap_membus_256_t* d_hbm_p31,
    action_reg* act_reg) {
    // Host Memory AXI Interface
#pragma HLS INTERFACE m_axi port = din_gmem bundle = host_mem offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64
#pragma HLS INTERFACE s_axilite port = din_gmem bundle = ctrl_reg offset = 0x030

#pragma HLS INTERFACE m_axi port = dout_gmem bundle = host_mem offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64
#pragma HLS INTERFACE s_axilite port = dout_gmem bundle = ctrl_reg offset = 0x040

    // HBM interfaces
#pragma HLS INTERFACE m_axi port = d_hbm_p0 bundle = card_hbm_p0 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p1 bundle = card_hbm_p1 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p2 bundle = card_hbm_p2 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p3 bundle = card_hbm_p3 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p4 bundle = card_hbm_p4 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p5 bundle = card_hbm_p5 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p6 bundle = card_hbm_p6 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p7 bundle = card_hbm_p7 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p8 bundle = card_hbm_p8 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p9 bundle = card_hbm_p9 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p10 bundle = card_hbm_p10 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p11 bundle = card_hbm_p11 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p12 bundle = card_hbm_p12 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p13 bundle = card_hbm_p13 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p14 bundle = card_hbm_p14 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p15 bundle = card_hbm_p15 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p16 bundle = card_hbm_p16 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p17 bundle = card_hbm_p17 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p18 bundle = card_hbm_p18 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p19 bundle = card_hbm_p19 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p20 bundle = card_hbm_p20 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p21 bundle = card_hbm_p21 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p22 bundle = card_hbm_p22 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p23 bundle = card_hbm_p23 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p24 bundle = card_hbm_p24 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p25 bundle = card_hbm_p25 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p26 bundle = card_hbm_p26 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p27 bundle = card_hbm_p27 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p28 bundle = card_hbm_p28 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p29 bundle = card_hbm_p29 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p30 bundle = card_hbm_p30 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

#pragma HLS INTERFACE m_axi port = d_hbm_p31 bundle = card_hbm_p31 offset = slave depth = 512 max_read_burst_length = \
    64 max_write_burst_length = 64 num_write_outstanding = HBM_NUM_WRITE_OUTSTANDING num_read_outstanding = \
        HBM_NUM_READ_OUTSTANDING

    // Host Memory AXI Lite Master Interface
#pragma HLS DATA_PACK variable = act_reg
#pragma HLS INTERFACE s_axilite port = act_reg bundle = ctrl_reg offset = 0x100
#pragma HLS INTERFACE s_axilite port = return bundle = ctrl_reg

    process_action(
        din_gmem,
        dout_gmem,
        d_hbm_p0,
        d_hbm_p1,
        d_hbm_p2,
        d_hbm_p3,
        d_hbm_p4,
        d_hbm_p5,
        d_hbm_p6,
        d_hbm_p7,
        d_hbm_p8,
        d_hbm_p9,
        d_hbm_p10,
        d_hbm_p11,
        d_hbm_p12,
        d_hbm_p13,
        d_hbm_p14,
        d_hbm_p15,
        d_hbm_p16,
        d_hbm_p17,
        d_hbm_p18,
        d_hbm_p19,
        d_hbm_p20,
        d_hbm_p21,
        d_hbm_p22,
        d_hbm_p23,
        d_hbm_p24,
        d_hbm_p25,
        d_hbm_p26,
        d_hbm_p27,
        d_hbm_p28,
        d_hbm_p29,
        d_hbm_p30,
        d_hbm_p31,
        act_reg);
}

//-----------------------------------------------------------------------------
//--- TESTBENCH ---------------------------------------------------------------
//-----------------------------------------------------------------------------

#ifdef NO_SYNTH

 12;int main(void) {
#define MEMORY_LINES_256 16384 /* 512 KiB */
#define MEMORY_LINES_1024 4096 /* 512 KiB */
    int rc = 0;
    unsigned int i;
    static snap_membus_1024_t din_gmem[MEMORY_LINES_1024];
    static snap_membus_1024_t dout_gmem[MEMORY_LINES_1024];
    static snap_membus_256_t d_hbm_p0[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p1[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p2[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p3[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p4[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p5[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p6[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p7[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p8[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p9[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p10[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p11[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p12[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p13[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p14[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p15[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p16[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p17[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p18[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p19[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p20[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p21[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p22[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p23[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p24[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p25[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p26[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p27[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p28[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p29[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p30[MEMORY_LINES_256];
    static snap_membus_256_t d_hbm_p31[MEMORY_LINES_256];

    auto align = [](uint32_t& address) {
        const int alignment = 128;
        address += address % alignment == 0 ? 0 : (alignment - (size_t)address % alignment);
    };

    action_reg act_reg;

    act_reg.Control.flags = 0x1; /* just not 0x0 */

    act_reg.Data.bwt_primary = 17048;
    act_reg.Data.bwt_L2[0] = 0;
    act_reg.Data.bwt_L2[1] = 18548;
    act_reg.Data.bwt_L2[2] = 29903;
    act_reg.Data.bwt_L2[3] = 41258;
    act_reg.Data.bwt_L2[4] = 59806;

    act_reg.Data.bwt_addr = 0;
    act_reg.Data.bwt_size;

    uint32_t dram_offset_bytes = 0;
    // Init BWT
    load_from_file(
        "/home/till/Till/mt-fpga-alignment/sample_data/Wuhan-Hu-1.bwt.bin",
        &act_reg.Data.bwt_addr,
        &act_reg.Data.bwt_size,
        din_gmem,
        &dram_offset_bytes);

    align(dram_offset_bytes);

    // Init sequences
    load_from_file(
        "/home/till/Till/mt-fpga-alignment/sample_data/sample10.seq.bin",
        &act_reg.Data.sequences_addr,
        &act_reg.Data.sequences_size,
        din_gmem,
        &dram_offset_bytes);

    align(dram_offset_bytes);

    // Init SMEM results free-list
    uint32_t smem_results_overflow_size_bytes = 8 * (sizeof(uint32_t) + sizeof(bwt_interval_vector_t));
    act_reg.Data.smem_results_overflow_addr = dram_offset_bytes;
    dram_offset_bytes += smem_results_overflow_size_bytes;
    for (int i = 0; i < 7; i++)
        *((char*)din_gmem + dram_offset_bytes + (sizeof(uint32_t) * i)) = i + 1;
    *(uint32_t*)((char*)din_gmem + dram_offset_bytes + (sizeof(uint32_t) * 7)) = 0xffffffff;

    align(dram_offset_bytes);

    // Init tasks
    const int num_tasks = 16;
    bwt_interval_vector_t* smems = (bwt_interval_vector_t*)(uint64_t)dram_offset_bytes;
    dram_offset_bytes += sizeof(bwt_interval_vector_t) * num_tasks;

    align(dram_offset_bytes);

    //act_reg.Data.smem_task_queue_size = SMEM_TASK_QUEUE_NUM_ENTRIES * sizeof(smem_task_t);
    act_reg.Data.smem_task_queue_addr = dram_offset_bytes;
    dram_offset_bytes += SMEM_TASK_QUEUE_NUM_ENTRIES * sizeof(smem_task_t);
    smem_task_t tasks[num_tasks] = {
        {.sequence_offset = 0,
         .start_position = 0,
         .sequence_length = 250,
         .smems = &smems[0],
         .min_intv = 1},  // .n = 1
        {.sequence_offset = 0,
         .start_position = 9,
         .sequence_length = 250,
         .smems = &smems[1],
         .min_intv = 1},  // .n = 6
        {.sequence_offset = 0,
         .start_position = 16,
         .sequence_length = 250,
         .smems = &smems[2],
         .min_intv = 1},  // .n = 4
        {.sequence_offset = 0,
         .start_position = 21,
         .sequence_length = 250,
         .smems = &smems[3],
         .min_intv = 1},  // .n = 5
        {.sequence_offset = 0,
         .start_position = 29,
         .sequence_length = 250,
         .smems = &smems[4],
         .min_intv = 1},  // .n = 4
        {.sequence_offset = 0,
         .start_position = 36,
         .sequence_length = 250,
         .smems = &smems[5],
         .min_intv = 1},  // .n = 4
        {.sequence_offset = 0,
         .start_position = 43,
         .sequence_length = 250,
         .smems = &smems[6],
         .min_intv = 1},  // .n = 5
        {.sequence_offset = 0,
         .start_position = 48,
         .sequence_length = 250,
         .smems = &smems[7],
         .min_intv = 1},  // .n = 3
        {.sequence_offset = 0,
         .start_position = 58,
         .sequence_length = 250,
         .smems = &smems[8],
         .min_intv = 1},  // .n = 4
        {.sequence_offset = 0,
         .start_position = 65,
         .sequence_length = 250,
         .smems = &smems[9],
         .min_intv = 1},  // .n = 5
        {.sequence_offset = 0,
         .start_position = 74,
         .sequence_length = 250,
         .smems = &smems[10],
         .min_intv = 1},  // .n = 3
        {.sequence_offset = 0,
         .start_position = 82,
         .sequence_length = 250,
         .smems = &smems[11],
         .min_intv = 1},  // .n = 6
        {.sequence_offset = 0,
         .start_position = 90,
         .sequence_length = 250,
         .smems = &smems[12],
         .min_intv = 1},  // .n = 5
        {.sequence_offset = 250, .start_position = 0, .sequence_length = 250, .smems = &smems[13], .min_intv = 1},
        {.sequence_offset = 250, .start_position = 159, .sequence_length = 250, .smems = &smems[14], .min_intv = 1},
        {.sequence_offset = 0xffffffff, .start_position = 0, .sequence_length = 0, .smems = NULL, .min_intv = 1},
    };
    __builtin_memcpy((char*)din_gmem + act_reg.Data.smem_task_queue_addr, tasks, sizeof(smem_task_t) * num_tasks);
    dram_offset_bytes += sizeof(smem_task_t) * num_tasks;
    align(dram_offset_bytes);

    act_reg.Data.runtime_status_control_addr = dram_offset_bytes;
    dram_offset_bytes += sizeof(runtime_status_control_t);
    align(dram_offset_bytes);

    runtime_status_control_t runtime_status_control;
    runtime_status_control.host_next_task_index = num_tasks;
    runtime_status_control.accelerator_processed_index = 0;
    __builtin_memcpy(
        (char*)din_gmem + act_reg.Data.runtime_status_control_addr,
        &runtime_status_control,
        sizeof(runtime_status_control_t));


    hls_action(
        din_gmem,
        dout_gmem,
        d_hbm_p0,
        d_hbm_p1,
        d_hbm_p2,
        d_hbm_p3,
        d_hbm_p4,
        d_hbm_p5,
        d_hbm_p6,
        d_hbm_p7,
        d_hbm_p8,
        d_hbm_p9,
        d_hbm_p10,
        d_hbm_p11,
        d_hbm_p12,
        d_hbm_p13,
        d_hbm_p14,
        d_hbm_p15,
        d_hbm_p16,
        d_hbm_p17,
        d_hbm_p18,
        d_hbm_p19,
        d_hbm_p20,
        d_hbm_p21,
        d_hbm_p22,
        d_hbm_p23,
        d_hbm_p24,
        d_hbm_p25,
        d_hbm_p26,
        d_hbm_p27,
        d_hbm_p28,
        d_hbm_p29,
        d_hbm_p30,
        d_hbm_p31,
        &act_reg);

    smems = (bwt_interval_vector_t*)((char*)dout_gmem + (uint64_t)smems);

    if (act_reg.Control.Retc == SNAP_RETC_FAILURE) {
        fprintf(stderr, " ==> RETURN CODE FAILURE <==\n");
        return 1;
    }

    //    std::cout << "HBM:" << std::endl;
    //    for (int i = 0; i < (act_reg.Data.bwt.size >> 2); ++i)
    //        std::cout << "0x" << std::hex << std::setfill('0') << std::setw(8) << *((uint32_t *)d_hbm_p0 + i)  << " ";
    //
    //    std::cout << std::endl << "DRAM:" << std::endl;
    //    for (int i = 0; i < (act_reg.Data.bwt.size >> 2); ++i)
    //        std::cout << "0x"   << std::hex << std::setfill('0') << std::setw(8) << *((uint32_t *)din_gmem + act_reg.Data.bwt.addr + i)  << " ";

    int conditions = memcmp(
        (void*)((unsigned long)d_hbm_p0 + 0),
        (void*)((unsigned long)din_gmem + act_reg.Data.bwt_addr),
        act_reg.Data.bwt_size);

    if (conditions != 0) {
        fprintf(stderr, " ==> DATA COMPARE FAILURE <==\n");
        return 1;
    } else
        printf(" ==> DATA COMPARE OK <==\n");

    return 0;
}

#endif
