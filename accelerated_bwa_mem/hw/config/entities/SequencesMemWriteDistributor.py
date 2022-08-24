Inc("../utils.py")
Inc("../types/Sequences.py")

Ent(
    "SequencesMemWriteDistributor",
    Generic("NumOutputSignals", T("Integer")),
    PortI("sys", T("Sys")),
    PortS("sequenceWr", T("HlsSequencesMem")),
    PortM("sequenceWrs", T("HlsSequencesMemWr"), vector="NumOutputSignals"),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_memWr": "sequenceWr",
            "x_pm_memWrs": "sequenceWrs",
        }
    ),
    x_templates={"generic/mem_write_distributor.vhd": "sequences_mem_write_distributor.vhd"},
)