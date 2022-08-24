Inc("../utils.py")
Inc("../globals.py")

Inc("../types/streams/BwtStream.py")

Ent(
    f"BwtEntryCompressor",
    PortI("sys", T("Sys")),
    PortM(
        "reqStreamMaster",
        T(
            "RoutedBwtPositionStreamSink"
            if HBM_1ST_LAYER_CROSSBAR
            else "HlsBwtPositionStreamSink"
        ),
    ),
    PortS("reqStreamSlave", T(f"BwtAddressStreamSink")),
    PortM(
        "retStreamMaster",
        T(
            "UnroutedBwtEntryStreamSource"
            if HBM_1ST_LAYER_CROSSBAR
            else "HlsBwtEntryStreamSource"
        ),
    ),
    PortS("retStreamSlave", T(f"UncompressedBwtEntryStreamSource")),
    x_templates={"specific/bwt_entry_compressor.vhd": f"bwt_entry_compressor.vhd"},
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_pm_reqStreamMaster": "reqStreamMaster",
            "x_ps_reqStreamSlave": "reqStreamSlave",
            "x_pm_retStreamMaster": "retStreamMaster",
            "x_ps_retStreamSlave": "retStreamSlave",
        }
    ),
)
