Inc("../../utils.py")


def AxiPipelineStageTemplate(memTypeName):
    Ent(
        f"AxiPipelineStage{memTypeName}",
        PortI("sys", T("Sys")),
        PortM("axiIn", T(memTypeName)),
        PortS("axiOut", T(memTypeName)),
        x_templates={
            "components/axi/AxiPipelineStage.vhd": f"axi_pipeline_stage_{memTypeName}.vhd"
        },
        **fixedNameMapping(
            {"x_psys": "sys", "x_pm_master": "axiIn", "x_ps_slave": "axiOut"}
        ),
    )
