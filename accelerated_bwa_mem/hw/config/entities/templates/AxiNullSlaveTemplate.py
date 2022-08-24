Inc("../../utils.py")


def AxiNullSlaveTemplate(memTypeName):
    Ent(
        f"AxiNullSlave{memTypeName}",
        PortS("out", T(memTypeName)),
        x_templates={
            "components/axi/AxiNullSlave.vhd": f"axi_null_slave_{memTypeName}.vhd"
        },
        **fixedNameMapping({"x_ps_slave": "out"}),
    )
