from nis import match
from unittest import case

Inc("../../include/ocaccel.py")
Inc("../../globals.py")

Inc("../hls/HlsPort.py")
Inc("../templates/StreamCrossbarTemplate.py")
Inc("../../types/streams/BwtStream.py")

if HBM_2ND_LAYER_CROSSBAR:
    ReqStreamCrossbarTemplate(
        "HlsBwtPositionStreamSink", "PartiallyRoutedBwtPositionStreamSink"
    )
    ReqStreamCrossbarTemplate(
        "PartiallyRoutedBwtPositionStreamSink", "RoutedBwtPositionStreamSink"
    )

    RetStreamCrossbarTemplate(
        "UnroutedBwtEntryStreamSource", "PartiallyUnroutedBwtEntryStreamSource"
    )
    RetStreamCrossbarTemplate(
        "PartiallyUnroutedBwtEntryStreamSource", "HlsBwtEntryStreamSource"
    )
else:
    ReqStreamCrossbarTemplate("HlsBwtPositionStreamSink", "RoutedBwtPositionStreamSink")
    RetStreamCrossbarTemplate("UnroutedBwtEntryStreamSource", "HlsBwtEntryStreamSource")


def secondLayerCrossbarNumInPorts(crossbarIndex):
    return {0: (0, 0), 4: (1, 0), 8: (2, 0), 12: (2, 1)}[NUM_SMEM_CORES % 16][
        0 if crossbarIndex < 4 else 1
    ] + (2 if NUM_SMEM_CORES >= 16 else 0)


def secondLayerPortToFirstLayerIndex(secondLayerCrossbarIndex, secondLayerPortIndex):
    firstLayerPortIndex = secondLayerCrossbarIndex % 4
    firstLayerCrossbarIndex = (
        4 * int(secondLayerPortIndex / 2)
        + 2 * int(secondLayerCrossbarIndex / 4)
        + (secondLayerPortIndex % 2)
    )

    return 4 * firstLayerCrossbarIndex + firstLayerPortIndex


with Ent(
    "StreamCrossbar",
    PortI("sys", ocaccel.tsys, x_wrapname="ap"),
    *HlsPortsM(
        "req_unrouted", T(f"HlsBwtPositionStreamSink"), NUM_SMEM_CORES, suffix=""
    ),
    *HlsPortsS(
        "req_routed", T(f"RoutedBwtPositionStreamSink"), NUM_HBM_STREAMS, suffix=""
    ),
    *HlsPortsS(
        "ret_unrouted", T(f"UnroutedBwtEntryStreamSource"), NUM_HBM_STREAMS, suffix=""
    ),
    *HlsPortsM("ret_routed", T(f"HlsBwtEntryStreamSource"), NUM_SMEM_CORES, suffix=""),
    x_templates={"generic/entity.vhd": "stream_crossbar.vhd"},
):
    if HBM_2ND_LAYER_CROSSBAR:
        first_layer_req_routed_stream_name = "req_partially_routed"
        first_layer_ret_unrouted_stream_name = "ret_partially_routed"
    else:
        first_layer_req_routed_stream_name = "req_routed"
        first_layer_ret_unrouted_stream_name = "ret_unrouted"

    for crossbar_index in range(int(NUM_SMEM_CORES / 4)):
        Ins(
            "ReqStreamCrossbarHlsBwtPositionStreamSinkPartiallyRoutedBwtPositionStreamSink"
            if HBM_2ND_LAYER_CROSSBAR
            else "ReqStreamCrossbarHlsBwtPositionStreamSinkRoutedBwtPositionStreamSink",
            f"req_stream_crossbar_first_layer_{crossbar_index}",
            MapGeneric(
                "SelectorBitOffset",
                Lit(
                    (2 if HBM_2ND_LAYER_CROSSBAR else 0)
                    + BWT_REQUEST_LOCAL_ADDR_WIDTH + (2 * 8)
                ),
            ),
            MapGeneric("SelectorBitWidth", Lit(2)),
            MapGeneric("FIFOLogDepth", Lit(4)),
            MapGeneric("ModifyId", Lit(2)),
            MapPort("sys", S("sys")),
            MapPort(
                "unrouted",
                SV(*(f"req_unrouted_{4 * crossbar_index + i}" for i in range(4))),
            ),
            MapPort(
                "routed",
                SV(
                    *(
                        f"{first_layer_req_routed_stream_name}_{4 * crossbar_index + i}"
                        for i in range(4)
                    )
                ),
            ),
        )

        Ins(
            "RetStreamCrossbarPartiallyUnroutedBwtEntryStreamSourceHlsBwtEntryStreamSource"
            if HBM_2ND_LAYER_CROSSBAR
            else "RetStreamCrossbarUnroutedBwtEntryStreamSourceHlsBwtEntryStreamSource",
            f"ret_stream_crossbar_first_layer_{crossbar_index}",
            MapGeneric("SelectorBitOffset", Lit(200 + SMEM_KERNEL_PIPELINE_LOG2_DEPTH)),
            MapGeneric("SelectorBitWidth", Lit(2)),
            MapGeneric("FIFOLogDepth", Lit(DEFAULT_STREAM_BUFFER_LOG_DEPTH)),
            MapGeneric("ModifyId", Lit(1)),
            MapPort("sys", S("sys")),
            MapPort(
                "unrouted",
                SV(
                    *(
                        f"{first_layer_ret_unrouted_stream_name}_{4 * crossbar_index +  i}"
                        for i in range(4)
                    )
                ),
            ),
            MapPort(
                "routed",
                SV(*(f"ret_routed_{4 * crossbar_index + i}" for i in range(4))),
            ),
        )

    if HBM_2ND_LAYER_CROSSBAR:
        for crossbar_index in range(int(NUM_HBM_STREAMS / 4)):
            Ins(
                "ReqStreamCrossbarPartiallyRoutedBwtPositionStreamSinkRoutedBwtPositionStreamSink",
                f"req_stream_crossbar_second_layer_{crossbar_index}",
                MapGeneric(
                    "SelectorBitOffset", Lit(BWT_REQUEST_LOCAL_ADDR_WIDTH + (2 * 8))
                ),
                MapGeneric("SelectorBitWidth", Lit(2)),
                MapGeneric("FIFOLogDepth", Lit(4)),
                MapGeneric("ModifyId", Lit(2)),
                MapPort("sys", S("sys")),
                MapPort(
                    "unrouted",
                    SV(
                        *(
                            f"req_partially_routed_{secondLayerPortToFirstLayerIndex(crossbar_index, port_index)}"
                            for port_index in range(
                                secondLayerCrossbarNumInPorts(crossbar_index)
                            )
                        )
                    ),
                ),
                MapPort(
                    "routed",
                    SV(*(f"req_routed_{4 * crossbar_index + i}" for i in range(4))),
                ),
            )

            Ins(
                "RetStreamCrossbarUnroutedBwtEntryStreamSourcePartiallyUnroutedBwtEntryStreamSource",
                f"ret_stream_crossbar_second_layer_{crossbar_index}",
                MapGeneric(
                    "SelectorBitOffset", Lit(2 + 200 + SMEM_KERNEL_PIPELINE_LOG2_DEPTH)
                ),
                MapGeneric("SelectorBitWidth", Lit(2)),
                MapGeneric("FIFOLogDepth", Lit(DEFAULT_STREAM_BUFFER_LOG_DEPTH)),
                MapGeneric("ModifyId", Lit(1)),
                MapPort("sys", S("sys")),
                MapPort(
                    "unrouted",
                    SV(*(f"ret_unrouted_{4 * crossbar_index +  i}" for i in range(4))),
                ),
                MapPort(
                    "routed",
                    SV(
                        *(
                            f"ret_partially_routed_{secondLayerPortToFirstLayerIndex(crossbar_index, port_index)}"
                            for port_index in range(
                                secondLayerCrossbarNumInPorts(crossbar_index)
                            )
                        )
                    ),
                ),
            )
