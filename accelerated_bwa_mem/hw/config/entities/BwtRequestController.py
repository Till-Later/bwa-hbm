Inc("../types/streams/BwtStream.py")

Ent(
    "BwtRequestController",
    Generic("StreamCount", T("Integer")),
    Generic("HbmPortCount", T("Integer")),
    Generic("HbmCacheLinesPerBwtEntry", T("Integer")),
    Generic("RequestAddrWidth", T("Integer")),
    PortI("sys", T("Sys")),
    PortM(
        "hbm_req_bwt_address_streams",
        T("HbmBwtAddressStreamSink"),
        vector="StreamCount"
    ),
    PortM(
        "hbm_ret_bwt_entry_streams", T("HbmBwtEntryStreamSource"), vector="StreamCount"
    ),
    PortM("hbm", T("AxiHbmRd"), vector="HbmPortCount"),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_pm_req_bwt_position_id_streams": "hbm_req_bwt_address_streams",
            "x_pm_ret_bwt_entry_id_streams": "hbm_ret_bwt_entry_streams",
        }
    ),
    x_templates={"specific/bwt_request_controller.vhd": "bwt_request_controller.vhd"},
)
