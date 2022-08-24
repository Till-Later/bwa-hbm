Inc("../types/Sequences.py")

Ent(
    "SequenceBufferURAM",
    PortI("sys", T("Sys")),
    PortS("sequenceRd", T("HlsSequencesMemRd")),
    PortS("sequenceWr", T("HlsSequencesMemWr")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_sequenceRd": "sequenceRd",
            "x_ps_sequenceWr": "sequenceWr",
        }
    ),
    x_templates={"specific/sequence_buffer_uram.vhd": "sequence_buffer_uram.vhd"},
)
