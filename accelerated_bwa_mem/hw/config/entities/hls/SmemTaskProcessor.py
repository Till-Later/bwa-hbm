Inc("../../types/Numeric.py")
Inc("../../types/Sequences.py")
Inc("../../types/streams/TaskStream.py")
Inc("../../types/streams/BwtExtendStream.py")
Inc("../../types/streams/PipelineIndexStream.py")
Inc("../../types/streams/TerminationSignalStream.py")
Inc("WrappedHlsEntity.py")
Inc("HlsPort.py")

WrappedHlsEntity(
    "smem_task_processor",
    HlsPortI("bwt_L2", T("u320")),
    HlsPortM("task_stream", T("TaskStreamSink")),
    HlsPortM("follow_up_task_stream", T("FollowUpTaskStreamSink")),
    *HlsPortsM("req_bwt_extend_streams", T("BwtExtendStreamSource"), 4),
    *HlsPortsM("ret_bwt_extend_streams", T("BwtExtendStreamSink"), 4),
    HlsPortM("freed_pipeline_index_stream", T("PipelineIndexStreamSink")),
    HlsPortM("completed_task_stream", T("PipelineIndexStreamSource")),
    HlsPortM("sequence_buffer", T("HlsSequenceRdBus"), suffix="V"),
    *((HlsPortM(f"smem_buffer_{i}_request_stream", T("SmemRequestStreamSource"))) for i in range(6)),
    *((HlsPortM(f"smem_buffer_{i}_response_stream", T("SmemResponseStreamSink"))) for i in range(6)),
    HlsPortM("termination_signal_stream", T("TerminationSignalStreamSink"), suffix="V"),
)
