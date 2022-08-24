Inc("../../utils.py")
Inc("../../types/RegPort.py")

def RegPortToMemPortTemplate(memPortName):
    Ent(
        f"RegPortToMemPort{memPortName}",
        Generic("MemoryLatency", T("Integer")),
        PortI("sys", T("Sys")),
        PortS("regPort", T("RegPort")),
        PortM("memPort", T(memPortName)),
        x_templates={
            "generic/reg_port_to_mem_port.vhd": f"reg_port_to_mem_port_{memPortName}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_ps_reg": "regPort",
                "x_pm_mem": "memPort",
            }
        ),
    )