library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util.all;

package fosi_axi is

  -----------------------------------------------------------------------------
  -- General Axi Declarations
  -----------------------------------------------------------------------------

  -- byte address bits of the boundary a burst may not cross(4KB blocks)
  constant c_AxiBurstAlignWidth : integer := 12;

  constant c_AxiLenWidth    : integer := 8;
  subtype t_AxiLen is unsigned(c_AxiLenWidth-1 downto 0);
  constant c_AxiNullLen : t_AxiLen := (others => '0');

  constant c_AxiSizeWidth   : integer := 3;
  subtype t_AxiSize is unsigned(c_AxiSizeWidth-1 downto 0);

  constant c_AxiBurstWidth  : integer := 2;
  subtype t_AxiBurst is unsigned(c_AxiBurstWidth-1 downto 0);
  constant c_AxiBurstFixed : t_AxiBurst := "00";
  constant c_AxiBurstIncr : t_AxiBurst := "01";
  constant c_AxiBurstWrap : t_AxiBurst := "10";
  constant c_AxiNullBurst : t_AxiBurst := c_AxiBurstFixed;

  constant c_AxiLockWidth  : integer := 2;
  subtype t_AxiLock is unsigned(c_AxiLockWidth-1 downto 0);
  constant c_AxiLockNormal : t_AxiLock := "00";
  constant c_AxiLockExclusive : t_AxiLock := "01";
  constant c_AxiLockLocked : t_AxiLock := "10";
  constant c_AxiNullLock   : t_AxiLock := c_AxiLockNormal;

  constant c_AxiCacheWidth  : integer := 4;
  subtype t_AxiCache is unsigned(c_AxiCacheWidth-1 downto 0);
  constant c_AxiNullCache  : t_AxiCache  := "0010"; -- Normal, NoCache, NoBuffer

  constant c_AxiProtWidth   : integer := 3;
  subtype t_AxiProt is unsigned(c_AxiProtWidth-1 downto 0);
  constant c_AxiNullProt   : t_AxiProt   := "000";  -- Unprivileged, Non-Sec, Data

  constant c_AxiQosWidth    : integer := 4;
  subtype t_AxiQos is unsigned(c_AxiQosWidth-1 downto 0);
  constant c_AxiNullQos    : t_AxiQos    := "0000"; -- No QOS

  constant c_AxiRegionWidth : integer := 4;
  subtype t_AxiRegion is unsigned(c_AxiRegionWidth-1 downto 0);
  constant c_AxiNullRegion : t_AxiRegion := "0000"; -- Default Region

  constant c_AxiRespWidth : integer := 2;
  subtype t_AxiResp is unsigned(c_AxiRespWidth-1 downto 0);
  constant c_AxiRespOkay   : t_AxiResp := "00";
  constant c_AxiRespExOkay : t_AxiResp := "01";
  constant c_AxiRespSlvErr : t_AxiResp := "10";
  constant c_AxiRespDecErr : t_AxiResp := "11";


  -------------------------------------------------------------------------------
  -- NativeAxi interface
  -------------------------------------------------------------------------------
  --Scalars:

  constant c_NativeAxiDataWidth : integer := C_HOST_AXI_DATA_WIDTH;
  constant c_NativeAxiStrbWidth : integer := c_NativeAxiDataWidth/8;
  subtype t_NativeAxiData is unsigned (c_NativeAxiDataWidth-1 downto 0);
  subtype t_NativeAxiStrb is unsigned (c_NativeAxiStrbWidth-1 downto 0);

  constant c_NativeAxiByteAddrWidth : integer := f_clog2(c_NativeAxiStrbWidth);
  subtype t_NativeAxiByteAddr is unsigned (c_NativeAxiByteAddrWidth-1 downto 0);

  constant c_NativeAxiFullSize : t_AxiSize := to_unsigned(c_NativeAxiByteAddrWidth, t_AxiSize'length);
  constant c_NativeAxiBurstLenWidth : integer := c_AxiBurstAlignWidth - c_NativeAxiByteAddrWidth;
  subtype t_NativeAxiBurstLen is unsigned(c_NativeAxiBurstLenWidth-1 downto 0);

  constant c_NativeAxiAddrWidth : integer := C_HOST_AXI_ADDR_WIDTH;
  subtype t_NativeAxiAddr is unsigned (c_NativeAxiAddrWidth-1 downto 0);

  constant c_NativeAxiWordAddrWidth : integer := c_NativeAxiAddrWidth - c_NativeAxiByteAddrWidth;
  subtype t_NativeAxiWordAddr is unsigned(c_NativeAxiWordAddrWidth-1 downto 0);

  --Complete Bundle:
  type t_NativeAxi_ms is record
    awaddr   : t_NativeAxiAddr;
    awlen    : t_AxiLen;
    awsize   : t_AxiSize;
    awburst  : t_AxiBurst;
    awvalid  : std_logic;
    wdata    : t_NativeAxiData;
    wstrb    : t_NativeAxiStrb;
    wlast    : std_logic;
    wvalid   : std_logic;
    bready   : std_logic;
    araddr   : t_NativeAxiAddr;
    arlen    : t_AxiLen;
    arsize   : t_AxiSize;
    arburst  : t_AxiBurst;
    arvalid  : std_logic;
    rready   : std_logic;
  end record;
  type t_NativeAxi_sm is record
    awready  : std_logic;
    wready   : std_logic;
    bresp    : t_AxiResp;
    bvalid   : std_logic;
    arready  : std_logic;
    rdata    : t_NativeAxiData;
    rresp    : t_AxiResp;
    rlast    : std_logic;
    rvalid   : std_logic;
  end record;
  constant c_NativeAxiNull_ms : t_NativeAxi_ms := (
    awaddr   => (others => '0'),
    awlen    => c_AxiNullLen,
    awsize   => c_NativeAxiFullSize,
    awburst  => c_AxiNullBurst,
    awvalid  => '0',
    wdata    => (others => '0'),
    wstrb    => (others => '0'),
    wlast    => '0',
    wvalid   => '0',
    bready   => '0',
    araddr   => (others => '0'),
    arlen    => c_AxiNullLen,
    arsize   => c_NativeAxiFullSize,
    arburst  => c_AxiNullBurst,
    arvalid  => '0',
    rready   => '0' );
  constant c_NativeAxiNull_sm : t_NativeAxi_sm := (
    awready  => '0',
    wready   => '0',
    bresp    => (others => '0'),
    bvalid   => '0',
    arready  => '0',
    rdata    => (others => '0'),
    rresp    => (others => '0'),
    rlast    => '0',
    rvalid   => '0' );
  type t_NativeAxi_v_ms is array (integer range <>) of t_NativeAxi_ms;
  type t_NativeAxi_v_sm is array (integer range <>) of t_NativeAxi_sm;

  -- Read Bundle:
  type t_NativeAxiRd_ms is record
    araddr   : t_NativeAxiAddr;
    arlen    : t_AxiLen;
    arsize   : t_AxiSize;
    arburst  : t_AxiBurst;
    arvalid  : std_logic;
    rready   : std_logic;
  end record;
  type t_NativeAxiRd_sm is record
    arready  : std_logic;
    rdata    : t_NativeAxiData;
    rresp    : t_AxiResp;
    rlast    : std_logic;
    rvalid   : std_logic;
  end record;
  constant c_NativeAxiRdNull_ms : t_NativeAxiRd_ms := (
    araddr   => (others => '0'),
    arlen    => c_AxiNullLen,
    arsize   => c_NativeAxiFullSize,
    arburst  => c_AxiNullBurst,
    arvalid  => '0',
    rready   => '0' );
  constant c_NativeAxiRdNull_sm : t_NativeAxiRd_sm := (
    arready  => '0',
    rdata    => (others => '0'),
    rresp    => (others => '0'),
    rlast    => '0',
    rvalid   => '0' );
  type t_NativeAxiRd_v_ms is array (integer range <>) of t_NativeAxiRd_ms;
  type t_NativeAxiRd_v_sm is array (integer range <>) of t_NativeAxiRd_sm;

  -- Write Bundle:
  type t_NativeAxiWr_ms is record
    awaddr   : t_NativeAxiAddr;
    awlen    : t_AxiLen;
    awsize   : t_AxiSize;
    awburst  : t_AxiBurst;
    awvalid  : std_logic;
    wdata    : t_NativeAxiData;
    wstrb    : t_NativeAxiStrb;
    wlast    : std_logic;
    wvalid   : std_logic;
    bready   : std_logic;
  end record;
  type t_NativeAxiWr_sm is record
    awready  : std_logic;
    wready   : std_logic;
    bresp    : t_AxiResp;
    bvalid   : std_logic;
  end record;
  constant c_NativeAxiWrNull_ms : t_NativeAxiWr_ms := (
    awaddr   => (others => '0'),
    awlen    => c_AxiNullLen,
    awsize   => c_NativeAxiFullSize,
    awburst  => c_AxiNullBurst,
    awvalid  => '0',
    wdata    => (others => '0'),
    wstrb    => (others => '0'),
    wlast    => '0',
    wvalid   => '0',
    bready   => '0' );
  constant c_NativeAxiWrNull_sm : t_NativeAxiWr_sm := (
    awready  => '0',
    wready   => '0',
    bresp    => (others => '0'),
    bvalid   => '0' );
  type t_NativeAxiWr_v_ms is array (integer range <>) of t_NativeAxiWr_ms;
  type t_NativeAxiWr_v_sm is array (integer range <>) of t_NativeAxiWr_sm;

  -- Address Channel AR or AW:
  type t_NativeAxiA_od is record
    addr    : t_NativeAxiAddr;
    len     : t_AxiLen;
    size    : t_AxiSize;
    burst   : t_AxiBurst;
    valid   : std_logic;
  end record;
  type t_NativeAxiA_do is record
    ready   : std_logic;
  end record;
  constant c_NativeAxiANull_od : t_NativeAxiA_od := (
    addr    => (others => '0'),
    len     => c_AxiNullLen,
    size    => c_NativeAxiFullSize,
    burst   => c_AxiNullBurst,
    valid   => '0' );
  constant c_NativeAxiANull_do : t_NativeAxiA_do := (
    ready  => '0' );
  type t_NativeAxiA_v_od is array (integer range <>) of t_NativeAxiA_od;
  type t_NativeAxiA_v_do is array (integer range <>) of t_NativeAxiA_do;

  -- Read Channel R:
  type t_NativeAxiR_od is record
    data    : t_NativeAxiData;
    resp    : t_AxiResp;
    last    : std_logic;
    valid   : std_logic;
  end record;
  type t_NativeAxiR_do is record
    ready   : std_logic;
  end record;
  constant c_NativeAxiRNull_od : t_NativeAxiR_od := (
    data    => (others => '0'),
    resp    => (others => '0'),
    last    => '0',
    valid   => '0' );
  constant c_NativeAxiRNull_do : t_NativeAxiR_do := (
    ready   => '0' );
  type t_NativeAxiR_v_od is array (integer range <>) of t_NativeAxiR_od;
  type t_NativeAxiR_v_do is array (integer range <>) of t_NativeAxiR_do;

  -- Write Channel W:
  type t_NativeAxiW_od is record
    data    : t_NativeAxiData;
    strb    : t_NativeAxiStrb;
    last    : std_logic;
    valid   : std_logic;
  end record;
  type t_NativeAxiW_do is record
    ready   : std_logic;
  end record;
  constant c_NativeAxiWNull_od : t_NativeAxiW_od := (
    data    => (others => '0'),
    strb    => (others => '0'),
    last    => '0',
    valid   => '0' );
  constant c_NativeAxiWNull_do : t_NativeAxiW_do := (
    ready   => '0' );
  type t_NativeAxiW_v_od is array (integer range <>) of t_NativeAxiW_od;
  type t_NativeAxiW_v_do is array (integer range <>) of t_NativeAxiW_do;

  -- Write Response Channel B:
  type t_NativeAxiB_od is record
    resp    : t_AxiResp;
    valid   : std_logic;
  end record;
  type t_NativeAxiB_do is record
    ready   : std_logic;
  end record;
  constant c_NativeAxiBNull_od : t_NativeAxiB_od := (
    resp    => (others => '0'),
    valid   => '0' );
  constant c_NativeAxiBNull_do : t_NativeAxiB_do := (
    ready   => '0' );
  type t_NativeAxiB_v_od is array (integer range <>) of t_NativeAxiB_od;
  type t_NativeAxiB_v_do is array (integer range <>) of t_NativeAxiB_do;

  -- Conversion Functions:
  function f_nativeAxiSplitRd_ms(v_axi : t_NativeAxi_ms) return t_NativeAxiRd_ms;
  function f_nativeAxiSplitRd_sm(v_axi : t_NativeAxi_sm) return t_NativeAxiRd_sm;
  function f_nativeAxiSplitWr_ms(v_axi : t_NativeAxi_ms) return t_NativeAxiWr_ms;
  function f_nativeAxiSplitWr_sm(v_axi : t_NativeAxi_sm) return t_NativeAxiWr_sm;
  function f_nativeAxiJoinRdWr_ms(v_axiRd : t_NativeAxiRd_ms; v_axiWr : t_NativeAxiWr_ms) return t_NativeAxi_ms;
  function f_nativeAxiJoinRdWr_sm(v_axiRd : t_NativeAxiRd_sm; v_axiWr : t_NativeAxiWr_sm) return t_NativeAxi_sm;
  function f_nativeAxiRdSplitA_ms(v_axiRd : t_NativeAxiRd_ms) return t_NativeAxiA_od;
  function f_nativeAxiRdSplitA_sm(v_axiRd : t_NativeAxiRd_sm) return t_NativeAxiA_do;
  function f_nativeAxiRdSplitR_ms(v_axiRd : t_NativeAxiRd_ms) return t_NativeAxiR_do;
  function f_nativeAxiRdSplitR_sm(v_axiRd : t_NativeAxiRd_sm) return t_NativeAxiR_od;
  function f_nativeAxiRdJoin_ms(v_axiA : t_NativeAxiA_od; v_axiR : t_NativeAxiR_do) return t_NativeAxiRd_ms;
  function f_nativeAxiRdJoin_sm(v_axiA : t_NativeAxiA_do; v_axiR : t_NativeAxiR_od) return t_NativeAxiRd_sm;
  function f_nativeAxiWrSplitA_ms(v_axiWr : t_NativeAxiWr_ms) return t_NativeAxiA_od;
  function f_nativeAxiWrSplitA_sm(v_axiWr : t_NativeAxiWr_sm) return t_NativeAxiA_do;
  function f_nativeAxiWrSplitW_ms(v_axiWr : t_NativeAxiWr_ms) return t_NativeAxiW_od;
  function f_nativeAxiWrSplitW_sm(v_axiWr : t_NativeAxiWr_sm) return t_NativeAxiW_do;
  function f_nativeAxiWrSplitB_ms(v_axiWr : t_NativeAxiWr_ms) return t_NativeAxiB_do;
  function f_nativeAxiWrSplitB_sm(v_axiWr : t_NativeAxiWr_sm) return t_NativeAxiB_od;
  function f_nativeAxiWrJoin_ms(v_axiA : t_NativeAxiA_od; v_axiW : t_NativeAxiW_od; v_axiB : t_NativeAxiB_do) return t_NativeAxiWr_ms;
  function f_nativeAxiWrJoin_sm(v_axiA : t_NativeAxiA_do; v_axiW : t_NativeAxiW_do; v_axiB : t_NativeAxiB_od) return t_NativeAxiWr_sm;

end fosi_axi;


package body fosi_axi is

  -------------------------------------------------------------------------------
  -- Axi Interface: NativeAxi
  -------------------------------------------------------------------------------
  -- Conversion Functions:
  function f_nativeAxiSplitRd_ms(v_axi : t_NativeAxi_ms) return t_NativeAxiRd_ms is
    variable v_axiRd : t_NativeAxiRd_ms;
  begin
    v_axiRd.araddr   := v_axi.araddr;
    v_axiRd.arlen    := v_axi.arlen;
    v_axiRd.arsize   := v_axi.arsize;
    v_axiRd.arburst  := v_axi.arburst;
    v_axiRd.arvalid  := v_axi.arvalid;
    v_axiRd.rready   := v_axi.rready;
    return v_axiRd;
  end f_nativeAxiSplitRd_ms;

  function f_nativeAxiSplitRd_sm(v_axi : t_NativeAxi_sm) return t_NativeAxiRd_sm is
    variable v_axiRd : t_NativeAxiRd_sm;
  begin
    v_axiRd.arready  := v_axi.arready;
    v_axiRd.rdata    := v_axi.rdata;
    v_axiRd.rresp    := v_axi.rresp;
    v_axiRd.rlast    := v_axi.rlast;
    v_axiRd.rvalid   := v_axi.rvalid;
    return v_axiRd;
  end f_nativeAxiSplitRd_sm;


  function f_nativeAxiSplitWr_ms(v_axi : t_NativeAxi_ms) return t_NativeAxiWr_ms is
    variable v_axiWr : t_NativeAxiWr_ms;
  begin
    v_axiWr.awaddr   := v_axi.awaddr;
    v_axiWr.awlen    := v_axi.awlen;
    v_axiWr.awsize   := v_axi.awsize;
    v_axiWr.awburst  := v_axi.awburst;
    v_axiWr.awvalid  := v_axi.awvalid;
    v_axiWr.wdata    := v_axi.wdata;
    v_axiWr.wstrb    := v_axi.wstrb;
    v_axiWr.wlast    := v_axi.wlast;
    v_axiWr.wvalid   := v_axi.wvalid;
    v_axiWr.bready   := v_axi.bready;
    return v_axiWr;
  end f_nativeAxiSplitWr_ms;

  function f_nativeAxiSplitWr_sm(v_axi : t_NativeAxi_sm) return t_NativeAxiWr_sm is
    variable v_axiWr : t_NativeAxiWr_sm;
  begin
    v_axiWr.awready  := v_axi.awready;
    v_axiWr.wready   := v_axi.wready;
    v_axiWr.bresp    := v_axi.bresp;
    v_axiWr.bvalid   := v_axi.bvalid;
    return v_axiWr;
  end f_nativeAxiSplitWr_sm;


  function f_nativeAxiJoinRdWr_ms(v_axiRd : t_NativeAxiRd_ms; v_axiWr : t_NativeAxiWr_ms) return t_NativeAxi_ms is
    variable v_axi : t_NativeAxi_ms;
  begin
    v_axi.awaddr   := v_axiWr.awaddr;
    v_axi.awlen    := v_axiWr.awlen;
    v_axi.awsize   := v_axiWr.awsize;
    v_axi.awburst  := v_axiWr.awburst;
    v_axi.awvalid  := v_axiWr.awvalid;
    v_axi.wdata    := v_axiWr.wdata;
    v_axi.wstrb    := v_axiWr.wstrb;
    v_axi.wlast    := v_axiWr.wlast;
    v_axi.wvalid   := v_axiWr.wvalid;
    v_axi.bready   := v_axiWr.bready;
    v_axi.araddr   := v_axiRd.araddr;
    v_axi.arlen    := v_axiRd.arlen;
    v_axi.arsize   := v_axiRd.arsize;
    v_axi.arburst  := v_axiRd.arburst;
    v_axi.arvalid  := v_axiRd.arvalid;
    v_axi.rready   := v_axiRd.rready;
    return v_axi;
  end f_nativeAxiJoinRdWr_ms;

  function f_nativeAxiJoinRdWr_sm(v_axiRd : t_NativeAxiRd_sm; v_axiWr : t_NativeAxiWr_sm) return t_NativeAxi_sm is
    variable v_axi : t_NativeAxi_sm;
  begin
    v_axi.awready  := v_axiWr.awready;
    v_axi.wready   := v_axiWr.wready;
    v_axi.bresp    := v_axiWr.bresp;
    v_axi.bvalid   := v_axiWr.bvalid;
    v_axi.arready  := v_axiRd.arready;
    v_axi.rdata    := v_axiRd.rdata;
    v_axi.rresp    := v_axiRd.rresp;
    v_axi.rlast    := v_axiRd.rlast;
    v_axi.rvalid   := v_axiRd.rvalid;
    return v_axi;
  end f_nativeAxiJoinRdWr_sm;


  function f_nativeAxiRdSplitA_ms(v_axiRd : t_NativeAxiRd_ms) return t_NativeAxiA_od is
    variable v_axiA : t_NativeAxiA_od;
  begin
    v_axiA.addr   := v_axiRd.araddr;
    v_axiA.len    := v_axiRd.arlen;
    v_axiA.size   := v_axiRd.arsize;
    v_axiA.burst  := v_axiRd.arburst;
    v_axiA.valid  := v_axiRd.arvalid;
    return v_axiA;
  end f_nativeAxiRdSplitA_ms;

  function f_nativeAxiRdSplitA_sm(v_axiRd : t_NativeAxiRd_sm) return t_NativeAxiA_do is
    variable v_axiA : t_NativeAxiA_do;
  begin
    v_axiA.ready := v_axiRd.arready;
    return v_axiA;
  end f_nativeAxiRdSplitA_sm;


  function f_nativeAxiRdSplitR_ms(v_axiRd : t_NativeAxiRd_ms) return t_NativeAxiR_do is
    variable v_axiR : t_NativeAxiR_do;
  begin
    v_axiR.ready  := v_axiRd.rready;
    return v_axiR;
  end f_nativeAxiRdSplitR_ms;

  function f_nativeAxiRdSplitR_sm(v_axiRd : t_NativeAxiRd_sm) return t_NativeAxiR_od is
    variable v_axiR : t_NativeAxiR_od;
  begin
    v_axiR.data   := v_axiRd.rdata;
    v_axiR.resp   := v_axiRd.rresp;
    v_axiR.last   := v_axiRd.rlast;
    v_axiR.valid  := v_axiRd.rvalid;
    return v_axiR;
  end f_nativeAxiRdSplitR_sm;


  function f_nativeAxiRdJoin_ms(v_axiA : t_NativeAxiA_od; v_axiR : t_NativeAxiR_do) return t_NativeAxiRd_ms is
    variable v_axiRd : t_NativeAxiRd_ms;
  begin
    v_axiRd.araddr   := v_axiA.addr;
    v_axiRd.arlen    := v_axiA.len;
    v_axiRd.arsize   := v_axiA.size;
    v_axiRd.arburst  := v_axiA.burst;
    v_axiRd.arvalid  := v_axiA.valid;
    v_axiRd.rready   := v_axiR.ready;
    return v_axiRd;
  end f_nativeAxiRdJoin_ms;

  function f_nativeAxiRdJoin_sm(v_axiA : t_NativeAxiA_do; v_axiR : t_NativeAxiR_od) return t_NativeAxiRd_sm is
    variable v_axiRd : t_NativeAxiRd_sm;
  begin
    v_axiRd.arready  := v_axiA.ready;
    v_axiRd.rdata    := v_axiR.data;
    v_axiRd.rresp    := v_axiR.resp;
    v_axiRd.rlast    := v_axiR.last;
    v_axiRd.rvalid   := v_axiR.valid;
    return v_axiRd;
  end f_nativeAxiRdJoin_sm;


  function f_nativeAxiWrSplitA_ms(v_axiWr : t_NativeAxiWr_ms) return t_NativeAxiA_od is
    variable v_axiA : t_NativeAxiA_od;
  begin
      v_axiA.addr   := v_axiWr.awaddr;
      v_axiA.len    := v_axiWr.awlen;
      v_axiA.size   := v_axiWr.awsize;
      v_axiA.burst  := v_axiWr.awburst;
      v_axiA.valid  := v_axiWr.awvalid;
    return v_axiA;
  end f_nativeAxiWrSplitA_ms;

  function f_nativeAxiWrSplitA_sm(v_axiWr : t_NativeAxiWr_sm) return t_NativeAxiA_do is
    variable v_axiA : t_NativeAxiA_do;
  begin
    v_axiA.ready := v_axiWr.awready;
    return v_axiA;
  end f_nativeAxiWrSplitA_sm;


  function f_nativeAxiWrSplitW_ms(v_axiWr : t_NativeAxiWr_ms) return t_NativeAxiW_od is
    variable v_axiW : t_NativeAxiW_od;
  begin
    v_axiW.data     := v_axiWr.wdata;
    v_axiW.strb     := v_axiWr.wstrb;
    v_axiW.last     := v_axiWr.wlast;
    v_axiW.valid    := v_axiWr.wvalid;
    return v_axiW;
  end f_nativeAxiWrSplitW_ms;

  function f_nativeAxiWrSplitW_sm(v_axiWr : t_NativeAxiWr_sm) return t_NativeAxiW_do is
    variable v_axiW : t_NativeAxiW_do;
  begin
    v_axiW.ready := v_axiWr.wready;
    return v_axiW;
  end f_nativeAxiWrSplitW_sm;


  function f_nativeAxiWrSplitB_ms(v_axiWr : t_NativeAxiWr_ms) return t_NativeAxiB_do is
    variable v_axiB : t_NativeAxiB_do;
  begin
    v_axiB.ready   := v_axiWr.bready;
    return v_axiB;
  end f_nativeAxiWrSplitB_ms;

  function f_nativeAxiWrSplitB_sm(v_axiWr : t_NativeAxiWr_sm) return t_NativeAxiB_od is
    variable v_axiB : t_NativeAxiB_od;
  begin
    v_axiB.resp    := v_axiWr.bresp;
    v_axiB.valid   := v_axiWr.bvalid;
    return v_axiB;
  end f_nativeAxiWrSplitB_sm;


  function f_nativeAxiWrJoin_ms(v_axiA : t_NativeAxiA_od; v_axiW : t_NativeAxiW_od; v_axiB : t_NativeAxiB_do) return t_NativeAxiWr_ms is
    variable v_axiWr : t_NativeAxiWr_ms;
  begin
    v_axiWr.awaddr   := v_axiA.addr;
    v_axiWr.awlen    := v_axiA.len;
    v_axiWr.awsize   := v_axiA.size;
    v_axiWr.awburst  := v_axiA.burst;
    v_axiWr.awvalid  := v_axiA.valid;
    v_axiWr.wdata    := v_axiW.data;
    v_axiWr.wstrb    := v_axiW.strb;
    v_axiWr.wlast    := v_axiW.last;
    v_axiWr.wvalid   := v_axiW.valid;
    v_axiWr.bready   := v_axiB.ready;
    return v_axiWr;
  end f_nativeAxiWrJoin_ms;

  function f_nativeAxiWrJoin_sm(v_axiA : t_NativeAxiA_do; v_axiW : t_NativeAxiW_do; v_axiB : t_NativeAxiB_od) return t_NativeAxiWr_sm is
    variable v_axiWr : t_NativeAxiWr_sm;
  begin
    v_axiWr.awready  := v_axiA.ready;
    v_axiWr.wready   := v_axiW.ready;
    v_axiWr.bresp    := v_axiB.resp;
    v_axiWr.bvalid   := v_axiB.valid;
    return v_axiWr;
  end f_nativeAxiWrJoin_sm;

end fosi_axi;
