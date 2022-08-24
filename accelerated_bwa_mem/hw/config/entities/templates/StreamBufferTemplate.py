Inc("../../utils.py")

def StreamBufferTemplate(streamTypeName):
    Ent(
        f"HlsStreamBuffer{streamTypeName}",
        Generic("FIFOLogDepth", T("Integer")),
        PortI("sys", T("Sys")),
        PortS("source", T(f"{streamTypeName}Source")),
        PortS("sink", T(f"{streamTypeName}Sink")),
        x_templates={
            "generic/hls_stream_buffer.vhd": f"hls_stream_buffer_{streamTypeName}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_ps_source": "source",
                "x_ps_sink": "sink",
            }
        ),
    )
