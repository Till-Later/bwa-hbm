Inc("../../globals.py")
Inc("../../types/Numeric.py")
Inc("../../types/Sequences.py")
Inc("../../types/HlsHmem.py")
Inc("../../types/streams/TerminationSignalStream.py")
Inc("../../types/streams/TaskStream.py")
Inc("WrappedHlsEntity.py")
Inc("HlsPort.py")

WrappedHlsEntity(
    "smem_task_scheduler",
    HlsPortI("runtime_status_control_addr", T("u64")),
    HlsPortM("m_axi_host_mem", T("HlsHmem"), suffix=""),
    HlsPortM("sequences", T("HlsSequencesMem"), suffix="V"),
    *HlsPortsM("task_streams", T("TaskStreamSource"), NUM_SMEM_CORES),
    *HlsPortsM(
        "termination_signal_streams",
        T("TerminationSignalStreamSource"),
        NUM_TERMINATION_SIGNAL_STREAMS,
        suffix="V",
    ),
)
