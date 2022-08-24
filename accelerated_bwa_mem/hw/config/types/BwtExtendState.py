Inc("../globals.py")

with Pkg("bwt_extend_state_types", x_templates={"generic/package.vhd": "pkg/bwt_extend_state_types.vhd"}):
    TypeHlsMemory(
        "BwtExtendStateMemWr",
        data_bits=140,
        addr_bits=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        has_rd=False,
        has_wr=True,
    )

    TypeHlsMemory(
        "BwtExtendStateMemRd",
        data_bits=140,
        addr_bits=SMEM_KERNEL_PIPELINE_LOG2_DEPTH,
        has_rd=True,
        has_wr=False,
    )