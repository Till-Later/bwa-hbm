Inc("../include/ocaccel.py")

with Pkg("hls_hmem_types", x_templates={"generic/package.vhd": "pkg/hls_hmem_types.vhd"}):
    AxiType(
        "HlsHmem",
        ocaccel.AxiHost_DataBytes,
        ocaccel.AxiHost_AddrBits,
        id_bits=1,
        has_attr=True,
        aruser_bits=1,
        awuser_bits=1,
        ruser_bits=1,
        wuser_bits=1,
        buser_bits=1,
        add_split=True,
    )
