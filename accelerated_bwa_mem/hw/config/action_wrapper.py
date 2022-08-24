import math
from functools import partial
import itertools

Inc("globals.py")
Inc("utils.py")
Inc("include/dfaccto.py")
Inc("include/ocaccel.py")

streamMonitorChannelNames = []
for i in range(NUM_SMEM_CORES):
    for streamName in [
        "task_stream",
        "freed_result_buffer_stream",
        "filled_result_buffer_stream",
        "hls_req_bwt_position_stream",
        "hls_ret_bwt_entry_stream",
    ]:
        streamMonitorChannelNames.append(f"{streamName}_source_monitor_channel_{i}")
        streamMonitorChannelNames.append(f"{streamName}_sink_monitor_channel_{i}")
NUM_STREAM_MONITORS = len(streamMonitorChannelNames)

# HDL Components
Inc("entities/MemoryReadBusArbiter.py")
Inc("entities/SequencesMemWriteDistributor.py")
Inc("entities/SequenceBufferURAM.py")
Inc("entities/BwtEntryCompressor.py")

Inc("types/HlsHmem.py")
Inc("types/HlsHbm.py")

Inc("entities/templates/AxiPipelineStageTemplate.py")
AxiPipelineStageTemplate("AxiCtrl")

Inc("entities/templates/AxiConverterTemplate.py")
AxiConverterTemplate(ocaccel.thost.name, "HlsHmem")

Inc("entities/templates/MultiplexedAxiRwPortTemplate.py")
MultiplexedAxiRwPortTemplate("HlsHmem", 3)

Inc("types/streams/BwtStream.py")
Inc("types/streams/PipelineIndexStream.py")
Inc("types/streams/TaskStream.py")
Inc("types/streams/TerminationSignalStream.py")
Inc("types/AcceleratorResults.py")

Inc("entities/templates/StreamBufferTemplate.py")

StreamBufferTemplate("TaskStream")

StreamBufferTemplate("FreedResultBufferStream")
StreamBufferTemplate("FilledResultBufferStream")

StreamBufferTemplate("HlsBwtPositionStream")
StreamBufferTemplate("HlsBwtEntryStream")
StreamBufferTemplate("PipelineIndexStream")
StreamBufferTemplate("TerminationSignalStream")

Inc("entities/templates/StreamMonitorTemplate.py")

StreamMonitorTemplate("FreedResultBufferStreamSource")
StreamMonitorTemplate("FreedResultBufferStreamSink")

StreamMonitorTemplate("FilledResultBufferStreamSource")
StreamMonitorTemplate("FilledResultBufferStreamSink")

StreamMonitorTemplate("TaskStreamSink")
StreamMonitorTemplate("TaskStreamSource")

StreamMonitorTemplate("FollowUpTaskStreamSink")
StreamMonitorTemplate("FollowUpTaskStreamSource")

StreamMonitorTemplate("HlsBwtPositionStreamSource")
StreamMonitorTemplate("HlsBwtPositionStreamSink")

StreamMonitorTemplate("HlsBwtEntryStreamSource")
StreamMonitorTemplate("HlsBwtEntryStreamSink")

StreamMonitorTemplate("PipelineIndexStreamSource")
StreamMonitorTemplate("PipelineIndexStreamSink")

Inc("entities/templates/RegPortToMemPortTemplate.py")
Inc("types/Monitor.py")

RegPortToMemPortTemplate("AggregatedMonitorMem")

Inc("entities/templates/StreamCrossbarTemplate.py")

Inc("entities/templates/StreamIdBufferTemplate.py")

StreamIdBufferTemplate(
    "BwtAddressStreamSink",
    "HbmBwtAddressStreamSink",
    "UncompressedBwtEntryStreamSource",
    "HbmBwtEntryStreamSource",
)

Inc("entities/ActionControl.py")
Inc("entities/CtrlRegDemux.py")
Inc("entities/AcceleratedBwaMemMainController.py")
Inc("entities/BwtRequestController.py")

Inc("entities/AggregatedMonitorCountersBram.py")

# HLS Components
Inc("entities/hls/InitBwt.py")
Inc("entities/hls/ResultsToHostManager.py")
Inc("entities/hls/SmemTaskScheduler.py")
Inc("entities/hls/StreamMonitorAggregator.py")

# Complex Components
Inc("entities/wrapped/HbmInterface.py")
Inc("entities/wrapped/SmemCore.py")
Inc("entities/wrapped/StreamCrossbar.py")

with Ent(
    "action_wrapper",
    Generic("NumKernels", T("Integer")),
    x_templates={"generic/ext_wrapper.vhd": "action_wrapper.vhd"},
    *ocaccel.get_ports(),
):
    Ins(
        f"AxiConverter{ocaccel.thost.name}ToHlsHmem",
        f"axi_converter_{ocaccel.thost.name}_to_hmem",
        MapPort("axiIn", S("hmem")),
        MapPort("axiOut", S("hls_hmem")),
    )

    Ins(
        "MultiplexedAxiRwPortHlsHmem_3",
        "multiplexed_axi_rw_port_hlshmem_3",
        MapPort("sys", S("sys")),
        MapPort("axi_in", S("hls_hmem")),
        MapPort("axi_out_0", S("hls_hmem_init_bwt")),
        MapPort("axi_out_1", S("hls_hmem_smem_task_scheduler")),
        MapPort("axi_out_2", S("hls_hmem_results_to_host_manager")),
    )

    Ins(
        f"AxiPipelineStageAxiCtrl",
        f"pipeline_stage_axi_ctrl",
        MapPort("sys", S("sys")),
        MapPort("axiIn", S("ctrl_pipelined")),
        MapPort("axiOut", S(f"ctrl")),
    )

    Ins(
        "CtrlRegDemux",
        "ctrl_reg_demux",
        # See https://opencapi.github.io/oc-accel-doc/deep-dive/registers/, Section HLS Design
        # ActionControl receives register range 0x00 to 0x1C, controlling start and stop signals of action
        # AcceleratedBwaMemMainController receieces signals starting from 0x110
        # Registers 0x100 to 0x10C are ignored
        MapGeneric(
            "Ports",
            LitV(
                {"offset": 0x0, "count": 8},
                {"offset": int(0x110 / 4), "count": 24},
                {
                    "offset": int(0x200 / 4),
                    "count": NUM_STREAM_MONITORS * 3 * 2,
                    # Each Monitor has 3 counters of 48 bits, rounded up to 64 bits, split into two 32 bits
                },
            ),
        ),
        MapPort("sys", S("sys")),
        MapPort("ctrl", S("ctrl_pipelined")),
        MapPort(
            "regPorts",
            SV(
                "regPortAction",
                "regPortMainController",
                "regPortAggregatedMonitorCounters",
            ),
        ),
    )

    Ins(
        "AcceleratedBwaMemMainController",
        "accelerated_bwa_mem_main_controller",
        MapGeneric("NumInitSignals", Lit(1)),
        MapGeneric("NumMainSignals", Lit(3 + 3 * NUM_SMEM_CORES)),
        MapPort("sys", S("sys")),
        MapPort("start", S("mainStart")),
        MapPort("ready", S("mainControllerReady")),
        MapPort("reset_counters", S("reset_counters")),
        MapPort("reg", S("regPortMainController")),
        MapPort("bwt_addr", S("bwt_addr")),
        MapPort("runtime_status_control_addr", S("runtime_status_control_addr")),
        MapPort("bwt_primary", S("bwt_primary")),
        MapPort("bwt_L2", S("bwt_L2")),
        MapPort("bwt_size", S("bwt_size")),
        MapPort("split_width", S("split_width")),
        MapPort("split_len", S("split_len")),
        MapPort("min_seed_len", S("min_seed_len")),
        MapPort("ctrl_hs_init", SV("ctrl_hs_init_bwt")),
        MapPort(
            "ctrl_hs_main",
            SV(
                "ctrl_hs_results_to_host_manager",
                "ctrl_hs_smem_task_scheduler",
                "ctrl_hs_stream_monitor_aggregator",
                *itertools.chain(
                    *list(
                        (
                            f"ctrl_hs_smem_task_processor_{i}",
                            f"ctrl_hs_bwt_extend_processor_{i}",
                            f"ctrl_hs_task_completion_manager_{i}",
                        )
                        for i in range(NUM_SMEM_CORES)
                    )
                ),
            ),
        ),
    )

    Ins(
        "ActionControl",
        "action_control",
        MapGeneric("ReadyCount", Lit(1)),
        MapGeneric("ActionType", Lit(0x0ACCE701)),
        MapGeneric("ActionRev", Lit(0x00000004)),
        MapPort("sys", S("sys")),
        MapPort("intr", S("intr")),
        MapPort("reg", S("regPortAction")),
        MapPort("start", S("mainStart")),
        MapPort("ready", SV("mainControllerReady")),
    )

    for i in range(ocaccel.AxiHbmCount):
        Ins(
            "HbmInterface",
            f"hbm_interface_{i}",
            MapPort("sys", S("sys")),
            MapPort("hbm", S(f"hbm{i}")),
            MapPort("axi_hbm_rd", S(f"axi_hbm_rd_{i}")),
            MapPort("hls_hbm_write_only", S(f"hls_hbm_init_bwt_{i}")),
        )

    Ins(
        "init_bwt",
        "init_bwt",
        MapPort("sys", S("sys")),
        MapPort("ctrl_hs", S("ctrl_hs_init_bwt")),
        MapPort("bwt_host_address", S("bwt_addr")),
        MapPort("bwt_size", S("bwt_size")),
        MapPort("m_axi_host_mem", S("hls_hmem_init_bwt")),
        *(
            MapPort(f"m_axi_card_hbm_{i}", S(f"hls_hbm_init_bwt_{i}"))
            for i in range(ocaccel.AxiHbmCount)
        ),
    )

    Ins(
        "SequencesMemWriteDistributor",
        "sequences_mem_write_distributor",
        MapGeneric("NumOutputSignals", Lit(NUM_SMEM_CORE_GROUPS)),
        MapPort("sys", S("sys")),
        MapPort(
            "sequenceWrs",
            SV(
                *(
                    f"sequence_distributed_wr_group_{i}"
                    for i in range(NUM_SMEM_CORE_GROUPS)
                )
            ),
        ),
        MapPort("sequenceWr", S("sequence_wr")),
    )

    for i in range(NUM_SMEM_CORE_GROUPS):
        numMemPorts = min(
            NUM_SMEM_CORES_PER_CORE_GROUP,
            NUM_SMEM_CORES - (NUM_SMEM_CORES_PER_CORE_GROUP * i),
        )

        Ins(
            "MemoryReadBusArbiter",
            f"sequence_read_bus_arbiter_group_{i}",
            MapGeneric("NumBusPorts", Lit(numMemPorts)),
            MapGeneric("MemoryLatency", Lit(5)),  # 2 internally, 3 by sequence buffer
            MapPort("sys", S("sys")),
            MapPort(
                "sequenceRdBusses",
                SV(
                    *(
                        f"sequence_rd_bus_{i}"
                        for i in range(
                            i * NUM_SMEM_CORES_PER_CORE_GROUP,
                            i * NUM_SMEM_CORES_PER_CORE_GROUP + numMemPorts,
                        )
                    )
                ),
            ),
            MapPort("sequenceRd", S(f"sequence_rd_group_{i}")),
        )

        Ins(
            "SequenceBufferURAM",
            f"sequence_buffer_uram_group_{i}",
            MapPort("sys", S("sys")),
            MapPort("sequenceRd", S(f"sequence_rd_group_{i}")),
            MapPort("sequenceWr", S(f"sequence_distributed_wr_group_{i}")),
        )

    Ins(
        "RegPortToMemPortAggregatedMonitorMem",
        "reg_port_to_mem_port_aggregated_monitor_mem",
        MapGeneric("MemoryLatency", Lit(2)),
        MapPort("sys", S("sys")),
        MapPort("regPort", S("regPortAggregatedMonitorCounters")),
        MapPort("memPort", S("aggregated_monitor_counters_mem")),
    )

    Ins(
        "AggregatedMonitorCountersBram",
        "aggregated_monitor_counters_bram",
        MapGeneric("AddPipelineStages", Lit(0)),
        MapGeneric("LatencyB", Lit(1)),
        MapPort("sys", S("sys")),
        MapPort("memPortWr", S("aggregated_monitor_counters_mem_wr")),
        MapPort("memPort", S("aggregated_monitor_counters_mem")),
    )

    Ins(
        "stream_monitor_aggregator",
        "stream_monitor_aggregator",
        MapPort("sys", S("sys")),
        MapPort("ctrl_hs", S("ctrl_hs_stream_monitor_aggregator")),
        MapPort("aggregated_monitor_counters", S("aggregated_monitor_counters_mem_wr")),
        *(
            MapPort(f"monitor_channel_{i}", S(channelName))
            for i, channelName in enumerate(streamMonitorChannelNames)
        ),
        MapPort(
            "termination_signal_stream",
            S(f"termination_signal_stream_sink_{3 * NUM_SMEM_CORES}"),
        ),
    )

    Ins(
        "smem_task_scheduler",
        "smem_task_scheduler",
        MapPort("sys", S("sys")),
        MapPort("ctrl_hs", S("ctrl_hs_smem_task_scheduler")),
        MapPort("m_axi_host_mem", S("hls_hmem_smem_task_scheduler")),
        MapPort("runtime_status_control_addr", S("runtime_status_control_addr")),
        MapPort("sequences", S("sequence_wr")),
        *MapHlsPorts("task_streams", "task_stream_source", NUM_SMEM_CORES),
        *MapHlsPorts(
            "termination_signal_streams",
            "termination_signal_stream_source",
            NUM_TERMINATION_SIGNAL_STREAMS,
        ),
    )

    createStreamBufferInstances(
        "TaskStream",
        "task_stream",
        NUM_SMEM_CORES,
        monitorPosition=MonitorPosition.BOTH,
    )

    createStreamBufferInstances(
        "TerminationSignalStream",
        "termination_signal_stream",
        NUM_TERMINATION_SIGNAL_STREAMS,
        FIFOLogDepth=1,
    )

    createStreamBufferInstances(
        "FreedResultBufferStream",
        "freed_result_buffer_stream",
        NUM_TERMINATION_SIGNAL_STREAMS,
        monitorPosition=MonitorPosition.BOTH,
    )

    createStreamBufferInstances(
        "FilledResultBufferStream",
        "filled_result_buffer_stream",
        NUM_TERMINATION_SIGNAL_STREAMS,
        monitorPosition=MonitorPosition.BOTH,
    )

    Ins(
        "results_to_host_manager",
        "results_to_host_manager",
        MapPort("sys", S("sys")),
        MapPort("ctrl_hs", S("ctrl_hs_results_to_host_manager")),
        MapPort("m_axi_host_mem", S("hls_hmem_results_to_host_manager")),
        MapPort("runtime_status_control_addr", S("runtime_status_control_addr")),
        *MapHlsPorts("result_buffers", "result_buffer_mem_rd", NUM_SMEM_CORES),
        *MapHlsPorts(
            "freed_result_buffer_streams",
            "freed_result_buffer_stream_source",
            NUM_SMEM_CORES,
        ),
        *MapHlsPorts(
            "filled_result_buffer_streams",
            "filled_result_buffer_stream_sink",
            NUM_SMEM_CORES,
        ),
        MapPort(
            "termination_signal_stream",
            S(f"termination_signal_stream_sink_{3 * NUM_SMEM_CORES + 1}"),
        ),
    )

    for i in range(NUM_SMEM_CORES):
        Ins(
            "SmemCore",
            f"smem_core_{i}",
            MapPort("sys", S("sys")),
            MapPort(
                "ctrl_hs_smem_task_processor", S(f"ctrl_hs_smem_task_processor_{i}")
            ),
            MapPort(
                "ctrl_hs_bwt_extend_processor", S(f"ctrl_hs_bwt_extend_processor_{i}")
            ),
            MapPort(
                "ctrl_hs_task_completion_manager",
                S(f"ctrl_hs_task_completion_manager_{i}"),
            ),
            MapPort("bwt_primary", S("bwt_primary")),
            MapPort("bwt_L2", S("bwt_L2")),
            MapPort("split_width", S("split_width")),
            MapPort("split_len", S("split_len")),
            MapPort("min_seed_len", S("min_seed_len")),
            MapPort("task_stream_sink", S(f"task_stream_sink_{i}")),
            MapPort("sequence_rd_bus", S(f"sequence_rd_bus_{i}")),
            MapPort("result_buffer_mem_rd", S(f"result_buffer_mem_rd_{i}")),
            MapPort(
                "req_bwt_position_stream_source",
                S(f"hls_req_bwt_position_stream_source_{i}"),
            ),
            MapPort(
                "ret_bwt_entry_stream_sink", S(f"hls_ret_bwt_entry_stream_sink_{i}")
            ),
            MapPort(
                "freed_result_buffer_stream_sink",
                S(f"freed_result_buffer_stream_sink_{i}"),
            ),
            MapPort(
                "filled_result_buffer_stream_source",
                S(f"filled_result_buffer_stream_source_{i}"),
            ),
            MapPort(
                "termination_signal_stream_sink_smem_task_processor",
                S(f"termination_signal_stream_sink_{3 * i}"),
            ),
            MapPort(
                "termination_signal_stream_sink_bwt_extend_processor",
                S(f"termination_signal_stream_sink_{3 * i + 1}"),
            ),
            MapPort(
                "termination_signal_stream_sink_task_completion_manager",
                S(f"termination_signal_stream_sink_{3 * i + 2}"),
            ),
        )

    createStreamBufferInstances(
        "HlsBwtPositionStream",
        "hls_req_bwt_position_stream",
        NUM_SMEM_CORES,
        FIFOLogDepth=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        monitorPosition=MonitorPosition.BOTH,
    )
    createStreamBufferInstances(
        "HlsBwtEntryStream",
        "hls_ret_bwt_entry_stream",
        NUM_SMEM_CORES,
        monitorPosition=MonitorPosition.BOTH,
    )

    bwtRequestProcessorHbmPortSignals = []
    if GLOBAL_ADDRESSING and HBM_1ST_LAYER_CROSSBAR and IMPLEMENT_FOR_REAL_HBM:
        # When global addressing with crossbar the hbm, the hbm slot have to be reordered to prevent
        # (slow) lateral access through the internal crossbar of the hbm
        for i in range(ocaccel.AxiHbmCount):
            mappedIndex = (16 if i >= 16 else 0) + (4 * (i % 4)) + int((i % 16) / 4)
            bwtRequestProcessorHbmPortSignals.append(f"axi_hbm_rd_{mappedIndex}")
    else:
        for i in range(ocaccel.AxiHbmCount):
            bwtRequestProcessorHbmPortSignals.append(f"axi_hbm_rd_{i}")

    if HBM_1ST_LAYER_CROSSBAR:
        Ins(
            "StreamCrossbar",
            "stream_crossbar",
            MapPort("sys", S("sys")),
            *MapHlsPorts(
                "req_unrouted", "hls_req_bwt_position_stream_sink", NUM_SMEM_CORES
            ),
            *MapHlsPorts(
                "req_routed", "req_routed_bwt_position_stream_sink", NUM_HBM_STREAMS
            ),
            *MapHlsPorts(
                "ret_unrouted", "ret_unrouted_bwt_entry_stream_source", NUM_HBM_STREAMS
            ),
            *MapHlsPorts(
                "ret_routed", "hls_ret_bwt_entry_stream_source", NUM_SMEM_CORES
            ),
        )

    for i in range(NUM_HBM_STREAMS):
        Ins(
            "BwtEntryCompressor",
            f"bwt_entry_compressor_{i}",
            MapPort("sys", S("sys")),
            MapPort(
                "reqStreamMaster",
                S(
                    f"req_routed_bwt_position_stream_sink_{i}"
                    if HBM_1ST_LAYER_CROSSBAR
                    else f"hls_req_bwt_position_stream_sink_{i}"
                ),
            ),
            MapPort("reqStreamSlave", S(f"req_bwt_address_stream_sink_{i}")),
            MapPort(
                "retStreamMaster",
                S(
                    f"ret_unrouted_bwt_entry_stream_source_{i}"
                    if HBM_1ST_LAYER_CROSSBAR
                    else f"hls_ret_bwt_entry_stream_source_{i}"
                ),
            ),
            MapPort(
                "retStreamSlave", S(f"ret_uncompressed_bwt_entry_stream_source_{i}")
            ),
        )

        Ins(
            "StreamIdBufferBwtAddressStreamSinkUncompressedBwtEntryStreamSource",
            f"bwt_stream_id_buffer_{i}",
            MapPort("sys", S("sys")),
            MapPort("reqStreamMaster", S(f"req_bwt_address_stream_sink_{i}")),
            MapPort("reqStreamSlave", S(f"hbm_req_bwt_address_stream_sink_{i}")),
            MapPort(
                "retStreamMaster", S(f"ret_uncompressed_bwt_entry_stream_source_{i}")
            ),
            MapPort("retStreamSlave", S(f"hbm_ret_bwt_entry_stream_source_{i}")),
        )

    Ins(
        "BwtRequestController",
        "bwt_request_controller",
        MapGeneric("StreamCount", Lit(NUM_HBM_STREAMS)),
        MapGeneric("HbmPortCount", Lit(32)),
        MapGeneric("HbmCacheLinesPerBwtEntry", Lit(HBM_CACHE_LINES_PER_BWT_ENTRY)),
        MapGeneric("RequestAddrWidth", Lit(BWT_REQUEST_LOCAL_ADDR_WIDTH)),
        MapPort("sys", S("sys")),
        MapPort(
            "hbm_req_bwt_address_streams",
            SV(
                *(
                    f"hbm_req_bwt_address_stream_sink_{i}"
                    for i in range(NUM_HBM_STREAMS)
                )
            ),
        ),
        MapPort(
            "hbm_ret_bwt_entry_streams",
            SV(
                *(
                    f"hbm_ret_bwt_entry_stream_source_{i}"
                    for i in range(NUM_HBM_STREAMS)
                )
            ),
        ),
        MapPort("hbm", SV(*bwtRequestProcessorHbmPortSignals)),
    )
