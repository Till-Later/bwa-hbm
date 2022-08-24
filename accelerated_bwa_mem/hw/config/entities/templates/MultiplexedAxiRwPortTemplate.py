Inc("../../utils.py")

Inc("../../include/ocaccel.py")
Inc("AxiPipelineStageTemplate.py")
Inc("AxiSplitterTemplate.py")
Inc("AxiMultiplexerTemplate.py")
Inc("AxiJoinerTemplate.py")

def MultiplexedAxiRwPortTemplate(axiTypeName, count):
    AxiPipelineStageTemplate(axiTypeName)
    AxiSplitterTemplate(axiTypeName)
    AxiMultiplexerTemplate(axiTypeName, "Rd")
    AxiMultiplexerTemplate(axiTypeName, "Wr")
    AxiJoinerTemplate(axiTypeName)

    with Ent(
        f"MultiplexedAxiRwPort{axiTypeName}_{count}",
        PortI("sys", ocaccel.tsys, x_wrapname="ap"),
        PortM("axi_in", T(axiTypeName), x_wrapname="axi_in"),
        *(PortS(f"axi_out_{i}", T(axiTypeName), x_wrapname=f"axi_out_{i}") for i in range(count)),
        x_templates={"generic/entity.vhd": f"multiplexed_axi_rw_port_{axiTypeName}_{count}.vhd"},
    ):
        Ins(
            f"AxiPipelineStage{axiTypeName}",
            f"pipeline_stage_in",
            MapPort("sys", S("sys")),
            MapPort("axiIn", S("axi_in")),
            MapPort("axiOut", S("axi_in_pipelined")),
        )

        Ins(
            f"AxiSplitter{axiTypeName}",
            "splitter",
            MapPort("sys", S("sys")),
            MapPort("axi", S(f"axi_in_pipelined")),
            MapPort("axiRd", S(f"axi_rd")),
            MapPort("axiWr", S(f"axi_wr")),
        )

        Ins(
            f"AxiRdMultiplexer{axiTypeName}",
            "rd_multiplexer",
            MapGeneric("FIFOLogDepth", Lit(4)),
            MapPort("sys", S("sys")),
            MapPort("axiRd", S("axi_rd")),
            MapPort("axiRds", SV(*(f"axi_rd_{i}" for i in range(count)))),
        )

        Ins(
            f"AxiWrMultiplexer{axiTypeName}",
            "wr_multiplexer",
            MapGeneric("FIFOLogDepth", Lit(4)),
            MapPort("sys", S("sys")),
            MapPort("axiWr", S("axi_wr")),
            MapPort("axiWrs", SV(*(f"axi_wr_{i}" for i in range(count)))),
        )

        for i in range(count):
            Ins(
                f"AxiJoiner{axiTypeName}",
                f"joiner_{i}",
                MapPort("sys", S("sys")),
                MapPort("axi", S(f"axi_out_pipelined_{i}")),
                MapPort("axiRd", S(f"axi_rd_{i}")),
                MapPort("axiWr", S(f"axi_wr_{i}")),
            )

            Ins(
                f"AxiPipelineStage{axiTypeName}",
                f"pipeline_stage_out_{i}",
                MapPort("sys", S("sys")),
                MapPort("axiIn", S(f"axi_out_pipelined_{i}")),
                MapPort("axiOut", S(f"axi_out_{i}")),
            )
