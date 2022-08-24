Inc("utils.py")

with Pkg("dfaccto_axi", x_templates={"generic/package.vhd": "pkg/dfaccto_axi.vhd"}):

    UnsignedType("AxiLen", width=8)

    UnsignedType("AxiSize", width=3)

    UnsignedType(
        "AxiBurst",
        width=2,
        x_cfixed=lambda t: Con("AxiBurstFixed", t, value=Lit(0)),
        x_cincr=lambda t: Con("AxiBurstIncr", t, value=Lit(1)),
        x_cwrap=lambda t: Con("AxiBurstWrap", t, value=Lit(2)),
    )

    UnsignedType(
        "AxiLock",
        width=2,
        x_cnormal=lambda t: Con("AxiLockNormal", t, value=Lit(0)),
        x_cexclusive=lambda t: Con("AxiLockExclusive", t, value=Lit(1)),
        x_clocked=lambda t: Con("AxiLockLocked", t, value=Lit(2)),
    )

    UnsignedType(
        "AxiCache",
        width=4,
        x_cdn=lambda t: Con("AxiCacheDevNoBuf", t, value=Lit(0b0000)),
        x_cdb=lambda t: Con("AxiCacheDevBuf", t, value=Lit(0b0001)),
        x_cnn=lambda t: Con("AxiCacheNormNoBuf", t, value=Lit(0b0010)),
        x_cnb=lambda t: Con("AxiCacheNormBuf", t, value=Lit(0b0011)),
        x_ctrn=lambda t: Con("AxiCacheThruRdNoA", t, value=Lit(0b1010)),
        x_ctwn=lambda t: Con("AxiCacheThruWrNoA", t, value=Lit(0b0110)),
        x_cta=lambda t: Con("AxiCacheThruAlloc", t, value=Lit(0b1110)),
        x_cwrn=lambda t: Con("AxiCacheBackRdNoA", t, value=Lit(0b1011)),
        x_cwwn=lambda t: Con("AxiCacheBackWrNoA", t, value=Lit(0b0111)),
        x_cwa=lambda t: Con("AxiCacheBackAlloc", t, value=Lit(0b1111)),
    )

    UnsignedType(
        "AxiProt",
        width=3,
        x_cpriv=lambda t: Con("AxiProtFlagPriv", t, value=Lit(0b001)),
        x_csec=lambda t: Con("AxiProtFlagSec", t, value=Lit(0b010)),
        x_cinst=lambda t: Con("AxiProtFlagInst", t, value=Lit(0b100)),
    )

    UnsignedType("AxiQos", width=4)

    UnsignedType("AxiRegion", width=4)

    UnsignedType(
        "AxiResp",
        width=2,
        x_cokay=lambda t: Con("AxiRespOkay", t, value=Lit(0)),
        x_cexokay=lambda t: Con("AxiRespExOkay", t, value=Lit(1)),
        x_cslverr=lambda t: Con("AxiRespSlvErr", t, value=Lit(2)),
        x_cdecerr=lambda t: Con("AxiRespDecErr", t, value=Lit(3)),
    )


def AxiType(
    name,
    data_bytes,
    addr_bits,
    id_bits=None,
    add_split=False,
    has_burst=True,
    has_attr=False,
    has_lock=None,
    has_cache=None,
    has_prot=None,
    has_qos=None,
    has_region=None,
    aruser_bits=None,
    awuser_bits=None,
    ruser_bits=None,
    wuser_bits=None,
    buser_bits=None,
    len_bits=8,
):
    assert data_bytes in (
        1,
        2,
        4,
        8,
        16,
        32,
        64,
        128,
    ), "Axi only supports power-of-two byte counts up to 128"
    word_idx_bits = uwidth(data_bytes - 1)
    word_addr_bits = addr_bits - word_idx_bits
    assert (
        word_addr_bits >= 0
    ), "Axi address range must at least include a single data word"
    tdata = UnsignedType("{}Data".format(name), width=data_bytes * 8)
    tstrb = UnsignedType("{}Strb".format(name), width=data_bytes)
    taddr = UnsignedType("{}Addr".format(name), width=addr_bits)
    twidx = UnsignedType("{}WordIdx".format(name), width=word_idx_bits)
    twaddr = UnsignedType("{}WordAddr".format(name), width=word_addr_bits)
    clen = T("AxiLen", "dfaccto_axi").x_cnull
    csize = Con(
        "{}FullSize".format(name), T("AxiSize", "dfaccto_axi"), value=Lit(word_idx_bits)
    )
    cburst = T("AxiBurst", "dfaccto_axi").x_cnull

    tlogic = T("Logic", "dfaccto")
    tresp = T("AxiResp", "dfaccto_axi")

    if id_bits is not None:
        tid = UnsignedType("{}Id".format(name), width=id_bits)
    else:
        tid = None
    if aruser_bits is not None:
        taruser = UnsignedType("{}ARUser".format(name), width=aruser_bits)
    else:
        taruser = None
    if awuser_bits is not None:
        tawuser = UnsignedType("{}AWUser".format(name), width=awuser_bits)
    else:
        tawuser = None
    if ruser_bits is not None:
        truser = UnsignedType("{}RUser".format(name), width=ruser_bits)
    else:
        truser = None
    if wuser_bits is not None:
        twuser = UnsignedType("{}WUser".format(name), width=wuser_bits)
    else:
        twuser = None
    if buser_bits is not None:
        tbuser = UnsignedType("{}BUser".format(name), width=buser_bits)
    else:
        tbuser = None

    if has_burst:
        # tlen = T("AxiLen", "dfaccto_axi")
        tlen = UnsignedType("{}Len".format(name), width=len_bits)
        tsize = T("AxiSize", "dfaccto_axi")
        tburst = T("AxiBurst", "dfaccto_axi")
        tlast = tlogic
    else:
        tlen = None
        tsize = None
        tburst = None
        tlast = None
    if has_attr if has_lock is None else has_lock:
        tlock = T("AxiLock", "dfaccto_axi")
    else:
        tlock = None
    if has_attr if has_cache is None else has_cache:
        tcache = T("AxiCache", "dfaccto_axi")
    else:
        tcache = None
    if has_attr if has_prot is None else has_prot:
        tprot = T("AxiProt", "dfaccto_axi")
    else:
        tprot = None
    if has_attr if has_qos is None else has_qos:
        tqos = T("AxiQos", "dfaccto_axi")
    else:
        tqos = None
    if has_attr if has_region is None else has_region:
        tregion = T("AxiRegion", "dfaccto_axi")
    else:
        tregion = None

    variants = [(name, True, True)]
    if add_split:
        variants.append(("{}Rd".format(name), True, False))
        variants.append(("{}Wr".format(name), False, True))
    for variant, has_rd, has_wr in variants:
        TypeC(
            variant,
            x_is_axi=True,
            x_has_rd=has_rd,
            x_has_wr=has_wr,
            x_definition="{{>types/definition/axi.part}}",
            x_format_ms="{{>types/format/axi_ms.part}}",
            x_format_sm="{{>types/format/axi_sm.part}}",
            x_wrapeport="{{>types/wrapeport/axi.part}}",
            x_wrapeconv="{{>types/wrapeconv/axi.part}}",
            x_wrapidefs="{{>types/wrapidefs/axi.part}}",
            x_wrapiconv="{{>types/wrapiconv/axi.part}}",
            x_wrapipmap="{{>types/wrapipmap/axi.part}}",
            x_wrapigmap="{{>types/wrapigmap/axi.part}}",
            x_tlogic=tlogic,
            x_tresp=tresp,
            x_tdata=tdata,
            x_tstrb=tstrb,
            x_taddr=taddr,
            x_twidx=twidx,
            x_twaddr=twaddr,
            x_clen=clen,
            x_csize=csize,
            x_cburst=cburst,
            x_tid=tid,
            x_taruser=taruser,
            x_tawuser=tawuser,
            x_truser=truser,
            x_twuser=twuser,
            x_tbuser=tbuser,
            x_tlen=tlen,
            x_tsize=tsize,
            x_tburst=tburst,
            x_tlast=tlast,
            x_tlock=tlock,
            x_tcache=tcache,
            x_tprot=tprot,
            x_tqos=tqos,
            x_tregion=tregion,
            x_cnull=lambda t: Con(
                "{}Null".format(variant),
                t,
                value=Lit({"awsize": word_idx_bits, "arsize": word_idx_bits}),
            ),
        )
    return T(name)


def AxiStreamType(
    name,
    data_bytes,
    id_bits=None,
    dest_bits=None,
    user_bits=None,
    has_strb=False,
    has_keep=True,
    has_last=True,
):
    tdata = UnsignedType("{}Data".format(name), width=data_bytes * 8)
    if has_strb:
        tstrb = UnsignedType("{}Strb".format(name), width=data_bytes)
    else:
        tstrb = None
    if has_keep:
        tkeep = (
            UnsignedType("{}Keep".format(name), width=data_bytes)
            if tstrb is None
            else tstrb
        )
    else:
        tkeep = None
    if id_bits is not None:
        tid = UnsignedType("{}Id".format(name), width=id_bits)
    else:
        tid = None
    if dest_bits is not None:
        tdest = UnsignedType("{}Dest".format(name), width=user_bits)
    else:
        tdest = None
    if user_bits is not None:
        tuser = UnsignedType("{}User".format(name), width=user_bits)
    else:
        tuser = None

    tlogic = T("Logic", "dfaccto")

    return TypeC(
        name,
        x_is_axi_stream=True,
        x_definition="{{>types/definition/axis.part}}",
        x_format_ms="{{>types/format/axis_ms.part}}",
        x_format_sm="{{>types/format/axis_sm.part}}",
        x_wrapeport="{{>types/wrapeport/axis.part}}",
        x_wrapeconv="{{>types/wrapeconv/axis.part}}",
        x_wrapidefs="{{>types/wrapidefs/axis.part}}",
        x_wrapiconv="{{>types/wrapiconv/axis.part}}",
        x_wrapipmap="{{>types/wrapipmap/axis.part}}",
        x_wrapigmap=None,
        x_tlogic=tlogic,
        x_has_last=bool(has_last),
        x_tdata=tdata,
        x_tstrb=tstrb,
        x_tkeep=tkeep,
        x_tid=tid,
        x_tdest=tdest,
        x_tuser=tuser,
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit({})),
    )
