Inc("../../utils.py")

Inc("../../types/Monitor.py")

def StreamMonitorTemplate(streamTypeName):
    Ent(
        f"HlsStreamMonitor{streamTypeName}",
        Generic("FIFOLogDepth", T("Integer")),
        PortI("sys", T("Sys")),
        PortM("master", T(f"{streamTypeName}")),
        PortS("slave", T(f"{streamTypeName}")),
        PortI("reset_counters", T("Logic")),
        PortS("memRd", T("MonitorMemRd")),
        x_templates={
            "generic/hls_stream_monitor.vhd": f"hls_stream_monitor_{streamTypeName}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_pm_streamMaster": "master",
                "x_ps_streamSlave": "slave",
                "x_pi_reset_counters": "reset_counters",
                "x_ps_memRd": "memRd",
            }
        ),
    )
