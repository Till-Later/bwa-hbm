Inc("utils.py")


def TypeHlsBlock(name, data_bits=None, has_continue=False):
    # for ap_ctrl_hs, ap_ctrl_chain
    # ap_idle     --sm-> idle
    # ap_start    <-ms-- start
    # ap_ready    --sm-> ready
    # ap_return   --sm-> data    ?data_bits
    # ap_done     --sm-> done
    # ap_continue <-ms-- cont    ?has_continue
    if data_bits is not None:
        tdata = UnsignedType("{}Data".format(name), width=data_bits)
    else:
        tdata = None
    tlogic = T("Logic", "dfaccto")
    TypeC(
        name,
        x_is_hls_block=True,
        x_definition="{{>types/definition/hls_block.part}}",
        x_format_ms="{{>types/format/hls_block_ms.part}}",
        x_format_sm="{{>types/format/hls_block_sm.part}}",
        x_wrapeport="{{>types/wrapeport/hls_block.part}}",
        x_wrapeconv="{{>types/wrapeconv/hls_block.part}}",
        x_wrapidefs="{{>types/wrapidefs/hls_block.part}}",
        x_wrapiconv="{{>types/wrapiconv/hls_block.part}}",
        x_wrapipmap="{{>types/wrapipmap/hls_block.part}}",
        x_wrapigmap=None,
        x_tlogic=tlogic,
        x_has_continue=bool(has_continue),
        x_tdata=tdata,
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit({})),
    )


def TypeHlsHandshake(name, data_bits, mode="hs", is_input=False, is_output=False):
    # for ap_hs, ap_(o)vld, ap_ack
    # <name><i_pfx>        <-sm-- idata         ?is_input
    # <name><i_pfx>_ap_vld <-sm-- ivld ?has_vld ?is_input
    # <name><i_pfx>_ap_ack --ms-> iack ?has_ack ?is_input
    # <name><o_pfx>        --ms-> odata         ?is_output
    # <name><o_pfx>_ap_vld --ms-> ovld ?has_vld ?is_output
    # <name><o_pfx>_ap_ack <-sm-- oack ?has_ack ?is_output
    assert is_input or is_output, "HlsHandshake must be input or output"
    if mode == "hs":
        has_ivld = True
        has_ovld = True
        has_ack = True
    elif mode == "vld":
        has_ivld = True
        has_ovld = True
        has_ack = False
    elif mode == "ack":
        has_ivld = False
        has_ovld = False
        has_ack = True
    elif mode == "ovld":
        has_ivld = False
        has_ovld = True
        has_ack = False
    else:
        assert False, 'HlsHandshake invalid mode "{}"'.format(mode)

    in_prefix = "_i" if is_input and is_output else ""
    out_prefix = "_o" if is_input and is_output else ""

    tdata = UnsignedType("{}Data".format(name), width=data_bits)
    tlogic = T("Logic", "dfaccto")
    TypeC(
        name,
        x_is_hls_handshake=True,
        x_definition="{{>types/definition/hls_handshake.part}}",
        x_format_ms="{{>types/format/hls_handshake_ms.part}}",
        x_format_sm="{{>types/format/hls_handshake_sm.part}}",
        x_wrapeport="{{>types/wrapeport/hls_handshake.part}}",
        x_wrapeconv="{{>types/wrapeconv/hls_handshake.part}}",
        x_wrapidefs="{{>types/wrapidefs/hls_handshake.part}}",
        x_wrapiconv="{{>types/wrapiconv/hls_handshake.part}}",
        x_wrapipmap="{{>types/wrapipmap/hls_handshake.part}}",
        x_wrapigmap=None,
        x_tlogic=tlogic,
        x_tdata=tdata,
        x_in_prefix=in_prefix,
        x_out_prefix=out_prefix,
        x_iprefix=in_prefix,
        x_oprefix=out_prefix,
        x_is_input=is_input,
        x_is_output=is_output,
        x_has_iack=has_ack and is_input,
        x_has_oack=has_ack and is_output,
        x_has_ivld=has_ivld and is_input,
        x_has_ovld=has_ovld and is_output,
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit({})),
    )

def TypeHlsFifo(name, data_bits, id_bits = 0, is_source=False, is_sink=False):
    # for ap_fifo
    # <name>_dout    <-sm-- id & data   ?is_sink
    # <name>_empty_n <-sm-- ready       ?is_sink
    # <name>_read    --ms-> strobe      ?is_sink
    # <name>_din     --ms-> iq & data   ?is_source
    # <name>_full_n  <-sm-- ready       ?is_source
    # <name>_write   --ms-> strobe      ?is_source
    assert (is_source and not is_sink) or (
        not is_source and is_sink
    ), "HlsFifo must be either source or sink"
    tdata = (
        UnsignedType("{}Data".format(name), width=data_bits)
        if data_bits > 1
        else T("Logic", "dfaccto")
    )
    tid = UnsignedType("{}Id".format(name), width=id_bits) if id_bits > 0 else None
    tlogic = T("Logic", "dfaccto")
    TypeC(
        name,
        x_is_hls_fifo=True,
        x_definition="{{>types/definition/hls_fifo.part}}",
        x_format_ms="{{>types/format/hls_fifo_ms.part}}",
        x_format_sm="{{>types/format/hls_fifo_sm.part}}",
        x_wrapeport="{{>types/wrapeport/hls_fifo.part}}",
        x_wrapeconv="{{>types/wrapeconv/hls_fifo.part}}",
        x_wrapidefs="{{>types/wrapidefs/hls_fifo.part}}",
        x_wrapiconv="{{>types/wrapiconv/hls_fifo.part}}",
        x_wrapipmap="{{>types/wrapipmap/hls_fifo.part}}",
        x_wrapigmap=None,
        x_tlogic=tlogic,
        x_tdata=tdata,
        x_is_sink=is_sink,
        x_has_id=id_bits > 0,
        x_tid=tid,
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit({})),
    )


def TypeHlsMemory(name, data_bits, addr_bits, has_wr=True, has_rd=True):
    # for ap_memory
    # <name>_address0  --ms-> addr
    # <name>_we0       --ms-> write    ?has_wr
    # <name>_d0        --ms-> wdata    ?has_wr
    # <name>_q0        <-sm-- rdata    ?has_rd
    # <name>_ce0       --ms-> strobe
    assert has_wr or has_rd, "HlsMemory must have read or write signals"
    tdata = UnsignedType("{}Data".format(name), width=data_bits)
    taddr = UnsignedType("{}Addr".format(name), width=addr_bits)
    tlogic = T("Logic", "dfaccto")
    TypeC(
        name,
        x_is_hls_memory=True,
        x_definition="{{>types/definition/hls_memory.part}}",
        x_format_ms="{{>types/format/hls_memory_ms.part}}",
        x_format_sm="{{>types/format/hls_memory_sm.part}}",
        x_wrapeport="{{>types/wrapeport/hls_memory.part}}",
        x_wrapeconv="{{>types/wrapeconv/hls_memory.part}}",
        x_wrapidefs="{{>types/wrapidefs/hls_memory.part}}",
        x_wrapiconv="{{>types/wrapiconv/hls_memory.part}}",
        x_wrapipmap="{{>types/wrapipmap/hls_memory.part}}",
        x_wrapigmap=None,
        x_tlogic=tlogic,
        x_tdata=tdata,
        x_taddr=taddr,
        x_has_wr=bool(has_wr),
        x_has_rd=bool(has_rd),
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit({})),
    )


def TypeHlsBus(name, data_bits, addr_bits=32, size_bits=32):
    # for ap_bus
    # <name>_address     --ms-> req_addr
    # <name>_req_din     --ms-> req_write
    # <name>_size        --ms-> req_size
    # <name>_dataout     --ms-> req_wdata
    # <name>_req_full_n  <-sm-- req_ready
    # <name>_req_write   --ms-> req_strobe
    # <name>_datain      <-sm-- rsp_rdata
    # <name>_rsp_empty_n <-sm-- rsp_ready
    # <name>_rsp_read    --ms-> rsp_strobe
    tdata = UnsignedType("{}Data".format(name), width=data_bits)
    taddr = UnsignedType("{}Addr".format(name), width=addr_bits)
    tsize = UnsignedType("{}Size".format(name), width=size_bits)
    tlogic = T("Logic", "dfaccto")
    TypeC(
        name,
        x_is_hls_bus=True,
        x_definition="{{>types/definition/hls_bus.part}}",
        x_format_ms="{{>types/format/hls_bus_ms.part}}",
        x_format_sm="{{>types/format/hls_bus_sm.part}}",
        x_wrapeport="{{>types/wrapeport/hls_bus.part}}",
        x_wrapeconv="{{>types/wrapeconv/hls_bus.part}}",
        x_wrapidefs="{{>types/wrapidefs/hls_bus.part}}",
        x_wrapiconv="{{>types/wrapiconv/hls_bus.part}}",
        x_wrapipmap="{{>types/wrapipmap/hls_bus.part}}",
        x_wrapigmap=None,
        x_tlogic=tlogic,
        x_tdata=tdata,
        x_taddr=taddr,
        x_tsize=tsize,
        x_cnull=lambda t: Con("{}Null".format(name), t, value=Lit({})),
    )


# for s_axilite
# C_S_AXI_<name>_ADDR_WIDTH
# C_S_AXI_<name>_DATA_WIDTH
# s_axi_<name>_AWVALID : IN STD_LOGIC;
# s_axi_<name>_AWREADY : OUT STD_LOGIC;
# s_axi_<name>_AWADDR : IN STD_LOGIC_VECTOR (C_S_AXI_MYARG_ADDR_WIDTH-1 downto 0);
# s_axi_<name>_WVALID : IN STD_LOGIC;
# s_axi_<name>_WREADY : OUT STD_LOGIC;
# s_axi_<name>_WDATA : IN STD_LOGIC_VECTOR (C_S_AXI_MYARG_DATA_WIDTH-1 downto 0);
# s_axi_<name>_WSTRB : IN STD_LOGIC_VECTOR (C_S_AXI_MYARG_DATA_WIDTH/8-1 downto 0);
# s_axi_<name>_ARVALID : IN STD_LOGIC;
# s_axi_<name>_ARREADY : OUT STD_LOGIC;
# s_axi_<name>_ARADDR : IN STD_LOGIC_VECTOR (C_S_AXI_MYARG_ADDR_WIDTH-1 downto 0);
# s_axi_<name>_RVALID : OUT STD_LOGIC;
# s_axi_<name>_RREADY : IN STD_LOGIC;
# s_axi_<name>_RDATA : OUT STD_LOGIC_VECTOR (C_S_AXI_MYARG_DATA_WIDTH-1 downto 0);
# s_axi_<name>_RRESP : OUT STD_LOGIC_VECTOR (1 downto 0);
# s_axi_<name>_BVALID : OUT STD_LOGIC;
# s_axi_<name>_BREADY : IN STD_LOGIC;
# s_axi_<name>_BRESP : OUT STD_LOGIC_VECTOR (1 downto 0)

# for m_axi
# C_M_AXI_<name>_ADDR_WIDTH : INTEGER := 32;
# C_M_AXI_<name>_ID_WIDTH : INTEGER := 1;
# C_M_AXI_<name>_AWUSER_WIDTH : INTEGER := 1;
# C_M_AXI_<name>_DATA_WIDTH : INTEGER := 32;
# C_M_AXI_<name>_WUSER_WIDTH : INTEGER := 1;
# C_M_AXI_<name>_ARUSER_WIDTH : INTEGER := 1;
# C_M_AXI_<name>_RUSER_WIDTH : INTEGER := 1;
# C_M_AXI_<name>_BUSER_WIDTH : INTEGER := 1;
# C_M_AXI_<name>_TARGET_ADDR : INTEGER := 0;
# C_M_AXI_<name>_USER_VALUE : INTEGER := 0;
# C_M_AXI_<name>_PROT_VALUE : INTEGER := 0;
# C_M_AXI_<name>_CACHE_VALUE : INTEGER := 3;
# m_axi_<name>_AWVALID : OUT STD_LOGIC;
# m_axi_<name>_AWREADY : IN STD_LOGIC;
# m_axi_<name>_AWADDR : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ADDR_WIDTH-1 downto 0);
# m_axi_<name>_AWID : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ID_WIDTH-1 downto 0);
# m_axi_<name>_AWLEN : OUT STD_LOGIC_VECTOR (7 downto 0);
# m_axi_<name>_AWSIZE : OUT STD_LOGIC_VECTOR (2 downto 0);
# m_axi_<name>_AWBURST : OUT STD_LOGIC_VECTOR (1 downto 0);
# m_axi_<name>_AWLOCK : OUT STD_LOGIC_VECTOR (1 downto 0);
# m_axi_<name>_AWCACHE : OUT STD_LOGIC_VECTOR (3 downto 0);
# m_axi_<name>_AWPROT : OUT STD_LOGIC_VECTOR (2 downto 0);
# m_axi_<name>_AWQOS : OUT STD_LOGIC_VECTOR (3 downto 0);
# m_axi_<name>_AWREGION : OUT STD_LOGIC_VECTOR (3 downto 0);
# m_axi_<name>_AWUSER : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_AWUSER_WIDTH-1 downto 0);
# m_axi_<name>_WVALID : OUT STD_LOGIC;
# m_axi_<name>_WREADY : IN STD_LOGIC;
# m_axi_<name>_WDATA : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_DATA_WIDTH-1 downto 0);
# m_axi_<name>_WSTRB : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_DATA_WIDTH/8-1 downto 0);
# m_axi_<name>_WLAST : OUT STD_LOGIC;
# m_axi_<name>_WID : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ID_WIDTH-1 downto 0);
# m_axi_<name>_WUSER : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_WUSER_WIDTH-1 downto 0);
# m_axi_<name>_ARVALID : OUT STD_LOGIC;
# m_axi_<name>_ARREADY : IN STD_LOGIC;
# m_axi_<name>_ARADDR : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ADDR_WIDTH-1 downto 0);
# m_axi_<name>_ARID : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ID_WIDTH-1 downto 0);
# m_axi_<name>_ARLEN : OUT STD_LOGIC_VECTOR (7 downto 0);
# m_axi_<name>_ARSIZE : OUT STD_LOGIC_VECTOR (2 downto 0);
# m_axi_<name>_ARBURST : OUT STD_LOGIC_VECTOR (1 downto 0);
# m_axi_<name>_ARLOCK : OUT STD_LOGIC_VECTOR (1 downto 0);
# m_axi_<name>_ARCACHE : OUT STD_LOGIC_VECTOR (3 downto 0);
# m_axi_<name>_ARPROT : OUT STD_LOGIC_VECTOR (2 downto 0);
# m_axi_<name>_ARQOS : OUT STD_LOGIC_VECTOR (3 downto 0);
# m_axi_<name>_ARREGION : OUT STD_LOGIC_VECTOR (3 downto 0);
# m_axi_<name>_ARUSER : OUT STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ARUSER_WIDTH-1 downto 0);
# m_axi_<name>_RVALID : IN STD_LOGIC;
# m_axi_<name>_RREADY : OUT STD_LOGIC;
# m_axi_<name>_RDATA : IN STD_LOGIC_VECTOR (C_M_AXI_MYARG1_DATA_WIDTH-1 downto 0);
# m_axi_<name>_RLAST : IN STD_LOGIC;
# m_axi_<name>_RID : IN STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ID_WIDTH-1 downto 0);
# m_axi_<name>_RUSER : IN STD_LOGIC_VECTOR (C_M_AXI_MYARG1_RUSER_WIDTH-1 downto 0);
# m_axi_<name>_RRESP : IN STD_LOGIC_VECTOR (1 downto 0);
# m_axi_<name>_BVALID : IN STD_LOGIC;
# m_axi_<name>_BREADY : OUT STD_LOGIC;
# m_axi_<name>_BRESP : IN STD_LOGIC_VECTOR (1 downto 0);
# m_axi_<name>_BID : IN STD_LOGIC_VECTOR (C_M_AXI_MYARG1_ID_WIDTH-1 downto 0);
# m_axi_<name>_BUSER : IN STD_LOGIC_VECTOR (C_M_AXI_MYARG1_BUSER_WIDTH-1 downto 0);

# for axis
# <name>_TDATA  : OUT STD_LOGIC_VECTOR;
# <name>_TSTRB  : OUT STD_LOGIC_VECTOR;   ?
# <name>_TKEEP  : OUT STD_LOGIC_VECTOR;   ?
# <name>_TID    : OUT STD_LOGIC_VECTOR;   ?
# <name>_TDEST  : OUT STD_LOGIC_VECTOR;   ?
# <name>_TLAST  : OUT STD_LOGIC;          ?
# <name>_TVALID : OUT STD_LOGIC;
# <name>_TREADY : IN  STD_LOGIC;
