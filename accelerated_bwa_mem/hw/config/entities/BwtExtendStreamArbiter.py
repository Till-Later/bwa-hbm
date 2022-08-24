Inc("../utils.py")
Inc("../types/streams/BwtExtendStream.py")

Ent(
    "BwtExtendStreamArbiter",
    Generic("StreamCount", T("Integer")),
    Generic("LogRequestFifoDepth", T("Integer")),
    Generic("PipelineIndexWidth", T("Integer")),
    PortI("sys", T("Sys")),
    PortS("req_bwt_extend_streams", T("BwtExtendStreamSource"), vector="StreamCount"),
    PortS("req_bwt_extend_stream", T("BwtExtendStreamSink")),
    PortS("ret_bwt_extend_stream", T("BwtExtendStreamSource")),
    PortS("ret_bwt_extend_streams", T("BwtExtendStreamSink"), vector="StreamCount"),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_req_sources": "req_bwt_extend_streams",
            "x_ps_req_sink": "req_bwt_extend_stream",
            "x_ps_ret_source": "ret_bwt_extend_stream",
            "x_ps_ret_sinks": "ret_bwt_extend_streams",
        }
    ),
    x_templates={
        "specific/bwt_extend_stream_arbiter.vhd": "bwt_extend_stream_arbiter.vhd"
    },
)
