Inc("../types/RegPort.py")
Inc("../types/Numeric.py")
Inc("../types/Control.py")

Ent(
    "AcceleratedBwaMemMainController",
    Generic("NumInitSignals", T("Integer")),
    Generic("NumMainSignals", T("Integer")),
    PortI("sys", T("Sys")),
    PortI("start", T("Logic")),
    PortO("ready", T("Logic")),
    PortO("reset_counters", T("Logic")),
    PortS("reg", T("RegPort")),
    PortO("bwt_addr", T("u64")),
    PortO("runtime_status_control_addr", T("u64")),
    PortO("bwt_primary", T("u64")),
    PortO("bwt_L2", T("u320")),
    PortO("bwt_size", T("u32")),
    PortO("split_width", T("u32")),
    PortO("split_len", T("u32")),
    PortO("min_seed_len", T("u32")),
    PortM("ctrl_hs_init", T("HlsBlockCtrlHs"), vector="NumInitSignals"),
    PortM("ctrl_hs_main", T("HlsBlockCtrlHs"), vector="NumMainSignals"),
    x_templates={
        "specific/accelerated_bwa_mem_main_controller.vhd": "accelerated_bwa_mem_main_controller.vhd"
    },
)