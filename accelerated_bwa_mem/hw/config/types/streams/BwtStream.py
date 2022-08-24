Inc("../../globals.py")

with Pkg("bwtStream", x_templates={"generic/package.vhd": "pkg/bwt_stream.vhd"}):
    # HlsBwt --HlsBwtPositionStreamSource--> StreamBuffer --HlsBwtPositionStreamSink--> [Crossbar --RoutedBwtPositionStreamSink-->]
    # EntryCompressor --BwtAddressStreamSink--> IdBuffer --HbmBwtAddressStreamSink--> BwtRequestController
    TypeHlsFifo(
        "HlsBwtPositionStreamSource",
        data_bits=BWT_REQUEST_GLOBAL_ADDR_WIDTH + 2 * 8,
        id_bits=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_source=True,
    )
    TypeHlsFifo(
        "HlsBwtPositionStreamSink",
        data_bits=BWT_REQUEST_GLOBAL_ADDR_WIDTH + 2 * 8,
        id_bits=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_sink=True,
    )
    TypeHlsFifo(
        "PartiallyRoutedBwtPositionStreamSink",
        data_bits=BWT_REQUEST_GLOBAL_ADDR_WIDTH + 2 * 8,
        id_bits=2 + SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_sink=True,
    )
    TypeHlsFifo(
        "RoutedBwtPositionStreamSink",
        data_bits=BWT_REQUEST_GLOBAL_ADDR_WIDTH + 2 * 8,
        id_bits=(4 if HBM_2ND_LAYER_CROSSBAR else 2) + SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_sink=True,
    )
    TypeHlsFifo(
        "BwtAddressStreamSink",
        data_bits=BWT_REQUEST_GLOBAL_ADDR_WIDTH,
        id_bits=(4 if HBM_2ND_LAYER_CROSSBAR else (2 if HBM_1ST_LAYER_CROSSBAR else 0))
        + SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_sink=True,
    )
    TypeHlsFifo(
        "HbmBwtAddressStreamSink",
        data_bits=BWT_REQUEST_GLOBAL_ADDR_WIDTH,
        id_bits=HBM_ID_WIDTH,
        is_sink=True,
    )

    # BwtRequestController --HbmBwtEntryStreamSource--> IdBuffer --UncompressedBwtEntryStreamSource--> EntryCompressor
    # [--UnroutedBwtEntryStreamSource--> Crossbar] --HlsBwtEntryStreamSource--> StreamBuffer --> HlsBwtEntryStreamSink
    TypeHlsFifo(
        "HbmBwtEntryStreamSource", data_bits=512, id_bits=HBM_ID_WIDTH, is_source=True
    )
    TypeHlsFifo(
        "UncompressedBwtEntryStreamSource",
        data_bits=512,
        id_bits=(4 if HBM_2ND_LAYER_CROSSBAR else (2 if HBM_1ST_LAYER_CROSSBAR else 0))
        + SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_source=True,
    )
    TypeHlsFifo(
        "UnroutedBwtEntryStreamSource",
        data_bits=200,
        id_bits=(4 if HBM_2ND_LAYER_CROSSBAR else 2) + SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_source=True,
    )
    TypeHlsFifo(
        "PartiallyUnroutedBwtEntryStreamSource",
        data_bits=200,
        id_bits=2 + SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_source=True,
    )
    TypeHlsFifo(
        "HlsBwtEntryStreamSource",
        data_bits=200,
        id_bits=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_source=True,
    )
    TypeHlsFifo(
        "HlsBwtEntryStreamSink",
        data_bits=200,
        id_bits=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        is_sink=True,
    )
