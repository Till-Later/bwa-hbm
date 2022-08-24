Inc("../types/RegPort.py")
Inc("../include/ocaccel.py")

Ent(
    "CtrlRegDemux",
    Generic("PortCount", T("Integer")),
    Generic("Ports", T("RegMap"), vector="PortCount"),
    PortI("sys", T("Sys")),
    PortS("ctrl", ocaccel.tctrl),
    PortM("regPorts", T("RegPort"), vector="PortCount"),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_ps_ctrl": "ctrl",
            "x_pm_regPorts": "regPorts",
        }
    ),
    x_templates={"components/CtrlRegDemux.vhd": "ctrl_reg_demux.vhd"},
)