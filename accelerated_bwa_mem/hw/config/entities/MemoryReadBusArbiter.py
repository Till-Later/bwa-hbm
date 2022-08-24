Inc("../utils.py")
Inc("../types/Sequences.py")

Ent(
    "MemoryReadBusArbiter",
    Generic("NumBusPorts", T("Integer")),
    Generic("MemoryLatency", T("Integer")),
    PortI("sys", T("Sys")),
    PortS("sequenceRdBusses", T("HlsSequenceRdBus"), vector="NumBusPorts"),
    PortM("sequenceRd", T("HlsSequencesMemRd")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_busPorts": "sequenceRdBusses",
            "x_pm_memRd": "sequenceRd",
        }
    ),
    x_templates={"generic/memory_read_bus_arbiter.vhd": "memory_read_bus_arbiter.vhd"},
)