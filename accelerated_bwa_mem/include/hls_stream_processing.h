#ifndef ACCELERATED_BWA_MEM_HW_ARBITER_H
#define ACCELERATED_BWA_MEM_HW_ARBITER_H

#include <ap_int.h>
#include <ap_utils.h>
#include <hls_stream.h>

#include "hls_ap_utils.h"

#define PARTITIONED_STREAM_PARTITION_SIZE 256

template<typename STREAM_TYPE>
struct STREAM_TERMINATION
{ static const STREAM_TYPE SIGNAL; };

template<typename STREAM_TYPE>
struct stream_type_to_ap_uint
{
    static const int width = STREAM_TYPE::width;
    // static const int width = sizeof(STREAM_TYPE) * 8;
    typedef ap_uint<width> type;
};

template<typename STREAM_TYPE>
struct ap_stream : public hls::stream<typename stream_type_to_ap_uint<STREAM_TYPE>::type>
{
    typedef typename stream_type_to_ap_uint<STREAM_TYPE>::type AP_TYPE;

    void operator>>(STREAM_TYPE& rdata) {
        AP_TYPE ap_element;
        hls::stream<AP_TYPE>::operator>>(ap_element);
        rdata = STREAM_TYPE(ap_element);
    }

    bool read_nb(STREAM_TYPE& rdata) {
#pragma HLS inline
        if (hls::stream<AP_TYPE>::empty())
            return false;
        else {
            operator>>(rdata);
            return true;
        }
    }

    void operator<<(const STREAM_TYPE& wdata) {
        const AP_TYPE ap_element = static_cast<AP_TYPE>(wdata);
        hls::stream<AP_TYPE>::operator<<(ap_element);
    }
};

template<int BITS>
struct generate_ap_uint
{ typedef ap_uint<BITS> type; };

template<typename STREAM_TYPE>
class ap_partitioned_stream : public hls::stream<typename generate_ap_uint<PARTITIONED_STREAM_PARTITION_SIZE>::type>
{
public:
    typedef ap_uint<PARTITIONED_STREAM_PARTITION_SIZE> AP_TYPE_PART;

    static const int num_partitions = ((sizeof(STREAM_TYPE) * 8) / PARTITIONED_STREAM_PARTITION_SIZE);

    void operator>>(STREAM_TYPE& rdata) {
        AP_TYPE_PART ap_element[num_partitions];

        for (int i = 0; i < num_partitions; i++) {
            hls::stream<AP_TYPE_PART>::operator>>(ap_element[i]);
        }
        rdata = STREAM_TYPE(ap_element);
    }

    bool read_nb(STREAM_TYPE& rdata) {
        if (hls::stream<AP_TYPE_PART>::empty())
            return false;
        else {
            operator>>(rdata);
            return true;
        }
    }

    void operator<<(const STREAM_TYPE& wdata) {
        AP_TYPE_PART ap_element[num_partitions];
        wdata.to_ap_uint_v(ap_element);

        for (int i = 0; i < num_partitions; i++) {
            hls::stream<AP_TYPE_PART>::operator<<(ap_element[i]);
        }
    }
};

template<int N>
void termination_signal_distributor(
    hls::stream<bool>& termination_signal_stream,
    hls::stream<bool> termination_signal_streams[N]) {
    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate)
        ;
    for (int i = 0; i < N; i++)
        termination_signal_streams[i] << terminate;
}


//template<typename STREAM_TYPE, int N, bool FIXED_ORDER>
template<template<typename> class STREAM, typename STREAM_TYPE, int N, bool FIXED_ORDER>
void arbiter_1_to_N(
    STREAM<STREAM_TYPE>& input_stream,
    STREAM<STREAM_TYPE> output_streams[N],
    hls::stream<bool>& termination_signal_stream) {
    int current_output_stream = 0;
    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
        STREAM_TYPE element;
        input_stream >> element;

        bool inserted = false;
        while (!inserted) {
            if (FIXED_ORDER || !output_streams[current_output_stream].full()) {
                output_streams[current_output_stream] << element;
                inserted = true;
            }
            current_output_stream = (current_output_stream + 1) % N;
        }
    }
}

template<template<typename> class STREAM, typename STREAM_TYPE, int N>
void arbiter_N_to_1(
    STREAM<STREAM_TYPE> input_streams[N],
    STREAM<STREAM_TYPE>& output_stream,
    hls::stream<bool>& termination_signal_stream) {
    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline rewind
        for (ap_uint<8> current_input_stream = 0; current_input_stream < N; current_input_stream++) {
            STREAM_TYPE element;
            if (input_streams[current_input_stream].read_nb(element)) {
                output_stream << element;
            }
        }
    }
}

template<template<typename> class STREAM, typename STREAM_TYPE, int N>
void burst_arbiter_N_to_1(
    STREAM<STREAM_TYPE> input_streams[N],
    STREAM<STREAM_TYPE>& output_stream,
    hls::stream<bool>& termination_signal_stream) {
    bool terminate;
    while (!termination_signal_stream.read_nb(terminate) || !terminate) {
#pragma HLS pipeline rewind
        for (ap_uint<8> current_input_stream = 0; current_input_stream < N; current_input_stream++) {
            STREAM_TYPE element;
            while (input_streams[current_input_stream].read_nb(element)) {
                output_stream << element;
            }
        }
    }
}

template<
    template<typename>
    class REQ_STREAM,
    typename REQ_STREAM_TYPE,
    template<typename>
    class RET_STREAM,
    typename RET_STREAM_TYPE>
void bidirectional_stream_access(
    REQ_STREAM<REQ_STREAM_TYPE>& req_stream,
    RET_STREAM<RET_STREAM_TYPE>& ret_stream,
    REQ_STREAM_TYPE req_element,
    RET_STREAM_TYPE& ret_element) {
    req_stream << req_element;
    ap_wait();  // This prevents previous and following instructions from being combined into one clock cycle, resulting in a deadlock
    ret_stream >> ret_element;
}


template<
    template<typename>
    class REQ_STREAM,
    typename REQ_STREAM_TYPE,
    template<typename>
    class RET_STREAM,
    typename RET_STREAM_TYPE,
    int N>
void bidirectional_arbiter_N_to_1(
    REQ_STREAM<REQ_STREAM_TYPE> req_input_streams[N],
    RET_STREAM<RET_STREAM_TYPE> ret_input_streams[N],
    REQ_STREAM<REQ_STREAM_TYPE>& req_output_stream,
    RET_STREAM<RET_STREAM_TYPE>& ret_output_stream) {
    ap_uint<N> is_stream_terminated = 0;
    while (true) {
        for (ap_uint<8> current_input_stream = 0; current_input_stream < N; current_input_stream++) {
#pragma HLS pipeline
            REQ_STREAM_TYPE req_element;
            if (req_input_streams[current_input_stream].read_nb(req_element)) {
                if (req_element == STREAM_TERMINATION<REQ_STREAM_TYPE>::SIGNAL) {
                    is_stream_terminated |= 1 << current_input_stream;
                } else {
                    RET_STREAM_TYPE ret_element;
                    bidirectional_stream_access(req_output_stream, ret_output_stream, req_element, ret_element);
                    ret_input_streams[current_input_stream] << ret_element;
                }
            }
        }
        if (is_stream_terminated == ((1 << N) - 1)) {
            req_output_stream << STREAM_TERMINATION<REQ_STREAM_TYPE>::SIGNAL;
            return;
        }
    }
}

#endif  //ACCELERATED_BWA_MEM_HW_ARBITER_H
