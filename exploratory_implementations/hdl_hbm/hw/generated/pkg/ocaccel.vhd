library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto;
use work.dfaccto_axi;


package ocaccel is

  subtype t_AxiCtrlData is unsigned (32-1 downto 0);
  type t_AxiCtrlData_v is array (integer range <>) of ocaccel.t_AxiCtrlData;

  constant c_AxiCtrlDataNull : ocaccel.t_AxiCtrlData
            := to_unsigned(0, ocaccel.t_AxiCtrlData'length);

  subtype t_AxiCtrlStrb is unsigned (4-1 downto 0);
  type t_AxiCtrlStrb_v is array (integer range <>) of ocaccel.t_AxiCtrlStrb;

  constant c_AxiCtrlStrbNull : ocaccel.t_AxiCtrlStrb
            := to_unsigned(0, ocaccel.t_AxiCtrlStrb'length);

  subtype t_AxiCtrlAddr is unsigned (32-1 downto 0);
  type t_AxiCtrlAddr_v is array (integer range <>) of ocaccel.t_AxiCtrlAddr;

  constant c_AxiCtrlAddrNull : ocaccel.t_AxiCtrlAddr
            := to_unsigned(0, ocaccel.t_AxiCtrlAddr'length);

  subtype t_AxiCtrlWordIdx is unsigned (2-1 downto 0);
  type t_AxiCtrlWordIdx_v is array (integer range <>) of ocaccel.t_AxiCtrlWordIdx;

  constant c_AxiCtrlWordIdxNull : ocaccel.t_AxiCtrlWordIdx
            := to_unsigned(0, ocaccel.t_AxiCtrlWordIdx'length);

  subtype t_AxiCtrlWordAddr is unsigned (30-1 downto 0);
  type t_AxiCtrlWordAddr_v is array (integer range <>) of ocaccel.t_AxiCtrlWordAddr;

  constant c_AxiCtrlWordAddrNull : ocaccel.t_AxiCtrlWordAddr
            := to_unsigned(0, ocaccel.t_AxiCtrlWordAddr'length);

  constant c_AxiCtrlFullSize : dfaccto_axi.t_AxiSize
            := to_unsigned(2, dfaccto_axi.t_AxiSize'length);

  type t_AxiCtrl_ms is record
    awaddr   : ocaccel.t_AxiCtrlAddr;
    awvalid  : dfaccto.t_Logic;
    wdata    : ocaccel.t_AxiCtrlData;
    wstrb    : ocaccel.t_AxiCtrlStrb;
    wvalid   : dfaccto.t_Logic;
    bready   : dfaccto.t_Logic;
    araddr   : ocaccel.t_AxiCtrlAddr;
    arvalid  : dfaccto.t_Logic;
    rready   : dfaccto.t_Logic;
  end record;
  type t_AxiCtrl_sm is record
    awready  : dfaccto.t_Logic;
    wready   : dfaccto.t_Logic;
    bresp    : dfaccto_axi.t_AxiResp;
    bvalid   : dfaccto.t_Logic;
    arready  : dfaccto.t_Logic;
    rdata    : ocaccel.t_AxiCtrlData;
    rresp    : dfaccto_axi.t_AxiResp;
    rvalid   : dfaccto.t_Logic;
  end record;
  type t_AxiCtrl_v_ms is array (integer range <>) of ocaccel.t_AxiCtrl_ms;
  type t_AxiCtrl_v_sm is array (integer range <>) of ocaccel.t_AxiCtrl_sm;

  constant c_AxiCtrlNull_ms : ocaccel.t_AxiCtrl_ms
            := -- (ocaccel).t_AxiCtrl   |   {'awsize': 2, 'arsize': 2}
               (awaddr   => ocaccel.c_AxiCtrlAddrNull,
                awvalid  => dfaccto.c_LogicNull,
                wdata    => ocaccel.c_AxiCtrlDataNull,
                wstrb    => ocaccel.c_AxiCtrlStrbNull,
                wvalid   => dfaccto.c_LogicNull,
                bready   => dfaccto.c_LogicNull,
                araddr   => ocaccel.c_AxiCtrlAddrNull,
                arvalid  => dfaccto.c_LogicNull,
                rready   => dfaccto.c_LogicNull);
  constant c_AxiCtrlNull_sm : ocaccel.t_AxiCtrl_sm
            := (awready  => dfaccto.c_LogicNull,
                wready   => dfaccto.c_LogicNull,
                bresp    => dfaccto_axi.c_AxiRespNull,
                bvalid   => dfaccto.c_LogicNull,
                arready  => dfaccto.c_LogicNull,
                rdata    => ocaccel.c_AxiCtrlDataNull,
                rresp    => dfaccto_axi.c_AxiRespNull,
                rvalid   => dfaccto.c_LogicNull);

  subtype t_AxiHostData is unsigned (1024-1 downto 0);
  type t_AxiHostData_v is array (integer range <>) of ocaccel.t_AxiHostData;

  constant c_AxiHostDataNull : ocaccel.t_AxiHostData
            := to_unsigned(0, ocaccel.t_AxiHostData'length);

  subtype t_AxiHostStrb is unsigned (128-1 downto 0);
  type t_AxiHostStrb_v is array (integer range <>) of ocaccel.t_AxiHostStrb;

  constant c_AxiHostStrbNull : ocaccel.t_AxiHostStrb
            := to_unsigned(0, ocaccel.t_AxiHostStrb'length);

  subtype t_AxiHostAddr is unsigned (64-1 downto 0);
  type t_AxiHostAddr_v is array (integer range <>) of ocaccel.t_AxiHostAddr;

  constant c_AxiHostAddrNull : ocaccel.t_AxiHostAddr
            := to_unsigned(0, ocaccel.t_AxiHostAddr'length);

  subtype t_AxiHostWordIdx is unsigned (7-1 downto 0);
  type t_AxiHostWordIdx_v is array (integer range <>) of ocaccel.t_AxiHostWordIdx;

  constant c_AxiHostWordIdxNull : ocaccel.t_AxiHostWordIdx
            := to_unsigned(0, ocaccel.t_AxiHostWordIdx'length);

  subtype t_AxiHostWordAddr is unsigned (57-1 downto 0);
  type t_AxiHostWordAddr_v is array (integer range <>) of ocaccel.t_AxiHostWordAddr;

  constant c_AxiHostWordAddrNull : ocaccel.t_AxiHostWordAddr
            := to_unsigned(0, ocaccel.t_AxiHostWordAddr'length);

  constant c_AxiHostFullSize : dfaccto_axi.t_AxiSize
            := to_unsigned(7, dfaccto_axi.t_AxiSize'length);

  subtype t_AxiHostId is unsigned (1-1 downto 0);
  type t_AxiHostId_v is array (integer range <>) of ocaccel.t_AxiHostId;

  constant c_AxiHostIdNull : ocaccel.t_AxiHostId
            := to_unsigned(0, ocaccel.t_AxiHostId'length);

  subtype t_AxiHostARUser is unsigned (9-1 downto 0);
  type t_AxiHostARUser_v is array (integer range <>) of ocaccel.t_AxiHostARUser;

  constant c_AxiHostARUserNull : ocaccel.t_AxiHostARUser
            := to_unsigned(0, ocaccel.t_AxiHostARUser'length);

  subtype t_AxiHostAWUser is unsigned (9-1 downto 0);
  type t_AxiHostAWUser_v is array (integer range <>) of ocaccel.t_AxiHostAWUser;

  constant c_AxiHostAWUserNull : ocaccel.t_AxiHostAWUser
            := to_unsigned(0, ocaccel.t_AxiHostAWUser'length);

  subtype t_AxiHostRUser is unsigned (9-1 downto 0);
  type t_AxiHostRUser_v is array (integer range <>) of ocaccel.t_AxiHostRUser;

  constant c_AxiHostRUserNull : ocaccel.t_AxiHostRUser
            := to_unsigned(0, ocaccel.t_AxiHostRUser'length);

  subtype t_AxiHostWUser is unsigned (9-1 downto 0);
  type t_AxiHostWUser_v is array (integer range <>) of ocaccel.t_AxiHostWUser;

  constant c_AxiHostWUserNull : ocaccel.t_AxiHostWUser
            := to_unsigned(0, ocaccel.t_AxiHostWUser'length);

  subtype t_AxiHostBUser is unsigned (9-1 downto 0);
  type t_AxiHostBUser_v is array (integer range <>) of ocaccel.t_AxiHostBUser;

  constant c_AxiHostBUserNull : ocaccel.t_AxiHostBUser
            := to_unsigned(0, ocaccel.t_AxiHostBUser'length);

  subtype t_AxiHostLen is unsigned (8-1 downto 0);
  type t_AxiHostLen_v is array (integer range <>) of ocaccel.t_AxiHostLen;

  constant c_AxiHostLenNull : ocaccel.t_AxiHostLen
            := to_unsigned(0, ocaccel.t_AxiHostLen'length);

  type t_AxiHost_ms is record
    awaddr   : ocaccel.t_AxiHostAddr;
    awlen    : ocaccel.t_AxiHostLen;
    awsize   : dfaccto_axi.t_AxiSize;
    awburst  : dfaccto_axi.t_AxiBurst;
    awlock   : dfaccto_axi.t_AxiLock;
    awcache  : dfaccto_axi.t_AxiCache;
    awprot   : dfaccto_axi.t_AxiProt;
    awqos    : dfaccto_axi.t_AxiQos;
    awregion : dfaccto_axi.t_AxiRegion;
    awid     : ocaccel.t_AxiHostId;
    awuser   : ocaccel.t_AxiHostAWUser;
    awvalid  : dfaccto.t_Logic;
    wdata    : ocaccel.t_AxiHostData;
    wstrb    : ocaccel.t_AxiHostStrb;
    wlast    : dfaccto.t_Logic;
    wuser   : ocaccel.t_AxiHostWUser;
    wvalid   : dfaccto.t_Logic;
    bready   : dfaccto.t_Logic;
    araddr   : ocaccel.t_AxiHostAddr;
    arlen    : ocaccel.t_AxiHostLen;
    arsize   : dfaccto_axi.t_AxiSize;
    arburst  : dfaccto_axi.t_AxiBurst;
    arlock   : dfaccto_axi.t_AxiLock;
    arcache  : dfaccto_axi.t_AxiCache;
    arprot   : dfaccto_axi.t_AxiProt;
    arqos    : dfaccto_axi.t_AxiQos;
    arregion : dfaccto_axi.t_AxiRegion;
    arid     : ocaccel.t_AxiHostId;
    aruser   : ocaccel.t_AxiHostARUser;
    arvalid  : dfaccto.t_Logic;
    rready   : dfaccto.t_Logic;
  end record;
  type t_AxiHost_sm is record
    awready  : dfaccto.t_Logic;
    wready   : dfaccto.t_Logic;
    bresp    : dfaccto_axi.t_AxiResp;
    bid      : ocaccel.t_AxiHostId;
    buser   : ocaccel.t_AxiHostBUser;
    bvalid   : dfaccto.t_Logic;
    arready  : dfaccto.t_Logic;
    rdata    : ocaccel.t_AxiHostData;
    rresp    : dfaccto_axi.t_AxiResp;
    rlast    : dfaccto.t_Logic;
    rid      : ocaccel.t_AxiHostId;
    ruser   : ocaccel.t_AxiHostRUser;
    rvalid   : dfaccto.t_Logic;
  end record;
  type t_AxiHost_v_ms is array (integer range <>) of ocaccel.t_AxiHost_ms;
  type t_AxiHost_v_sm is array (integer range <>) of ocaccel.t_AxiHost_sm;

  constant c_AxiHostNull_ms : ocaccel.t_AxiHost_ms
            := -- (ocaccel).t_AxiHost   |   {'awsize': 7, 'arsize': 7}
               (awaddr   => ocaccel.c_AxiHostAddrNull,
                awlen    => ocaccel.c_AxiHostLenNull,
                awsize   => to_unsigned(7, dfaccto_axi.t_AxiSize'length),
                awburst  => dfaccto_axi.c_AxiBurstNull,
                awlock   => dfaccto_axi.c_AxiLockNull,
                awcache  => dfaccto_axi.c_AxiCacheNull,
                awprot   => dfaccto_axi.c_AxiProtNull,
                awqos    => dfaccto_axi.c_AxiQosNull,
                awregion => dfaccto_axi.c_AxiRegionNull,
                awid     => ocaccel.c_AxiHostIdNull,
                awuser   => ocaccel.c_AxiHostAWUserNull,
                awvalid  => dfaccto.c_LogicNull,
                wdata    => ocaccel.c_AxiHostDataNull,
                wstrb    => ocaccel.c_AxiHostStrbNull,
                wlast    => dfaccto.c_LogicNull,
                wuser    => ocaccel.c_AxiHostWUserNull,
                wvalid   => dfaccto.c_LogicNull,
                bready   => dfaccto.c_LogicNull,
                araddr   => ocaccel.c_AxiHostAddrNull,
                arlen    => ocaccel.c_AxiHostLenNull,
                arsize   => to_unsigned(7, dfaccto_axi.t_AxiSize'length),
                arburst  => dfaccto_axi.c_AxiBurstNull,
                arlock   => dfaccto_axi.c_AxiLockNull,
                arcache  => dfaccto_axi.c_AxiCacheNull,
                arprot   => dfaccto_axi.c_AxiProtNull,
                arqos    => dfaccto_axi.c_AxiQosNull,
                arregion => dfaccto_axi.c_AxiRegionNull,
                arid     => ocaccel.c_AxiHostIdNull,
                aruser   => ocaccel.c_AxiHostARUserNull,
                arvalid  => dfaccto.c_LogicNull,
                rready   => dfaccto.c_LogicNull);
  constant c_AxiHostNull_sm : ocaccel.t_AxiHost_sm
            := (awready  => dfaccto.c_LogicNull,
                wready   => dfaccto.c_LogicNull,
                bid      => ocaccel.c_AxiHostIdNull,
                buser    => ocaccel.c_AxiHostBUserNull,
                bresp    => dfaccto_axi.c_AxiRespNull,
                bvalid   => dfaccto.c_LogicNull,
                arready  => dfaccto.c_LogicNull,
                rdata    => ocaccel.c_AxiHostDataNull,
                rresp    => dfaccto_axi.c_AxiRespNull,
                rlast    => dfaccto.c_LogicNull,
                rid      => ocaccel.c_AxiHostIdNull,
                ruser    => ocaccel.c_AxiHostRUserNull,
                rvalid   => dfaccto.c_LogicNull);

  subtype t_AxiDdrData is unsigned (512-1 downto 0);
  type t_AxiDdrData_v is array (integer range <>) of ocaccel.t_AxiDdrData;

  constant c_AxiDdrDataNull : ocaccel.t_AxiDdrData
            := to_unsigned(0, ocaccel.t_AxiDdrData'length);

  subtype t_AxiDdrStrb is unsigned (64-1 downto 0);
  type t_AxiDdrStrb_v is array (integer range <>) of ocaccel.t_AxiDdrStrb;

  constant c_AxiDdrStrbNull : ocaccel.t_AxiDdrStrb
            := to_unsigned(0, ocaccel.t_AxiDdrStrb'length);

  subtype t_AxiDdrAddr is unsigned (33-1 downto 0);
  type t_AxiDdrAddr_v is array (integer range <>) of ocaccel.t_AxiDdrAddr;

  constant c_AxiDdrAddrNull : ocaccel.t_AxiDdrAddr
            := to_unsigned(0, ocaccel.t_AxiDdrAddr'length);

  subtype t_AxiDdrWordIdx is unsigned (6-1 downto 0);
  type t_AxiDdrWordIdx_v is array (integer range <>) of ocaccel.t_AxiDdrWordIdx;

  constant c_AxiDdrWordIdxNull : ocaccel.t_AxiDdrWordIdx
            := to_unsigned(0, ocaccel.t_AxiDdrWordIdx'length);

  subtype t_AxiDdrWordAddr is unsigned (27-1 downto 0);
  type t_AxiDdrWordAddr_v is array (integer range <>) of ocaccel.t_AxiDdrWordAddr;

  constant c_AxiDdrWordAddrNull : ocaccel.t_AxiDdrWordAddr
            := to_unsigned(0, ocaccel.t_AxiDdrWordAddr'length);

  constant c_AxiDdrFullSize : dfaccto_axi.t_AxiSize
            := to_unsigned(6, dfaccto_axi.t_AxiSize'length);

  subtype t_AxiDdrId is unsigned (4-1 downto 0);
  type t_AxiDdrId_v is array (integer range <>) of ocaccel.t_AxiDdrId;

  constant c_AxiDdrIdNull : ocaccel.t_AxiDdrId
            := to_unsigned(0, ocaccel.t_AxiDdrId'length);

  subtype t_AxiDdrARUser is unsigned (1-1 downto 0);
  type t_AxiDdrARUser_v is array (integer range <>) of ocaccel.t_AxiDdrARUser;

  constant c_AxiDdrARUserNull : ocaccel.t_AxiDdrARUser
            := to_unsigned(0, ocaccel.t_AxiDdrARUser'length);

  subtype t_AxiDdrAWUser is unsigned (1-1 downto 0);
  type t_AxiDdrAWUser_v is array (integer range <>) of ocaccel.t_AxiDdrAWUser;

  constant c_AxiDdrAWUserNull : ocaccel.t_AxiDdrAWUser
            := to_unsigned(0, ocaccel.t_AxiDdrAWUser'length);

  subtype t_AxiDdrRUser is unsigned (1-1 downto 0);
  type t_AxiDdrRUser_v is array (integer range <>) of ocaccel.t_AxiDdrRUser;

  constant c_AxiDdrRUserNull : ocaccel.t_AxiDdrRUser
            := to_unsigned(0, ocaccel.t_AxiDdrRUser'length);

  subtype t_AxiDdrWUser is unsigned (1-1 downto 0);
  type t_AxiDdrWUser_v is array (integer range <>) of ocaccel.t_AxiDdrWUser;

  constant c_AxiDdrWUserNull : ocaccel.t_AxiDdrWUser
            := to_unsigned(0, ocaccel.t_AxiDdrWUser'length);

  subtype t_AxiDdrBUser is unsigned (1-1 downto 0);
  type t_AxiDdrBUser_v is array (integer range <>) of ocaccel.t_AxiDdrBUser;

  constant c_AxiDdrBUserNull : ocaccel.t_AxiDdrBUser
            := to_unsigned(0, ocaccel.t_AxiDdrBUser'length);

  subtype t_AxiDdrLen is unsigned (8-1 downto 0);
  type t_AxiDdrLen_v is array (integer range <>) of ocaccel.t_AxiDdrLen;

  constant c_AxiDdrLenNull : ocaccel.t_AxiDdrLen
            := to_unsigned(0, ocaccel.t_AxiDdrLen'length);

  type t_AxiDdr_ms is record
    awaddr   : ocaccel.t_AxiDdrAddr;
    awlen    : ocaccel.t_AxiDdrLen;
    awsize   : dfaccto_axi.t_AxiSize;
    awburst  : dfaccto_axi.t_AxiBurst;
    awlock   : dfaccto_axi.t_AxiLock;
    awcache  : dfaccto_axi.t_AxiCache;
    awprot   : dfaccto_axi.t_AxiProt;
    awqos    : dfaccto_axi.t_AxiQos;
    awregion : dfaccto_axi.t_AxiRegion;
    awid     : ocaccel.t_AxiDdrId;
    awuser   : ocaccel.t_AxiDdrAWUser;
    awvalid  : dfaccto.t_Logic;
    wdata    : ocaccel.t_AxiDdrData;
    wstrb    : ocaccel.t_AxiDdrStrb;
    wlast    : dfaccto.t_Logic;
    wuser   : ocaccel.t_AxiDdrWUser;
    wvalid   : dfaccto.t_Logic;
    bready   : dfaccto.t_Logic;
    araddr   : ocaccel.t_AxiDdrAddr;
    arlen    : ocaccel.t_AxiDdrLen;
    arsize   : dfaccto_axi.t_AxiSize;
    arburst  : dfaccto_axi.t_AxiBurst;
    arlock   : dfaccto_axi.t_AxiLock;
    arcache  : dfaccto_axi.t_AxiCache;
    arprot   : dfaccto_axi.t_AxiProt;
    arqos    : dfaccto_axi.t_AxiQos;
    arregion : dfaccto_axi.t_AxiRegion;
    arid     : ocaccel.t_AxiDdrId;
    aruser   : ocaccel.t_AxiDdrARUser;
    arvalid  : dfaccto.t_Logic;
    rready   : dfaccto.t_Logic;
  end record;
  type t_AxiDdr_sm is record
    awready  : dfaccto.t_Logic;
    wready   : dfaccto.t_Logic;
    bresp    : dfaccto_axi.t_AxiResp;
    bid      : ocaccel.t_AxiDdrId;
    buser   : ocaccel.t_AxiDdrBUser;
    bvalid   : dfaccto.t_Logic;
    arready  : dfaccto.t_Logic;
    rdata    : ocaccel.t_AxiDdrData;
    rresp    : dfaccto_axi.t_AxiResp;
    rlast    : dfaccto.t_Logic;
    rid      : ocaccel.t_AxiDdrId;
    ruser   : ocaccel.t_AxiDdrRUser;
    rvalid   : dfaccto.t_Logic;
  end record;
  type t_AxiDdr_v_ms is array (integer range <>) of ocaccel.t_AxiDdr_ms;
  type t_AxiDdr_v_sm is array (integer range <>) of ocaccel.t_AxiDdr_sm;

  constant c_AxiDdrNull_ms : ocaccel.t_AxiDdr_ms
            := -- (ocaccel).t_AxiDdr   |   {'awsize': 6, 'arsize': 6}
               (awaddr   => ocaccel.c_AxiDdrAddrNull,
                awlen    => ocaccel.c_AxiDdrLenNull,
                awsize   => to_unsigned(6, dfaccto_axi.t_AxiSize'length),
                awburst  => dfaccto_axi.c_AxiBurstNull,
                awlock   => dfaccto_axi.c_AxiLockNull,
                awcache  => dfaccto_axi.c_AxiCacheNull,
                awprot   => dfaccto_axi.c_AxiProtNull,
                awqos    => dfaccto_axi.c_AxiQosNull,
                awregion => dfaccto_axi.c_AxiRegionNull,
                awid     => ocaccel.c_AxiDdrIdNull,
                awuser   => ocaccel.c_AxiDdrAWUserNull,
                awvalid  => dfaccto.c_LogicNull,
                wdata    => ocaccel.c_AxiDdrDataNull,
                wstrb    => ocaccel.c_AxiDdrStrbNull,
                wlast    => dfaccto.c_LogicNull,
                wuser    => ocaccel.c_AxiDdrWUserNull,
                wvalid   => dfaccto.c_LogicNull,
                bready   => dfaccto.c_LogicNull,
                araddr   => ocaccel.c_AxiDdrAddrNull,
                arlen    => ocaccel.c_AxiDdrLenNull,
                arsize   => to_unsigned(6, dfaccto_axi.t_AxiSize'length),
                arburst  => dfaccto_axi.c_AxiBurstNull,
                arlock   => dfaccto_axi.c_AxiLockNull,
                arcache  => dfaccto_axi.c_AxiCacheNull,
                arprot   => dfaccto_axi.c_AxiProtNull,
                arqos    => dfaccto_axi.c_AxiQosNull,
                arregion => dfaccto_axi.c_AxiRegionNull,
                arid     => ocaccel.c_AxiDdrIdNull,
                aruser   => ocaccel.c_AxiDdrARUserNull,
                arvalid  => dfaccto.c_LogicNull,
                rready   => dfaccto.c_LogicNull);
  constant c_AxiDdrNull_sm : ocaccel.t_AxiDdr_sm
            := (awready  => dfaccto.c_LogicNull,
                wready   => dfaccto.c_LogicNull,
                bid      => ocaccel.c_AxiDdrIdNull,
                buser    => ocaccel.c_AxiDdrBUserNull,
                bresp    => dfaccto_axi.c_AxiRespNull,
                bvalid   => dfaccto.c_LogicNull,
                arready  => dfaccto.c_LogicNull,
                rdata    => ocaccel.c_AxiDdrDataNull,
                rresp    => dfaccto_axi.c_AxiRespNull,
                rlast    => dfaccto.c_LogicNull,
                rid      => ocaccel.c_AxiDdrIdNull,
                ruser    => ocaccel.c_AxiDdrRUserNull,
                rvalid   => dfaccto.c_LogicNull);

  subtype t_AxiHbmData is unsigned (256-1 downto 0);
  type t_AxiHbmData_v is array (integer range <>) of ocaccel.t_AxiHbmData;

  constant c_AxiHbmDataNull : ocaccel.t_AxiHbmData
            := to_unsigned(0, ocaccel.t_AxiHbmData'length);

  subtype t_AxiHbmStrb is unsigned (32-1 downto 0);
  type t_AxiHbmStrb_v is array (integer range <>) of ocaccel.t_AxiHbmStrb;

  constant c_AxiHbmStrbNull : ocaccel.t_AxiHbmStrb
            := to_unsigned(0, ocaccel.t_AxiHbmStrb'length);

  subtype t_AxiHbmAddr is unsigned (34-1 downto 0);
  type t_AxiHbmAddr_v is array (integer range <>) of ocaccel.t_AxiHbmAddr;

  constant c_AxiHbmAddrNull : ocaccel.t_AxiHbmAddr
            := to_unsigned(0, ocaccel.t_AxiHbmAddr'length);

  subtype t_AxiHbmWordIdx is unsigned (5-1 downto 0);
  type t_AxiHbmWordIdx_v is array (integer range <>) of ocaccel.t_AxiHbmWordIdx;

  constant c_AxiHbmWordIdxNull : ocaccel.t_AxiHbmWordIdx
            := to_unsigned(0, ocaccel.t_AxiHbmWordIdx'length);

  subtype t_AxiHbmWordAddr is unsigned (29-1 downto 0);
  type t_AxiHbmWordAddr_v is array (integer range <>) of ocaccel.t_AxiHbmWordAddr;

  constant c_AxiHbmWordAddrNull : ocaccel.t_AxiHbmWordAddr
            := to_unsigned(0, ocaccel.t_AxiHbmWordAddr'length);

  constant c_AxiHbmFullSize : dfaccto_axi.t_AxiSize
            := to_unsigned(5, dfaccto_axi.t_AxiSize'length);

  subtype t_AxiHbmId is unsigned (6-1 downto 0);
  type t_AxiHbmId_v is array (integer range <>) of ocaccel.t_AxiHbmId;

  constant c_AxiHbmIdNull : ocaccel.t_AxiHbmId
            := to_unsigned(0, ocaccel.t_AxiHbmId'length);

  subtype t_AxiHbmARUser is unsigned (1-1 downto 0);
  type t_AxiHbmARUser_v is array (integer range <>) of ocaccel.t_AxiHbmARUser;

  constant c_AxiHbmARUserNull : ocaccel.t_AxiHbmARUser
            := to_unsigned(0, ocaccel.t_AxiHbmARUser'length);

  subtype t_AxiHbmAWUser is unsigned (1-1 downto 0);
  type t_AxiHbmAWUser_v is array (integer range <>) of ocaccel.t_AxiHbmAWUser;

  constant c_AxiHbmAWUserNull : ocaccel.t_AxiHbmAWUser
            := to_unsigned(0, ocaccel.t_AxiHbmAWUser'length);

  subtype t_AxiHbmRUser is unsigned (1-1 downto 0);
  type t_AxiHbmRUser_v is array (integer range <>) of ocaccel.t_AxiHbmRUser;

  constant c_AxiHbmRUserNull : ocaccel.t_AxiHbmRUser
            := to_unsigned(0, ocaccel.t_AxiHbmRUser'length);

  subtype t_AxiHbmWUser is unsigned (1-1 downto 0);
  type t_AxiHbmWUser_v is array (integer range <>) of ocaccel.t_AxiHbmWUser;

  constant c_AxiHbmWUserNull : ocaccel.t_AxiHbmWUser
            := to_unsigned(0, ocaccel.t_AxiHbmWUser'length);

  subtype t_AxiHbmBUser is unsigned (1-1 downto 0);
  type t_AxiHbmBUser_v is array (integer range <>) of ocaccel.t_AxiHbmBUser;

  constant c_AxiHbmBUserNull : ocaccel.t_AxiHbmBUser
            := to_unsigned(0, ocaccel.t_AxiHbmBUser'length);

  subtype t_AxiHbmLen is unsigned (8-1 downto 0);
  type t_AxiHbmLen_v is array (integer range <>) of ocaccel.t_AxiHbmLen;

  constant c_AxiHbmLenNull : ocaccel.t_AxiHbmLen
            := to_unsigned(0, ocaccel.t_AxiHbmLen'length);

  type t_AxiHbm_ms is record
    awaddr   : ocaccel.t_AxiHbmAddr;
    awlen    : ocaccel.t_AxiHbmLen;
    awsize   : dfaccto_axi.t_AxiSize;
    awburst  : dfaccto_axi.t_AxiBurst;
    awlock   : dfaccto_axi.t_AxiLock;
    awcache  : dfaccto_axi.t_AxiCache;
    awprot   : dfaccto_axi.t_AxiProt;
    awqos    : dfaccto_axi.t_AxiQos;
    awregion : dfaccto_axi.t_AxiRegion;
    awid     : ocaccel.t_AxiHbmId;
    awuser   : ocaccel.t_AxiHbmAWUser;
    awvalid  : dfaccto.t_Logic;
    wdata    : ocaccel.t_AxiHbmData;
    wstrb    : ocaccel.t_AxiHbmStrb;
    wlast    : dfaccto.t_Logic;
    wuser   : ocaccel.t_AxiHbmWUser;
    wvalid   : dfaccto.t_Logic;
    bready   : dfaccto.t_Logic;
    araddr   : ocaccel.t_AxiHbmAddr;
    arlen    : ocaccel.t_AxiHbmLen;
    arsize   : dfaccto_axi.t_AxiSize;
    arburst  : dfaccto_axi.t_AxiBurst;
    arlock   : dfaccto_axi.t_AxiLock;
    arcache  : dfaccto_axi.t_AxiCache;
    arprot   : dfaccto_axi.t_AxiProt;
    arqos    : dfaccto_axi.t_AxiQos;
    arregion : dfaccto_axi.t_AxiRegion;
    arid     : ocaccel.t_AxiHbmId;
    aruser   : ocaccel.t_AxiHbmARUser;
    arvalid  : dfaccto.t_Logic;
    rready   : dfaccto.t_Logic;
  end record;
  type t_AxiHbm_sm is record
    awready  : dfaccto.t_Logic;
    wready   : dfaccto.t_Logic;
    bresp    : dfaccto_axi.t_AxiResp;
    bid      : ocaccel.t_AxiHbmId;
    buser   : ocaccel.t_AxiHbmBUser;
    bvalid   : dfaccto.t_Logic;
    arready  : dfaccto.t_Logic;
    rdata    : ocaccel.t_AxiHbmData;
    rresp    : dfaccto_axi.t_AxiResp;
    rlast    : dfaccto.t_Logic;
    rid      : ocaccel.t_AxiHbmId;
    ruser   : ocaccel.t_AxiHbmRUser;
    rvalid   : dfaccto.t_Logic;
  end record;
  type t_AxiHbm_v_ms is array (integer range <>) of ocaccel.t_AxiHbm_ms;
  type t_AxiHbm_v_sm is array (integer range <>) of ocaccel.t_AxiHbm_sm;

  constant c_AxiHbmNull_ms : ocaccel.t_AxiHbm_ms
            := -- (ocaccel).t_AxiHbm   |   {'awsize': 5, 'arsize': 5}
               (awaddr   => ocaccel.c_AxiHbmAddrNull,
                awlen    => ocaccel.c_AxiHbmLenNull,
                awsize   => to_unsigned(5, dfaccto_axi.t_AxiSize'length),
                awburst  => dfaccto_axi.c_AxiBurstNull,
                awlock   => dfaccto_axi.c_AxiLockNull,
                awcache  => dfaccto_axi.c_AxiCacheNull,
                awprot   => dfaccto_axi.c_AxiProtNull,
                awqos    => dfaccto_axi.c_AxiQosNull,
                awregion => dfaccto_axi.c_AxiRegionNull,
                awid     => ocaccel.c_AxiHbmIdNull,
                awuser   => ocaccel.c_AxiHbmAWUserNull,
                awvalid  => dfaccto.c_LogicNull,
                wdata    => ocaccel.c_AxiHbmDataNull,
                wstrb    => ocaccel.c_AxiHbmStrbNull,
                wlast    => dfaccto.c_LogicNull,
                wuser    => ocaccel.c_AxiHbmWUserNull,
                wvalid   => dfaccto.c_LogicNull,
                bready   => dfaccto.c_LogicNull,
                araddr   => ocaccel.c_AxiHbmAddrNull,
                arlen    => ocaccel.c_AxiHbmLenNull,
                arsize   => to_unsigned(5, dfaccto_axi.t_AxiSize'length),
                arburst  => dfaccto_axi.c_AxiBurstNull,
                arlock   => dfaccto_axi.c_AxiLockNull,
                arcache  => dfaccto_axi.c_AxiCacheNull,
                arprot   => dfaccto_axi.c_AxiProtNull,
                arqos    => dfaccto_axi.c_AxiQosNull,
                arregion => dfaccto_axi.c_AxiRegionNull,
                arid     => ocaccel.c_AxiHbmIdNull,
                aruser   => ocaccel.c_AxiHbmARUserNull,
                arvalid  => dfaccto.c_LogicNull,
                rready   => dfaccto.c_LogicNull);
  constant c_AxiHbmNull_sm : ocaccel.t_AxiHbm_sm
            := (awready  => dfaccto.c_LogicNull,
                wready   => dfaccto.c_LogicNull,
                bid      => ocaccel.c_AxiHbmIdNull,
                buser    => ocaccel.c_AxiHbmBUserNull,
                bresp    => dfaccto_axi.c_AxiRespNull,
                bvalid   => dfaccto.c_LogicNull,
                arready  => dfaccto.c_LogicNull,
                rdata    => ocaccel.c_AxiHbmDataNull,
                rresp    => dfaccto_axi.c_AxiRespNull,
                rlast    => dfaccto.c_LogicNull,
                rid      => ocaccel.c_AxiHbmIdNull,
                ruser    => ocaccel.c_AxiHbmRUserNull,
                rvalid   => dfaccto.c_LogicNull);

  type t_AxiHbmRd_ms is record
    araddr   : ocaccel.t_AxiHbmAddr;
    arlen    : ocaccel.t_AxiHbmLen;
    arsize   : dfaccto_axi.t_AxiSize;
    arburst  : dfaccto_axi.t_AxiBurst;
    arlock   : dfaccto_axi.t_AxiLock;
    arcache  : dfaccto_axi.t_AxiCache;
    arprot   : dfaccto_axi.t_AxiProt;
    arqos    : dfaccto_axi.t_AxiQos;
    arregion : dfaccto_axi.t_AxiRegion;
    arid     : ocaccel.t_AxiHbmId;
    aruser   : ocaccel.t_AxiHbmARUser;
    arvalid  : dfaccto.t_Logic;
    rready   : dfaccto.t_Logic;
  end record;
  type t_AxiHbmRd_sm is record
    arready  : dfaccto.t_Logic;
    rdata    : ocaccel.t_AxiHbmData;
    rresp    : dfaccto_axi.t_AxiResp;
    rlast    : dfaccto.t_Logic;
    rid      : ocaccel.t_AxiHbmId;
    ruser   : ocaccel.t_AxiHbmRUser;
    rvalid   : dfaccto.t_Logic;
  end record;
  type t_AxiHbmRd_v_ms is array (integer range <>) of ocaccel.t_AxiHbmRd_ms;
  type t_AxiHbmRd_v_sm is array (integer range <>) of ocaccel.t_AxiHbmRd_sm;

  constant c_AxiHbmRdNull_ms : ocaccel.t_AxiHbmRd_ms
            := (araddr   => ocaccel.c_AxiHbmAddrNull,
                arlen    => ocaccel.c_AxiHbmLenNull,
                arsize   => to_unsigned(5, dfaccto_axi.t_AxiSize'length),
                arburst  => dfaccto_axi.c_AxiBurstNull,
                arlock   => dfaccto_axi.c_AxiLockNull,
                arcache  => dfaccto_axi.c_AxiCacheNull,
                arprot   => dfaccto_axi.c_AxiProtNull,
                arqos    => dfaccto_axi.c_AxiQosNull,
                arregion => dfaccto_axi.c_AxiRegionNull,
                arid     => ocaccel.c_AxiHbmIdNull,
                aruser   => ocaccel.c_AxiHbmARUserNull,
                arvalid  => dfaccto.c_LogicNull,
                rready   => dfaccto.c_LogicNull);
  constant c_AxiHbmRdNull_sm : ocaccel.t_AxiHbmRd_sm
            := (arready  => dfaccto.c_LogicNull,
                rdata    => ocaccel.c_AxiHbmDataNull,
                rresp    => dfaccto_axi.c_AxiRespNull,
                rlast    => dfaccto.c_LogicNull,
                rid      => ocaccel.c_AxiHbmIdNull,
                ruser    => ocaccel.c_AxiHbmRUserNull,
                rvalid   => dfaccto.c_LogicNull);

  type t_AxiHbmWr_ms is record
    awaddr   : ocaccel.t_AxiHbmAddr;
    awlen    : ocaccel.t_AxiHbmLen;
    awsize   : dfaccto_axi.t_AxiSize;
    awburst  : dfaccto_axi.t_AxiBurst;
    awlock   : dfaccto_axi.t_AxiLock;
    awcache  : dfaccto_axi.t_AxiCache;
    awprot   : dfaccto_axi.t_AxiProt;
    awqos    : dfaccto_axi.t_AxiQos;
    awregion : dfaccto_axi.t_AxiRegion;
    awid     : ocaccel.t_AxiHbmId;
    awuser   : ocaccel.t_AxiHbmAWUser;
    awvalid  : dfaccto.t_Logic;
    wdata    : ocaccel.t_AxiHbmData;
    wstrb    : ocaccel.t_AxiHbmStrb;
    wlast    : dfaccto.t_Logic;
    wuser   : ocaccel.t_AxiHbmWUser;
    wvalid   : dfaccto.t_Logic;
    bready   : dfaccto.t_Logic;
  end record;
  type t_AxiHbmWr_sm is record
    awready  : dfaccto.t_Logic;
    wready   : dfaccto.t_Logic;
    bresp    : dfaccto_axi.t_AxiResp;
    bid      : ocaccel.t_AxiHbmId;
    buser   : ocaccel.t_AxiHbmBUser;
    bvalid   : dfaccto.t_Logic;
  end record;
  type t_AxiHbmWr_v_ms is array (integer range <>) of ocaccel.t_AxiHbmWr_ms;
  type t_AxiHbmWr_v_sm is array (integer range <>) of ocaccel.t_AxiHbmWr_sm;

  constant c_AxiHbmWrNull_ms : ocaccel.t_AxiHbmWr_ms
            := -- (ocaccel).t_AxiHbmWr   |   {'awsize': 5, 'arsize': 5}
               (awaddr   => ocaccel.c_AxiHbmAddrNull,
                awlen    => ocaccel.c_AxiHbmLenNull,
                awsize   => to_unsigned(5, dfaccto_axi.t_AxiSize'length),
                awburst  => dfaccto_axi.c_AxiBurstNull,
                awlock   => dfaccto_axi.c_AxiLockNull,
                awcache  => dfaccto_axi.c_AxiCacheNull,
                awprot   => dfaccto_axi.c_AxiProtNull,
                awqos    => dfaccto_axi.c_AxiQosNull,
                awregion => dfaccto_axi.c_AxiRegionNull,
                awid     => ocaccel.c_AxiHbmIdNull,
                awuser   => ocaccel.c_AxiHbmAWUserNull,
                awvalid  => dfaccto.c_LogicNull,
                wdata    => ocaccel.c_AxiHbmDataNull,
                wstrb    => ocaccel.c_AxiHbmStrbNull,
                wlast    => dfaccto.c_LogicNull,
                wuser    => ocaccel.c_AxiHbmWUserNull,
                wvalid   => dfaccto.c_LogicNull,
                bready   => dfaccto.c_LogicNull);
  constant c_AxiHbmWrNull_sm : ocaccel.t_AxiHbmWr_sm
            := (awready  => dfaccto.c_LogicNull,
                wready   => dfaccto.c_LogicNull,
                bid      => ocaccel.c_AxiHbmIdNull,
                buser    => ocaccel.c_AxiHbmBUserNull,
                bresp    => dfaccto_axi.c_AxiRespNull,
                bvalid   => dfaccto.c_LogicNull);

  subtype t_StmEthData is unsigned (512-1 downto 0);
  type t_StmEthData_v is array (integer range <>) of ocaccel.t_StmEthData;

  constant c_StmEthDataNull : ocaccel.t_StmEthData
            := to_unsigned(0, ocaccel.t_StmEthData'length);

  subtype t_StmEthKeep is unsigned (64-1 downto 0);
  type t_StmEthKeep_v is array (integer range <>) of ocaccel.t_StmEthKeep;

  constant c_StmEthKeepNull : ocaccel.t_StmEthKeep
            := to_unsigned(0, ocaccel.t_StmEthKeep'length);

  subtype t_StmEthUser is unsigned (1-1 downto 0);
  type t_StmEthUser_v is array (integer range <>) of ocaccel.t_StmEthUser;

  constant c_StmEthUserNull : ocaccel.t_StmEthUser
            := to_unsigned(0, ocaccel.t_StmEthUser'length);

  type t_StmEth_ms is record
    tdata   : ocaccel.t_StmEthData;
    tkeep   : ocaccel.t_StmEthKeep;
    tuser   : ocaccel.t_StmEthUser;
    tlast   : dfaccto.t_Logic;
    tvalid  : dfaccto.t_Logic;
  end record;
  type t_StmEth_sm is record
    tready  : dfaccto.t_Logic;
  end record;
  type t_StmEth_v_ms is array (integer range <>) of ocaccel.t_StmEth_ms;
  type t_StmEth_v_sm is array (integer range <>) of ocaccel.t_StmEth_sm;

  constant c_StmEthNull_ms : ocaccel.t_StmEth_ms
            := (tdata  => ocaccel.c_StmEthDataNull,
                tkeep  => ocaccel.c_StmEthKeepNull,
                tuser  => ocaccel.c_StmEthUserNull,
                tlast  => dfaccto.c_LogicNull,
                tvalid => dfaccto.c_LogicNull);
  constant c_StmEthNull_sm : ocaccel.t_StmEth_sm
            := (tready => dfaccto.c_LogicNull);

  subtype t_Context is unsigned (9-1 downto 0);
  type t_Context_v is array (integer range <>) of ocaccel.t_Context;

  constant c_ContextNull : ocaccel.t_Context
            := to_unsigned(0, ocaccel.t_Context'length);

  subtype t_InterruptSrc is unsigned (64-1 downto 0);
  type t_InterruptSrc_v is array (integer range <>) of ocaccel.t_InterruptSrc;

  constant c_InterruptSrcNull : ocaccel.t_InterruptSrc
            := to_unsigned(0, ocaccel.t_InterruptSrc'length);

  type t_Interrupt_ms is record
    ctx : ocaccel.t_Context;
    src : ocaccel.t_InterruptSrc;
    stb : dfaccto.t_Logic;
  end record;
  type t_Interrupt_sm is record
    ack : dfaccto.t_Logic;
  end record;
  type t_Interrupt_v_ms is array (integer range <>) of ocaccel.t_Interrupt_ms;
  type t_Interrupt_v_sm is array (integer range <>) of ocaccel.t_Interrupt_sm;

  constant c_InterruptNull_ms : ocaccel.t_Interrupt_ms
            := (ctx => ocaccel.c_ContextNull,
                src => ocaccel.c_InterruptSrcNull,
                stb => dfaccto.c_LogicNull);
  constant c_InterruptNull_sm : ocaccel.t_Interrupt_sm
            := (ack => dfaccto.c_LogicNull);

end ocaccel;
