Inc("../globals.py")

with Pkg("smem_types", x_templates={"generic/package.vhd": "pkg/smem_types.vhd"}):
    TypeHlsFifo(
        "SmemRequestStreamSource",
        data_bits=SMEM_BUFFER_ADDR_WIDTH + SMEM_BUFFER_DATA_WIDTH + 2,
        is_source=True,
        is_sink=False,
    )
    TypeHlsFifo("SmemResponseStreamSink", data_bits=SMEM_BUFFER_DATA_WIDTH, is_source=False, is_sink=True)

    TypeHlsMemory("SmemMem", data_bits=SMEM_BUFFER_DATA_WIDTH, addr_bits=SMEM_BUFFER_ADDR_WIDTH)

    TypeHlsMemory(
        "SmemMemRd",
        data_bits=SMEM_BUFFER_DATA_WIDTH,
        addr_bits=SMEM_BUFFER_ADDR_WIDTH,
        has_rd=True,
        has_wr=False,
    )
