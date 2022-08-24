#include "hls_smem_task_scheduler.h"

#include "hls_ap_utils.h"

void membus1024_to_membus256(snap_membus_1024_t buffer_1024, snap_membus_256_t buffer_256[DW256PERDW1024]) {
    buffer_256[0] = SLICE(buffer_1024, 0, MEMDW_256);
    buffer_256[1] = SLICE(buffer_1024, 1, MEMDW_256);
    buffer_256[2] = SLICE(buffer_1024, 2, MEMDW_256);
    buffer_256[3] = SLICE(buffer_1024, 3, MEMDW_256);
}

sequence_element_t sequence_byte_to_sequence_element(ap_uint<8> sequence_byte) {
    switch (sequence_byte) {
    case 'a':
    case 'A':
        return 0;
    case 'c':
    case 'C':
        return 1;
    case 'g':
    case 'G':
        return 2;
    case 't':
    case 'T':
        return 3;
    case '-':
        return 5;
    case '$':
        return 7;
    default:
        return 4;
    }
}

task_index_t get_scheduled_sequence_chunk_tasks_insertion_index(
    snap_membus_1024_t* gmem,
    snapu64_t runtime_status_control_addr) {
    snap_membus_1024_t buffer1024;
    __builtin_memcpy(
        &buffer1024,
        gmem
            + ((runtime_status_control_addr + SCHEDULED_SEQUENCE_CHUNK_TASKS_INSERTION_INDEX_OFFSET)
               >> ADDR_RIGHT_SHIFT_1024),
        sizeof(snap_membus_1024_t));
    return SLICE(buffer1024, 0, sizeof(task_index_t) * 8);
}

void set_scheduled_sequence_chunk_tasks_extraction_index(
    snap_membus_1024_t* gmem,
    snapu64_t runtime_status_control_addr,
    task_index_t index) {
    snap_membus_1024_t buffer1024 = 0;
    SLICE(buffer1024, 0, sizeof(task_index_t) * 8) = index;
    *(gmem
      + ((runtime_status_control_addr + SCHEDULED_SEQUENCE_CHUNK_TASKS_EXTRACTION_INDEX_OFFSET)
         >> ADDR_RIGHT_SHIFT_1024)) = buffer1024;
}

void schedule_sequences_from_buffer(
    snap_membus_1024_t buffer_1024[HOST_SEQUENCE_COPY_BUFFER_SIZE],
    sequence_section_t sequences[NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER],
    global_sequence_index_t& current_sequence_offset,
    global_sequence_index_t& sequence_start_offset,
    int current_copy_iteration,
    uint32_t& remaining_sequences,
    sequence_chunk_index_t chunk_index,
    task_index_t& current_task_index,
    ap_stream<task>& task_stream) {
    if (!remaining_sequences) return;


    global_sequence_index_t chunk_base_offset = chunk_index * SEQUENCE_CHUNK_SIZE;
    for (int copy_buffer_index = 0; copy_buffer_index < HOST_SEQUENCE_COPY_BUFFER_SIZE; copy_buffer_index++) {
        snap_membus_1024_t current_buffer_1024 = buffer_1024[copy_buffer_index];

        snap_membus_256_t current_buffer_256[DW256PERDW1024];
#pragma HLS array_partition variable = current_buffer_256 complete
        membus1024_to_membus256(current_buffer_1024, current_buffer_256);

        for (uint8_t i = 0; i < DW256PERDW1024; i++) {
#pragma HLS pipeline
            sequence_section_t converted_sequence_section;
            ap_uint<BPERDW_256> has_ending = 0;
            uint8_t end_index = 0;
            for (uint8_t j = 0; j < BPERDW_256; j++) {
#pragma HLS unroll
                char current_buffer_element = SLICE(current_buffer_256[i], j, 8);
                sequence_element_t current_sequence_element = sequence_byte_to_sequence_element(current_buffer_element);
                SLICE(converted_sequence_section, j, sequence_element_t::width) = current_sequence_element;

                SLICE(has_ending, j, 1) = current_sequence_element == 7;
            }
            sequences
                [(chunk_index * NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_CHUNK)
                 + ((current_copy_iteration * HOST_SEQUENCE_COPY_BUFFER_SIZE + copy_buffer_index) << 2) + i] =
                    converted_sequence_section;

            end_index = __builtin_ctz(has_ending);

            if (has_ending && remaining_sequences) {
                task task;
                task.task_index = current_task_index++;
                task.sequence_offset = chunk_base_offset + sequence_start_offset;
                task.sequence_length = (current_sequence_offset + end_index) - sequence_start_offset;
                task_stream << task;
                remaining_sequences--;
                sequence_start_offset = current_sequence_offset + end_index + 1;
            }
            current_sequence_offset += BPERDW_256;

            // if (!remaining_sequences) return;
        }
    }
}

void copy_sequences_and_schedule_tasks(
    snap_membus_1024_t* gmem,
    sequence_section_t sequences[NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER],
    ap_stream<task>& task_stream,
    sequence_chunk_task_t sequence_chunk_task,
    task_index_t& current_task_index) {
    global_sequence_index_t sequence_start_offset = 0;
    global_sequence_index_t current_sequence_offset = 0;

    uint32_t remaining_sequences = sequence_chunk_task.num_sequences;
    snap_membus_1024_t buffer_1024[HOST_SEQUENCE_COPY_BUFFER_SIZE];

    for (int current_copy_iteration = 0; current_copy_iteration < NUM_COPY_ITERATIONS_PER_SEQUENCE_CHUNK;
         current_copy_iteration++) {
        __builtin_memcpy(
            buffer_1024,
            (snap_membus_1024_t*)(gmem + ((sequence_chunk_task.host_address + current_sequence_offset) >> ADDR_RIGHT_SHIFT_1024)),
            (HOST_SEQUENCE_COPY_BUFFER_SIZE * BPERDW_1024));

        schedule_sequences_from_buffer(
            buffer_1024,
            sequences,
            current_sequence_offset,
            sequence_start_offset,
            current_copy_iteration,
            remaining_sequences,
            sequence_chunk_task.chunk_index,
            current_task_index,
            task_stream);
    }
}

sequence_chunk_task_t get_sequence_chunk_task(
    snap_membus_1024_t* gmem,
    snapu64_t runtime_status_control_addr,
    task_queue_index_t queue_index) {
    snap_membus_1024_t buffer_1024 = (snap_membus_1024_t)
        * (gmem
           + ((runtime_status_control_addr + SCHEDULED_SEQUENCE_CHUNK_TASKS_OFFSET
               + (queue_index * sizeof(sequence_chunk_task_t)))
              >> ADDR_RIGHT_SHIFT_1024));

    buffer_1024 >>= ((queue_index & (NUM_SEQUENCE_CHUNK_TASKS_PER_DW1024 - 1)) * sizeof(sequence_chunk_task_t) * 8);

    return (sequence_chunk_task_t){buffer_1024(63, 0), buffer_1024(95, 64), buffer_1024(103, 96), {}};
}

void schedule_tasks(
    snapu64_t runtime_status_control_addr,
    snap_membus_1024_t* gmem,
    sequence_section_t sequences[NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER],
    ap_stream<task>& task_stream,
    hls::stream<bool>& termination_signal_stream) {
    task_index_t insertion_index = 0;
    task_index_t extraction_index = 0;
    task_index_t current_task_index = 0;

    while (true) {
        if (insertion_index == extraction_index) {
            insertion_index = get_scheduled_sequence_chunk_tasks_insertion_index(gmem, runtime_status_control_addr);
            while (insertion_index == extraction_index) {
                for (int i = 0; i < 10000; i++) {
                    ap_wait();
                }
                insertion_index = get_scheduled_sequence_chunk_tasks_insertion_index(gmem, runtime_status_control_addr);
            }
        }

        sequence_chunk_task_t sequence_chunk_task =
            get_sequence_chunk_task(gmem, runtime_status_control_addr, extraction_index & (NUM_SEQUENCE_CHUNKS - 1));

        if (sequence_chunk_task.host_address == 0xffffffffffffffff) {
            termination_signal_stream << true;
            break;
        }

        copy_sequences_and_schedule_tasks(gmem, sequences, task_stream, sequence_chunk_task, current_task_index);

        extraction_index++;
        set_scheduled_sequence_chunk_tasks_extraction_index(gmem, runtime_status_control_addr, extraction_index);
    }
}

void smem_task_scheduler(
    snapu64_t runtime_status_control_addr,
    snap_membus_1024_t* gmem,
    sequence_section_t sequences[NUM_SEQUENCE_SECTIONS_PER_SEQUENCE_BUFFER],
    ap_stream<task> task_streams[NUM_SMEM_CORES],
    hls::stream<bool> termination_signal_streams[NUM_TERMINATION_SIGNAL_STREAMS]) {
#pragma HLS stable variable = runtime_status_control_addr
#pragma HLS INTERFACE m_axi port = gmem bundle = host_mem max_read_burst_length = 64 max_write_burst_length = \
    2 num_read_outstanding = 8 num_write_outstanding = 2
#pragma HLS resource variable = sequences core = RAM_1P
#pragma HLS interface ap_memory port = sequences
#pragma HLS INTERFACE ap_ctrl_hs port = return

    ap_stream<task> task_stream;
#pragma HLS STREAM depth = STREAM_BUFFER_DEPTH variable = task_stream

    hls::stream<bool> termination_signal_stream;
#pragma HLS STREAM depth = 1 variable = termination_signal_stream
    hls::stream<bool> arbiter_termination_signal_streams[2];
#pragma HLS STREAM depth = 1 variable = arbiter_termination_signal_streams

#pragma HLS dataflow
    termination_signal_distributor<2>(termination_signal_stream, arbiter_termination_signal_streams);
    termination_signal_distributor<NUM_TERMINATION_SIGNAL_STREAMS>(
        arbiter_termination_signal_streams[1], termination_signal_streams);

    arbiter_1_to_N<ap_stream, task, NUM_SMEM_CORES, false>(
        task_stream, task_streams, arbiter_termination_signal_streams[0]);
    schedule_tasks(runtime_status_control_addr, gmem, sequences, task_stream, termination_signal_stream);
}
