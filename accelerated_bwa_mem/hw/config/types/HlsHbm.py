Inc("../include/ocaccel.py")

with Pkg("hls_hbm_types", x_templates={"generic/package.vhd": "pkg/hls_hbm_types.vhd"}):
    AxiType(
        "HlsHbm",
        ocaccel.AxiHbm_DataBytes,
        64,
        id_bits=1,
        has_attr=True,
        aruser_bits=1,
        awuser_bits=1,
        ruser_bits=1,
        wuser_bits=1,
        buser_bits=1,
        add_split=True,
    )
