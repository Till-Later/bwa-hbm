Inc("../../types/Numeric.py")
Inc("../../types/streams/BwtExtendStream.py")
Inc("../../types/streams/BwtStream.py")
Inc("../../types/streams/TerminationSignalStream.py")
Inc("WrappedHlsEntity.py")
Inc("HlsPort.py")

WrappedHlsEntity(
    "bwt_extend_processor",
    HlsPortI("bwt_primary", T("u64"), suffix=""),
    HlsPortI("bwt_L2", T("u320")),
    HlsPortM("req_bwt_extend_stream", T("BwtExtendStreamSink")),
    HlsPortM("ret_bwt_extend_stream", T("BwtExtendStreamSource")),
    HlsPortM("req_bwt_position_stream", T("HlsBwtPositionStreamSource")),
    HlsPortM("ret_bwt_entry_stream", T("HlsBwtEntryStreamSink")),
    HlsPortM("termination_signal_stream", T("TerminationSignalStreamSink"), suffix="V"),
    HlsPortM("states_1", T("BwtExtendStateMemWr"), suffix="V"),
    HlsPortM("states_2", T("BwtExtendStateMemRd"), suffix="V"),
)
