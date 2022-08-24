Inc("../utils.py")
Inc("../types/BwtExtendState.py")

Ent(
    "BwtExtendStateBuffer",
    Generic("AddPipelineStages", T("Integer")),
    Generic("LatencyB", T("Integer")),
    PortI("sys", T("Sys")),
    PortS("memPortWr", T("BwtExtendStateMemWr")),
    PortS("memPortRd", T("BwtExtendStateMemRd")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_memPortA": "memPortWr",
            "x_ps_memPortB": "memPortRd",
        }
    ),
    x_templates={"generic/tdp_bram.vhd": "bwt_extend_state_bram.vhd"},
)