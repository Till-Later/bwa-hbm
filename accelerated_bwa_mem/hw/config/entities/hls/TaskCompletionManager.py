Inc("../../types/Numeric.py")
Inc("../../types/streams/PipelineIndexStream.py")
Inc("../../types/streams/TaskStream.py")
Inc("../../types/Smem.py")
Inc("../../types/AcceleratorResults.py")
Inc("../../types/streams/TerminationSignalStream.py")
Inc("WrappedHlsEntity.py")
Inc("HlsPort.py")

WrappedHlsEntity(
    "task_completion_manager",
    HlsPortI("split_width", T("u32")),
    HlsPortI("split_len", T("u32")),
    HlsPortI("min_seed_len", T("u32")),
    HlsPortM("completed_task_stream", T("PipelineIndexStreamSink")),
    HlsPortM("follow_up_task_stream", T("FollowUpTaskStreamSource")),
    HlsPortM("freed_pipeline_index_stream", T("PipelineIndexStreamSource")),
    HlsPortM("smem_buffer", T("SmemMem"), suffix="V"),
    HlsPortM("result_buffer", T("AcceleratorResultBufferMemWr"), suffix="V"),
    HlsPortM("freed_result_buffer_stream", T("FreedResultBufferStreamSink")),
    HlsPortM("filled_result_buffer_stream", T("FilledResultBufferStreamSource")),
    HlsPortM("termination_signal_stream", T("TerminationSignalStreamSink"), suffix="V"),
)
