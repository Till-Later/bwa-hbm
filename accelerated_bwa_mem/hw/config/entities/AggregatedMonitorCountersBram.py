Inc("../utils.py")
Inc("../types/Monitor.py")

Ent(
    "AggregatedMonitorCountersBram",
    PortI("sys", T("Sys")),
    Generic("AddPipelineStages", T("Integer")),
    Generic("LatencyB", T("Integer")),
    PortS("memPortWr", T("AggregatedMonitorMemWr")),
    PortS("memPort", T("AggregatedMonitorMem")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_memPortA": "memPortWr",
            "x_ps_memPortB": "memPort",
        }
    ),
    x_templates={"generic/tdp_bram.vhd": "aggregated_monitor_counters_bram.vhd"},
)