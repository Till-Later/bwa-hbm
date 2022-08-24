Inc("../../utils.py")

def AxiSplitterTemplate(memTypeName):
    Ent(
        f"AxiSplitter{memTypeName}",
        PortI("sys", T("Sys")),
        PortM("axi", T(memTypeName)),
        PortS("axiRd", T(memTypeName + "Rd")),
        PortS("axiWr", T(memTypeName + "Wr")),
        x_templates={
            "components/axi/AxiSplitter.vhd": f"axi_splitter_{memTypeName}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_pm_axi": "axi",
                "x_ps_axiRd": "axiRd",
                "x_ps_axiWr": "axiWr",
            }
        ),
    )
