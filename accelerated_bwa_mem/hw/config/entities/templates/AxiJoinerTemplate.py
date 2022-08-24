Inc("../../utils.py")


def AxiJoinerTemplate(memTypeName):
    Ent(
        f"AxiJoiner{memTypeName}",
        PortI("sys", T("Sys")),
        PortS("axi", T(memTypeName)),
        PortM("axiRd", T(f"{memTypeName}Rd")),
        PortM("axiWr", T(f"{memTypeName}Wr")),
        x_templates={"components/axi/AxiJoiner.vhd": f"axi_joiner_{memTypeName}.vhd"},
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_ps_axi": "axi",
                "x_pm_axiRd": "axiRd",
                "x_pm_axiWr": "axiWr",
            }
        ),
    )
