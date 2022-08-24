
Inc("../utils.py")
Inc("../include/ocaccel.py")
Inc("../types/RegPort.py")

Ent(
    "ActionControl",
    Generic("ReadyCount", T("Integer")),
    Generic("ActionType", T("Integer")),
    Generic("ActionRev", T("Integer")),
    PortI("sys", T("Sys")),
    PortM("intr", ocaccel.tintr),
    PortS("reg", T("RegPort")),
    PortO("start", T("Logic")),
    PortI("ready", T("Logic"), vector="ReadyCount"),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_pm_intr": "intr",
            "x_ps_reg": "reg",
            "x_po_start": "start",
            "x_pi_ready": "ready",
        }
    ),
    x_templates={"components/ActionControl.vhd": "action_control.vhd"},
)