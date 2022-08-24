Inc("../../globals.py")
Inc("../../types/streams/TerminationSignalStream.py")
Inc("../../types/Numeric.py")
Inc("../../types/HlsHmem.py")
Inc("../../types/AcceleratorResults.py")
Inc("WrappedHlsEntity.py")
Inc("HlsPort.py")

WrappedHlsEntity(
    "results_to_host_manager",
    HlsPortM("m_axi_host_mem", T("HlsHmem"), suffix="V"),
    HlsPortI("runtime_status_control_addr", T("u64")),
    *HlsPortsM(
        "result_buffers",
        T("AcceleratorResultBufferMemRd"),
        NUM_SMEM_CORES,
        suffix="V",
    ),
    *HlsPortsM(
        "freed_result_buffer_streams",
        T("FreedResultBufferStreamSource"),
        NUM_SMEM_CORES,
    ),
    *HlsPortsM(
        "filled_result_buffer_streams",
        T("FilledResultBufferStreamSink"),
        NUM_SMEM_CORES,
    ),
    HlsPortM("termination_signal_stream", T("TerminationSignalStreamSink"), suffix="V"),
)
