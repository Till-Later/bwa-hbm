
with Pkg("reg_port_types", x_templates={"generic/package.vhd": "pkg/reg_port_types.vhd"}):
    c_RegAddrWidth = 12
    c_RegDataWidth = 32
    UnsignedType("RegAddr", width=c_RegAddrWidth)
    UnsignedType("RegData", width=c_RegDataWidth)
    UnsignedType("RegStrb", width=c_RegDataWidth // 8)
    TypeC(
        "RegPort",
        x_definition="{{>types/definition/regport.part}}",
        x_format_ms="{{>types/format/regport_ms.part}}",
        x_format_sm="{{>types/format/regport_sm.part}}",
        x_wrapport="{{>types/wrapport/regport.part}}",
        x_wrapmap="{{>types/wrapmap/regport.part}}",
        x_tRegAddr=T("RegAddr"),
        x_tRegData=T("RegData"),
        x_tRegStrb=T("RegStrb"),
        x_tlogic=T("Logic"),
        x_cnull=lambda t: Con("RegPortNull", t, value=Lit({})),
    )

    TypeS(
        "RegMap",
        x_definition="{{>types/definition/regmap.part}}",
        x_format="{{>types/format/regmap.part}}",
        x_tsize=T("RegAddr"),
        x_cnull=lambda t: Con("RegMapNull", t, value=Lit({})),
    )