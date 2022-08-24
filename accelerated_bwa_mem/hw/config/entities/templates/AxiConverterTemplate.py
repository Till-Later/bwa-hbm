Inc("../../utils.py")


def AxiConverterTemplate(inMemTypeName, outMemTypeName):
    Ent(
        f"AxiConverter{inMemTypeName}To{outMemTypeName}",
        PortM("axiIn", T(inMemTypeName)),
        PortS("axiOut", T(outMemTypeName)),
        **fixedNameMapping({"x_pm_master": "axiIn", "x_ps_slave": "axiOut"}),
        x_templates={
            "components/axi/AxiConverter.vhd": f"hmem_axi_converter_{inMemTypeName}_to_{outMemTypeName}.vhd"
        },
    )
