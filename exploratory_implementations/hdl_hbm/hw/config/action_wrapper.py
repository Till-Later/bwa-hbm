Inc("include/dfaccto.py")
Inc("include/ocaccel.py")

from functools import partial


def fixedNameMapping(mapping):
    parameter_list = {}

    for key, value in mapping.items():
        parameter_list[key] = partial(lambda name, e: e.ports[name], value)

    return parameter_list


with Pkg("user", x_templates={"generic/package.vhd": "pkg/user.vhd"}):
    TypeHlsBlock("HlsBlock", data_bits=8)
    TypeHlsHandshake(
        "HlsPortInout", data_bits=8, mode="hs", is_input=True, is_output=True
    )
    TypeHlsHandshake("HlsPortIn", data_bits=8, mode="vld", is_input=True)
    TypeHlsFifo("HlsFifoOut", data_bits=8, is_source=True)
    TypeHlsFifo("HlsFifoIn", data_bits=8, is_sink=True)
    TypeHlsMemory("HlsMem", data_bits=8, addr_bits=5)
    TypeHlsMemory("HlsMemWr", data_bits=8, addr_bits=5, has_rd=False)
    TypeHlsBus("HlsBus", data_bits=8)
    AxiType("HlsAxi", data_bytes=4, addr_bits=32, id_bits=2)
    AxiType("HlsCtrl", data_bytes=4, addr_bits=5, has_burst=False)
    AxiStreamType("HlsStream", data_bytes=4)

    # For AxiReader
    AxiStreamType(
        "StmHbm",
        ocaccel.AxiHbm_DataBytes,
        id_bits=ocaccel.AxiHbm_IdBits,
        user_bits=ocaccel.AxiHbm_UserBits,
    )

    c_RegAddrWidth = 2
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

    UnsignedType("Status", width=20)

axiRW_ports = [
    Generic("FIFOLogDepth", T("Integer")),
    PortI("sys", T("Sys")),
    PortI("start", T("Logic")),
    PortO("ready", T("Logic")),
    PortS("regs", T("RegPort")),
    PortO("status", T("Status")),
]

Ent(
    "AxiReader",
    *axiRW_ports,
    PortM("axiRd", T("AxiHbmRd")),
    PortM("axiStm", T("StmHbm")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_pi_start": "start",
            "x_po_ready": "ready",
            "x_pm_axiRd": "axiRd",
            "x_pm_axiStm": "axiStm",
            "x_ps_reg": "regs",
            "x_po_status": "status",
        }
    ),
    x_templates={"components/axi/AxiReader.vhd": "axi_reader.vhd"},
)

Ent(
    "AxiWriter",
    *axiRW_ports,
    PortS("axiStm", T("StmHbm")),
    PortM("axiWr", T("AxiHbmWr")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_pi_start": "start",
            "x_po_ready": "ready",
            "x_pm_axiWr": "axiWr",
            "x_ps_axiStm": "axiStm",
            "x_ps_reg": "regs",
            "x_po_status": "status",
        }
    ),
    x_templates={"components/axi/AxiWriter.vhd": "axi_writer.vhd"},
)

Ent(
    "AxiAddrMachine",
    x_templates={"components/axi/AxiAddrMachine.vhd": "axi_addr_machine.vhd"},
)

Ent(
    "AxiSplitter",
    PortI("sys", T("Sys")),
    PortM("axi", T("AxiHbm")),
    PortS("axiRd", T("AxiHbmRd")),
    PortS("axiWr", T("AxiHbmWr")),
    x_templates={"components/axi/AxiSplitter.vhd": "axi_splitter.vhd"},
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_pm_axi": "axi",
            "x_ps_axiRd": "axiRd",
            "x_ps_axiWr": "axiWr",
        }
    ),
)

Ent(
    "HbmBenchmarkController",
    PortI("sys", T("Sys")),
    PortM("axiStmWr", T("StmHbm")),
    PortS("axiStmRd", T("StmHbm")),
    PortM("regsRd", T("RegPort")),
    PortM("regsWr", T("RegPort")),
    PortO("startRd", T("Logic")),
    PortI("readyRd", T("Logic")),
    PortO("startWr", T("Logic")),
    PortI("readyWr", T("Logic")),
    **fixedNameMapping(
        {
            "x_psys": "sys",
            "x_pm_axiStmWr": "axiStmWr",
            "x_ps_axiStmRd": "axiStmRd",
            "x_pm_regsRd": "regsRd",
            "x_pm_regsWr": "regsWr",
            "x_po_startRd": "startRd",
            "x_pi_readyRd": "readyRd",
            "x_po_startWr": "startWr",
            "x_pi_readyWr": "readyWr",
        }
    ),
    x_templates={
        "specific/hbm_benchmark_controller.vhd": "hbm_benchmark_controller.vhd"
    },
)

with Ent(
    "action_wrapper",
    *ocaccel.get_ports(),
    x_templates={"generic/ext_wrapper.vhd": "action_wrapper.vhd"},
):
    Ins(
        "AxiSplitter",
        "hbm_splitter",
        MapPort("sys", S("sys")),
        MapPort("axi", S("hbm0")),
        MapPort("axiRd", S("hbmRd")),
        MapPort("axiWr", S("hbmWr")),
    )

    Ins(
        "AxiReader",
        "hbm_reader",
        MapGeneric("FIFOLogDepth", Lit(4)),
        MapPort("sys", S("sys")),
        MapPort("axiRd", S("hbmRd")),
        MapPort("axiStm", S("stmRd")),
        MapPort("regs", S("regsRd")),
        MapPort("start", S("startRd")),
        MapPort("ready", S("readyRd")),
    )

    Ins(
        "AxiWriter",
        "hbm_writer",
        MapGeneric("FIFOLogDepth", Lit(4)),
        MapPort("sys", S("sys")),
        MapPort("axiWr", S("hbmWr")),
        MapPort("axiStm", S("stmWr")),
        MapPort("regs", S("regsWr")),
        MapPort("start", S("startWr")),
        MapPort("ready", S("readyWr")),
    )

    Ins(
        "HbmBenchmarkController",
        "hbm_benchmark_controller",
        MapPort("sys", S("sys")),
        MapPort("axiStmWr", S("stmWr")),
        MapPort("axiStmRd", S("stmRd")),
        MapPort("regsRd", S("regsRd")),
        MapPort("regsWr", S("regsWr")),
        MapPort("startRd", S("startRd")),
        MapPort("readyRd", S("readyRd")),
        MapPort("startWr", S("startWr")),
        MapPort("readyWr", S("readyWr")),
    )
#
#
# Ent(
#     "hls_wrapper",
#     PortI("sys", T("Sys"), x_wrapname="ap"),
#     PortS("block", T("HlsBlock"), x_wrapname="ap"),
#     PortM("portInout", T("HlsPortInout"), x_wrapname="myrefval"),
#     PortM("portIn", T("HlsPortIn"), x_wrapname="myoutval"),
#     PortM("fifoIn", T("HlsFifoIn"), x_wrapname="myinfifo"),
#     PortM("fifoOut", T("HlsFifoOut"), x_wrapname="myoutfifo"),
#     PortM("mem", T("HlsMem"), x_wrapname="mymemrw"),
#     PortM("memWr", T("HlsMemWr"), x_wrapname="mymemw"),
#     PortM("bus", T("HlsBus"), x_wrapname="mybus"),
#     PortM("axi", T("HlsAxi"), x_wrapname="m_axi_myaxim"),
#     PortS("ctrl", T("HlsCtrl"), x_wrapname="s_axi_myaxis"),
#     PortS("stmIn", T("HlsStream"), x_wrapname="myinstm"),
#     PortM("stmOut", T("HlsStream"), x_wrapname="myoutstm"),
#     x_genports=lambda e: list([p for p in e.ports if p.type.x_wrapigmap is not None]),
#     x_wrapname="hls_toplevel",
#     x_templates={"generic/int_wrapper.vhd": "hls_toplevel.vhd"},
# )
#
