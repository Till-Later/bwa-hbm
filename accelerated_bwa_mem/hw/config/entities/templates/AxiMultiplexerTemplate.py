Inc("../../utils.py")


def AxiMultiplexerTemplate(memTypeName, accessTypeName):
    Ent(
        f"Axi{accessTypeName}Multiplexer{memTypeName}",
        Generic("PortCount", T("Integer")),
        Generic("FIFOLogDepth", T("Integer")),
        PortI("sys", T("Sys")),
        PortM(f"axi{accessTypeName}", T(f"{memTypeName}{accessTypeName}")),
        PortS(
            f"axi{accessTypeName}s",
            T(f"{memTypeName}{accessTypeName}"),
            vector="PortCount",
        ),
        x_templates={
            f"components/axi/Axi{accessTypeName}Multiplexer.vhd": f"axi_{accessTypeName.lower()}_multiplexer_{memTypeName}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                f"x_pm_axi{accessTypeName}": f"axi{accessTypeName}",
                f"x_ps_axi{accessTypeName}s": f"axi{accessTypeName}s",
            }
        ),
    )
