Inc("../../utils.py")

def StreamIdBufferTemplate(reqStreamMaster, reqStreamSlave, retStreamMaster, retStreamSlave):
    Ent(
        f"StreamIdBuffer{reqStreamMaster}{retStreamMaster}",
        PortI("sys", T("Sys")),
        PortM("reqStreamMaster", T(f"{reqStreamMaster}")),
        PortS("reqStreamSlave", T(f"{reqStreamSlave}")),
        PortM("retStreamMaster", T(f"{retStreamMaster}")),
        PortS("retStreamSlave", T(f"{retStreamSlave}")),
        x_templates={
            "components/StreamIdBuffer.vhd": f"stream_id_buffer_{reqStreamMaster}_{retStreamMaster}.vhd"
        },
        **fixedNameMapping(
            {
                "x_psys": "sys",
                "x_pm_reqStreamMaster": "reqStreamMaster",
                "x_ps_reqStreamSlave": "reqStreamSlave",
                "x_pm_retStreamMaster": "retStreamMaster",
                "x_ps_retStreamSlave": "retStreamSlave",                
            }
        ),
    )