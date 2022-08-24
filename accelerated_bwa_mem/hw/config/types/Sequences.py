SEQUENCE_BUFFER_DATA_BITS = 96
SEQUENCE_BUFFER_ADDR_BITS = 16

with Pkg("sequences_types", x_templates={"generic/package.vhd": "pkg/sequences_types.vhd"}):
    TypeHlsBus("HlsSequenceRdBus", data_bits=SEQUENCE_BUFFER_DATA_BITS)

    TypeHlsMemory(
        "HlsSequencesMem",
        data_bits=SEQUENCE_BUFFER_DATA_BITS,
        addr_bits=SEQUENCE_BUFFER_ADDR_BITS,
    )

    TypeHlsMemory(
        "HlsSequencesMemWr",
        data_bits=SEQUENCE_BUFFER_DATA_BITS,
        addr_bits=SEQUENCE_BUFFER_ADDR_BITS,
        has_rd=False,
        has_wr=True,
    )

    TypeHlsMemory(
        "HlsSequencesMemRd",
        data_bits=SEQUENCE_BUFFER_DATA_BITS,
        addr_bits=SEQUENCE_BUFFER_ADDR_BITS,
        has_rd=True,
        has_wr=False,
    )
