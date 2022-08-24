Inc("../../utils.py")

def ReqStreamCrossbarTemplate(unroutedStreamTypeName, routedStreamTypeName):
    Ent(
        f"ReqStreamCrossbar{unroutedStreamTypeName}{routedStreamTypeName}",
        Generic("NumInStreamPorts", T("Integer")),
        Generic("NumOutStreamPorts", T("Integer")),
        Generic("SelectorBitOffset", T("Integer")),
        Generic("SelectorBitWidth", T("Integer")),
        Generic("FIFOLogDepth", T("Integer")),
        Generic("ModifyId", T("Integer")), # 0: idUnchanged, 1: removeSelector, 2: addSourceIndexToFront        
        PortI("sys", T("Sys")),
        PortM("unrouted", T(f"{unroutedStreamTypeName}"), vector="NumInStreamPorts"),
        PortS("routed", T(f"{routedStreamTypeName}"), vector="NumOutStreamPorts"),
        x_templates={
            "components/StreamCrossbar.vhd": f"req_stream_crossbar_{unroutedStreamTypeName}{routedStreamTypeName}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_pm_streamMasters": "unrouted",
                "x_ps_streamSlaves": "routed",
            }
        ),
    )

def RetStreamCrossbarTemplate(unroutedStreamTypeName, routedStreamTypeName):
    Ent(
        f"RetStreamCrossbar{unroutedStreamTypeName}{routedStreamTypeName}",
        Generic("NumInStreamPorts", T("Integer")),
        Generic("NumOutStreamPorts", T("Integer")),
        Generic("SelectorBitOffset", T("Integer")),
        Generic("SelectorBitWidth", T("Integer")),
        Generic("FIFOLogDepth", T("Integer")),   
        Generic("ModifyId", T("Integer")),     
        PortI("sys", T("Sys")),
        PortS("unrouted", T(f"{unroutedStreamTypeName}"), vector="NumInStreamPorts"),
        PortM("routed", T(f"{routedStreamTypeName}"), vector="NumOutStreamPorts"),
        x_templates={
            "components/StreamCrossbar.vhd": f"ret_stream_crossbar_{unroutedStreamTypeName}{routedStreamTypeName}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_pm_streamMasters": "routed",
                "x_ps_streamSlaves": "unrouted",
            }
        ),
    )
