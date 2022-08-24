Inc("../utils.py")
Inc("../types/AcceleratorResults.py")

Ent(
    "AcceleratorResultBuffer",
    PortI("sys", T("Sys")),
    Generic("AddPipelineStages", T("Integer")),
    Generic("LatencyB", T("Integer")),
    PortS("memPortWr", T("AcceleratorResultBufferMemWr")),
    PortS("memPortRd", T("AcceleratorResultBufferMemRd")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_memPortA": "memPortWr",
            "x_ps_memPortB": "memPortRd",
        }
    ),
    x_templates={"generic/tdp_bram.vhd": "accelerator_result_buffer.vhd"},
)