Inc("../../globals.py")
Inc("../../utils.py")

Inc("../../include/ocaccel.py")

Inc("../hls/HlsPort.py")
Inc("../SmemBuffer.py")
Inc("../AcceleratorResultBuffer.py")
Inc("../BwtExtendStateBuffer.py")
Inc("../BwtExtendStreamArbiter.py")
Inc("../hls/BwtExtendProcessor.py")
Inc("../hls/SmemTaskProcessor.py")
Inc("../hls/TaskCompletionManager.py")

Inc("../../types/Sequences.py")
Inc("../../types/Numeric.py")
Inc("../../types/Smem.py")
Inc("../../types/Control.py")
Inc("../../types/AcceleratorResults.py")
Inc("../../types/streams/TaskStream.py")
Inc("../../types/streams/PipelineIndexStream.py")
Inc("../../types/streams/TerminationSignalStream.py")
Inc("../../types/streams/BwtStream.py")

# StreamBufferTemplate("TaskStream")
# StreamBufferTemplate("PipelineIndexStream")
StreamBufferTemplate("FollowUpTaskStream")

with Ent(
    "SmemCore",
    PortI("sys", ocaccel.tsys, x_wrapname="ap"),
    PortS(
        "ctrl_hs_smem_task_processor",
        T("HlsBlockCtrlHs"),
        x_wrapname="ctrl_hs_smem_task_processor",
    ),
    PortS(
        "ctrl_hs_bwt_extend_processor",
        T("HlsBlockCtrlHs"),
        x_wrapname="ctrl_hs_bwt_extend_processor",
    ),
    PortS(
        "ctrl_hs_task_completion_manager",
        T("HlsBlockCtrlHs"),
        x_wrapname="ctrl_hs_task_completion_manager",
    ),
    PortI("bwt_primary", T("u64"), x_wrapname="bwt_primary"),
    PortI("bwt_L2", T("u320"), x_wrapname="bwt_L2"),
    HlsPortI("split_width", T("u32")),
    HlsPortI("split_len", T("u32")),
    HlsPortI("min_seed_len", T("u32")),
    PortM("task_stream_sink", T("TaskStreamSink"), x_wrapname="task_stream_sink"),
    PortM("sequence_rd_bus", T("HlsSequenceRdBus"), x_wrapname="sequence_rd_bus"),
    PortM(
        "req_bwt_position_stream_source",
        T("HlsBwtPositionStreamSource"),
        x_wrapname="req_bwt_position_stream_source",
    ),
    PortM(
        "ret_bwt_entry_stream_sink",
        T("HlsBwtEntryStreamSink"),
        x_wrapname="ret_bwt_entry_stream_sink",
    ),
    PortS("result_buffer_mem_rd", T("AcceleratorResultBufferMemRd")),
    HlsPortM("freed_result_buffer_stream_sink", T("FreedResultBufferStreamSink")),
    HlsPortM("filled_result_buffer_stream_source", T("FilledResultBufferStreamSource")),
    PortM(
        "termination_signal_stream_sink_smem_task_processor",
        T("TerminationSignalStreamSink"),
        x_wrapname="termination_signal_stream_sink_smem_task_processor",
    ),
    PortM(
        "termination_signal_stream_sink_bwt_extend_processor",
        T("TerminationSignalStreamSink"),
        x_wrapname="termination_signal_stream_sink_bwt_extend_processor",
    ),
    PortM(
        "termination_signal_stream_sink_task_completion_manager",
        T("TerminationSignalStreamSink"),
        x_wrapname="termination_signal_stream_sink_task_completion_manager",
    ),
    x_templates={"generic/entity.vhd": "smem_core.vhd"},
):
    Ins(
        "smem_task_processor",
        "smem_task_processor",
        MapPort("sys", S("sys")),
        MapPort("ctrl_hs", S("ctrl_hs_smem_task_processor")),
        MapPort("bwt_L2", S("bwt_L2")),
        *MapHlsPorts("req_bwt_extend_streams", "req_bwt_extend_streams_source", 4),
        *MapHlsPorts("ret_bwt_extend_streams", "ret_bwt_extend_streams_sink", 4),
        MapPort("task_stream", S("task_stream_sink")),
        MapPort("follow_up_task_stream", S("follow_up_task_stream_sink")),
        MapPort("freed_pipeline_index_stream", S("freed_pipeline_index_stream_sink")),
        MapPort("completed_task_stream", S("completed_task_stream_source")),
        MapPort("sequence_buffer", S("sequence_rd_bus")),
        *(
            MapPort(
                f"smem_buffer_{i}_request_stream",
                S(f"smem_buffer_{i}_request_stream_source"),
            )
            for i in range(6)
        ),
        *(
            MapPort(
                f"smem_buffer_{i}_response_stream",
                S(f"smem_buffer_{i}_response_stream_sink"),
            )
            for i in range(6)
        ),
        MapPort(
            "termination_signal_stream",
            S("termination_signal_stream_sink_smem_task_processor"),
        ),
    )

    Ins(
        "SmemBuffer",
        "smem_buffer",
        MapGeneric("NumStreamPorts", Lit(6)),
        MapPort("sys", S("sys")),
        MapPort(
            "reqStreams",
            SV(*(f"smem_buffer_{i}_request_stream_source" for i in range(6))),
        ),
        MapPort(
            "respStreams",
            SV(*(f"smem_buffer_{i}_response_stream_sink" for i in range(6))),
        ),
        MapPort("smemBufferMem", S("smem_buffer_mem")),
    )

    Ins(
        "BwtExtendStreamArbiter",
        "bwt_extend_stream_arbiter",
        MapGeneric("StreamCount", Lit(4)),
        MapGeneric("LogRequestFifoDepth", Lit(2)),
        MapGeneric("PipelineIndexWidth", Lit(PIPELINE_INDEX_WIDTH)),
        MapPort("sys", S("sys")),
        MapPort(
            "req_bwt_extend_streams",
            SV(*(f"req_bwt_extend_streams_source_{i}" for i in range(4))),
        ),
        MapPort("req_bwt_extend_stream", S("req_bwt_extend_stream_sink")),
        MapPort("ret_bwt_extend_stream", S("ret_bwt_extend_stream_source")),
        MapPort(
            "ret_bwt_extend_streams",
            SV(*(f"ret_bwt_extend_streams_sink_{i}" for i in range(4))),
        ),
    )

    Ins(
        "bwt_extend_processor",
        "bwt_extend_processor",
        MapPort("sys", S("sys")),
        MapPort("ctrl_hs", S("ctrl_hs_bwt_extend_processor")),
        MapPort("bwt_primary", S("bwt_primary")),
        MapPort("bwt_L2", S("bwt_L2")),
        MapPort("req_bwt_extend_stream", S("req_bwt_extend_stream_sink")),
        MapPort("req_bwt_position_stream", S("req_bwt_position_stream_source")),
        MapPort("ret_bwt_entry_stream", S("ret_bwt_entry_stream_sink")),
        MapPort("ret_bwt_extend_stream", S("ret_bwt_extend_stream_source")),
        MapPort(
            "termination_signal_stream",
            S("termination_signal_stream_sink_bwt_extend_processor"),
        ),
        MapPort("states_1", S("bwt_extend_state_buffer_mem_wr")),
        MapPort("states_2", S("bwt_extend_state_buffer_mem_rd")),
    )

    Ins(
        "BwtExtendStateBuffer",
        "bwt_extend_state_buffer",
        MapGeneric("AddPipelineStages", Lit(0)),
        MapGeneric("LatencyB", Lit(1)),
        MapPort("sys", S("sys")),
        MapPort("memPortWr", S("bwt_extend_state_buffer_mem_wr")),
        MapPort("memPortRd", S("bwt_extend_state_buffer_mem_rd")),
    )

    createStreamBufferInstance(
        "PipelineIndexStream",
        "freed_pipeline_index_stream",
        monitorPosition=MonitorPosition.NONE,
    )
    createStreamBufferInstance(
        "PipelineIndexStream",
        "completed_task_stream",
        monitorPosition=MonitorPosition.NONE,
        FIFOLogDepth=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
    )
    createStreamBufferInstance(
        "FollowUpTaskStream",
        "follow_up_task_stream",
        monitorPosition=MonitorPosition.NONE,
    )

    Ins(
        "AcceleratorResultBuffer",
        "accelerator_result_buffer",
        MapGeneric("AddPipelineStages", Lit(1)),
        MapGeneric("LatencyB", Lit(3)),
        MapPort("sys", S("sys")),
        MapPort("memPortWr", S("result_buffer_mem_wr")),
        MapPort("memPortRd", S("result_buffer_mem_rd")),
    )

    Ins(
        "task_completion_manager",
        "task_completion_manager",
        MapPort("sys", S("sys")),
        MapPort("ctrl_hs", S("ctrl_hs_task_completion_manager")),
        MapPort("split_width", S("split_width")),
        MapPort("split_len", S("split_len")),
        MapPort("min_seed_len", S("min_seed_len")),
        MapPort("completed_task_stream", S("completed_task_stream_sink")),
        MapPort("follow_up_task_stream", S("follow_up_task_stream_source")),
        MapPort("freed_pipeline_index_stream", S("freed_pipeline_index_stream_source")),
        MapPort("smem_buffer", S("smem_buffer_mem")),
        MapPort("result_buffer", S("result_buffer_mem_wr")),
        MapPort("freed_result_buffer_stream", S("freed_result_buffer_stream_sink")),
        MapPort("filled_result_buffer_stream", S("filled_result_buffer_stream_source")),
        MapPort(
            "termination_signal_stream",
            S("termination_signal_stream_sink_task_completion_manager"),
        ),
    )
