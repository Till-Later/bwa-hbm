def WrappedHlsEntity(name, *args):
    return Ent(
        f"{name}",
        PortI("sys", ocaccel.tsys, x_wrapname="ap"),
        PortS("ctrl_hs", T("HlsBlockCtrlHs"), x_wrapname="ap"),
        *args,
        x_genportsx_genports=lambda e: List(
            [p for p in e.ports if p.type.x_wrapigmap is not None]
        ),
        x_wrapname=f"{name}_{name}",
        x_templates={"generic/int_wrapper.vhd": f"hls_{name}.vhd"},
    )