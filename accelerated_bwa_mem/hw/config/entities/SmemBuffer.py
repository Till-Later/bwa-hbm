Inc("../types/Smem.py")

Ent(
    "SmemBuffer",
    Generic("NumStreamPorts", T("Integer")),
    PortI("sys", T("Sys")),
    PortS("reqStreams", T("SmemRequestStreamSource"), vector="NumStreamPorts"),
    PortS("respStreams", T("SmemResponseStreamSink"), vector="NumStreamPorts"),
    PortS("smemBufferMem", T("SmemMem")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_req_source": "reqStreams",
            "x_ps_resp_sink": "respStreams",
            "x_ps_memPort": "smemBufferMem",
        }
    ),
    x_templates={"specific/smem_buffer.vhd": "smem_buffer.vhd"},
)