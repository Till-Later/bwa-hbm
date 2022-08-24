Inc("../templates/AxiSplitterTemplate.py")
Inc("../templates/AxiConverterTemplate.py")
Inc("../templates/AxiNullSlaveTemplate.py")
Inc("../templates/AxiJoinerTemplate.py")

AxiSplitterTemplate("AxiHbm")
AxiJoinerTemplate("HlsHbm")
AxiConverterTemplate("AxiHbmWr", "HlsHbmWr")
AxiNullSlaveTemplate("HlsHbmRd")

with Ent(
    "HbmInterface",
    PortI("sys", ocaccel.tsys, x_wrapname="ap"),
    PortM("hbm", T("AxiHbm"), x_wrapname="hbm"),
    PortS("axi_hbm_rd", T("AxiHbmRd"), x_wrapname="axi_hbm_rd"),
    PortS("hls_hbm_write_only", T("HlsHbm"), x_wrapname="hls_hbm_write_only"),
    x_templates={"generic/entity.vhd": "hbm_interface.vhd"},
):
    Ins(
        "AxiSplitterAxiHbm",
        "axi_hbm_splitter",
        MapPort("sys", S("sys")),
        MapPort("axi", S("hbm")),
        MapPort("axiRd", S("axi_hbm_rd")),
        MapPort("axiWr", S("axi_hbm_wr")),
    )

    Ins(
        "AxiConverterAxiHbmWrToHlsHbmWr",
        "axi_converter_axi_hbm_wr_to_hls_hbm_wr",
        MapPort("axiIn", S("axi_hbm_wr")),
        MapPort("axiOut", S("hls_hbm_wr")),
    )

    Ins(
        "AxiNullSlaveHlsHbmRd",
        "axi_null_slave_hls_hbm_rd",
        MapPort("out", S("hls_hbm_rd_null")),
    )

    Ins(
        "AxiJoinerHlsHbm",
        "hls_hbm_joiner",
        MapPort("sys", S("sys")),
        MapPort("axi", S("hls_hbm_write_only")),
        MapPort("axiRd", S("hls_hbm_rd_null")),
        MapPort("axiWr", S("hls_hbm_wr")),
    )
