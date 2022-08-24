Inc("../globals.py")

with Pkg(
    "accelerator_result_buffer_types",
    x_templates={"generic/package.vhd": "pkg/accelerator_result_buffer_types.vhd"},
):
    TypeHlsFifo(
        "FreedResultBufferStreamSource",
        data_bits=ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES_BITS + 1,
        is_source=True,
        is_sink=False,
    )
    TypeHlsFifo(
        "FreedResultBufferStreamSink",
        data_bits=ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES_BITS + 1,
        is_source=False,
        is_sink=True,
    )

    TypeHlsFifo(
        "FilledResultBufferStreamSource",
        data_bits=ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES_BITS + 1 + 8,
        is_source=True,
        is_sink=False,
    )
    TypeHlsFifo(
        "FilledResultBufferStreamSink",
        data_bits=ACCELERATOR_RESULT_BUFFER_NUM_ENTRIES_BITS + 1 + 8,
        is_source=False,
        is_sink=True,
    )

    TypeHlsMemory(
        "AcceleratorResultBufferMemWr",
        data_bits=ACCELERATOR_RESULT_BUFFER_DATA_WIDTH,
        addr_bits=ACCELERATOR_RESULT_BUFFER_ADDR_WIDTH,
        has_rd=False,
        has_wr=True,
    )

    TypeHlsMemory(
        "AcceleratorResultBufferMemRd",
        data_bits=ACCELERATOR_RESULT_BUFFER_DATA_WIDTH,
        addr_bits=ACCELERATOR_RESULT_BUFFER_ADDR_WIDTH,
        has_rd=True,
        has_wr=False,
    )
