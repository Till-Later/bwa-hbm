library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto;
use work.dfaccto_axi;


package user is

  subtype t_HlsBlockData is unsigned (8-1 downto 0);
  type t_HlsBlockData_v is array (integer range <>) of user.t_HlsBlockData;

  constant c_HlsBlockDataNull : user.t_HlsBlockData
            := to_unsigned(0, user.t_HlsBlockData'length);

  type t_HlsBlock_ms is record
    start : dfaccto.t_Logic;
  end record;
  type t_HlsBlock_sm is record
    idle  : dfaccto.t_Logic;
    ready : dfaccto.t_Logic;
    data  : user.t_HlsBlockData;
    done  : dfaccto.t_Logic;
  end record;
  type t_HlsBlock_v_ms is array (integer range <>) of user.t_HlsBlock_ms;
  type t_HlsBlock_v_sm is array (integer range <>) of user.t_HlsBlock_sm;

  constant c_HlsBlockNull_ms : user.t_HlsBlock_ms
            := (start => dfaccto.c_LogicNull);
  constant c_HlsBlockNull_sm : user.t_HlsBlock_sm
            := (idle  => dfaccto.c_LogicNull,
                ready => dfaccto.c_LogicNull,
                data  => user.c_HlsBlockDataNull,
                done  => dfaccto.c_LogicNull);

  subtype t_HlsPortInoutData is unsigned (8-1 downto 0);
  type t_HlsPortInoutData_v is array (integer range <>) of user.t_HlsPortInoutData;

  constant c_HlsPortInoutDataNull : user.t_HlsPortInoutData
            := to_unsigned(0, user.t_HlsPortInoutData'length);

  type t_HlsPortInout_ms is record
    odata : user.t_HlsPortInoutData;
    ovld  : dfaccto.t_Logic;
    iack  : dfaccto.t_Logic;
  end record;
  type t_HlsPortInout_sm is record
    idata : user.t_HlsPortInoutData;
    ivld  : dfaccto.t_Logic;
    oack  : dfaccto.t_Logic;
  end record;
  type t_HlsPortInout_v_ms is array (integer range <>) of user.t_HlsPortInout_ms;
  type t_HlsPortInout_v_sm is array (integer range <>) of user.t_HlsPortInout_sm;

  constant c_HlsPortInoutNull_ms : user.t_HlsPortInout_ms
            := (odata  => user.c_HlsPortInoutDataNull,
                ovld   => dfaccto.c_LogicNull,
                iack   => dfaccto.c_LogicNull)
               ;
  constant c_HlsPortInoutNull_sm : user.t_HlsPortInout_sm
            := (idata  => user.c_HlsPortInoutDataNull,
                ivld   => dfaccto.c_LogicNull,
                oack   => dfaccto.c_LogicNull)
               ;

  subtype t_HlsPortInData is unsigned (8-1 downto 0);
  type t_HlsPortInData_v is array (integer range <>) of user.t_HlsPortInData;

  constant c_HlsPortInDataNull : user.t_HlsPortInData
            := to_unsigned(0, user.t_HlsPortInData'length);

  type t_HlsPortIn_ms is record
    dummy : std_logic;
  end record;
  type t_HlsPortIn_sm is record
    idata : user.t_HlsPortInData;
    ivld  : dfaccto.t_Logic;
  end record;
  type t_HlsPortIn_v_ms is array (integer range <>) of user.t_HlsPortIn_ms;
  type t_HlsPortIn_v_sm is array (integer range <>) of user.t_HlsPortIn_sm;

  constant c_HlsPortInNull_ms : user.t_HlsPortIn_ms
            := (dummy => '-');
  constant c_HlsPortInNull_sm : user.t_HlsPortIn_sm
            := (idata  => user.c_HlsPortInDataNull,
                ivld   => dfaccto.c_LogicNull)
               ;

  subtype t_HlsFifoOutData is unsigned (8-1 downto 0);
  type t_HlsFifoOutData_v is array (integer range <>) of user.t_HlsFifoOutData;

  constant c_HlsFifoOutDataNull : user.t_HlsFifoOutData
            := to_unsigned(0, user.t_HlsFifoOutData'length);

  type t_HlsFifoOut_ms is record
    data   : user.t_HlsFifoOutData;
    strobe : dfaccto.t_Logic;
  end record;
  type t_HlsFifoOut_sm is record
    ready  : dfaccto.t_Logic;
  end record;
  type t_HlsFifoOut_v_ms is array (integer range <>) of user.t_HlsFifoOut_ms;
  type t_HlsFifoOut_v_sm is array (integer range <>) of user.t_HlsFifoOut_sm;

  constant c_HlsFifoOutNull_ms : user.t_HlsFifoOut_ms
            := (data   => user.c_HlsFifoOutDataNull,
                strobe => dfaccto.c_LogicNull);
  constant c_HlsFifoOutNull_sm : user.t_HlsFifoOut_sm
            := (ready  => dfaccto.c_LogicNull);

  subtype t_HlsFifoInData is unsigned (8-1 downto 0);
  type t_HlsFifoInData_v is array (integer range <>) of user.t_HlsFifoInData;

  constant c_HlsFifoInDataNull : user.t_HlsFifoInData
            := to_unsigned(0, user.t_HlsFifoInData'length);

  type t_HlsFifoIn_ms is record
    strobe : dfaccto.t_Logic;
  end record;
  type t_HlsFifoIn_sm is record
    data   : user.t_HlsFifoInData;
    ready  : dfaccto.t_Logic;
  end record;
  type t_HlsFifoIn_v_ms is array (integer range <>) of user.t_HlsFifoIn_ms;
  type t_HlsFifoIn_v_sm is array (integer range <>) of user.t_HlsFifoIn_sm;

  constant c_HlsFifoInNull_ms : user.t_HlsFifoIn_ms
            := (strobe => dfaccto.c_LogicNull);
  constant c_HlsFifoInNull_sm : user.t_HlsFifoIn_sm
            := (data   => user.c_HlsFifoInDataNull,
                ready  => dfaccto.c_LogicNull);

  subtype t_HlsMemData is unsigned (8-1 downto 0);
  type t_HlsMemData_v is array (integer range <>) of user.t_HlsMemData;

  constant c_HlsMemDataNull : user.t_HlsMemData
            := to_unsigned(0, user.t_HlsMemData'length);

  subtype t_HlsMemAddr is unsigned (5-1 downto 0);
  type t_HlsMemAddr_v is array (integer range <>) of user.t_HlsMemAddr;

  constant c_HlsMemAddrNull : user.t_HlsMemAddr
            := to_unsigned(0, user.t_HlsMemAddr'length);

  type t_HlsMem_ms is record
    addr   : user.t_HlsMemAddr;
    wdata  : user.t_HlsMemData;
    write  : dfaccto.t_Logic;
    strobe : dfaccto.t_Logic;
  end record;
  type t_HlsMem_sm is record
    rdata  : user.t_HlsMemData;
  end record;
  type t_HlsMem_v_ms is array (integer range <>) of user.t_HlsMem_ms;
  type t_HlsMem_v_sm is array (integer range <>) of user.t_HlsMem_sm;

  constant c_HlsMemNull_ms : user.t_HlsMem_ms
            := (addr   => user.c_HlsMemAddrNull,
                write  => dfaccto.c_LogicNull,
                wdata  => user.c_HlsMemDataNull,
                strobe  => dfaccto.c_LogicNull);
  constant c_HlsMemNull_sm : user.t_HlsMem_sm
            := (rdata   => user.c_HlsMemDataNull);

  subtype t_HlsMemWrData is unsigned (8-1 downto 0);
  type t_HlsMemWrData_v is array (integer range <>) of user.t_HlsMemWrData;

  constant c_HlsMemWrDataNull : user.t_HlsMemWrData
            := to_unsigned(0, user.t_HlsMemWrData'length);

  subtype t_HlsMemWrAddr is unsigned (5-1 downto 0);
  type t_HlsMemWrAddr_v is array (integer range <>) of user.t_HlsMemWrAddr;

  constant c_HlsMemWrAddrNull : user.t_HlsMemWrAddr
            := to_unsigned(0, user.t_HlsMemWrAddr'length);

  type t_HlsMemWr_ms is record
    addr   : user.t_HlsMemWrAddr;
    wdata  : user.t_HlsMemWrData;
    write  : dfaccto.t_Logic;
    strobe : dfaccto.t_Logic;
  end record;
  type t_HlsMemWr_sm is record
    dummy  : std_logic;
  end record;
  type t_HlsMemWr_v_ms is array (integer range <>) of user.t_HlsMemWr_ms;
  type t_HlsMemWr_v_sm is array (integer range <>) of user.t_HlsMemWr_sm;

  constant c_HlsMemWrNull_ms : user.t_HlsMemWr_ms
            := (addr   => user.c_HlsMemWrAddrNull,
                write  => dfaccto.c_LogicNull,
                wdata  => user.c_HlsMemWrDataNull,
                strobe  => dfaccto.c_LogicNull);
  constant c_HlsMemWrNull_sm : user.t_HlsMemWr_sm
            := (dummy   => '-');

  subtype t_HlsBusData is unsigned (8-1 downto 0);
  type t_HlsBusData_v is array (integer range <>) of user.t_HlsBusData;

  constant c_HlsBusDataNull : user.t_HlsBusData
            := to_unsigned(0, user.t_HlsBusData'length);

  subtype t_HlsBusAddr is unsigned (32-1 downto 0);
  type t_HlsBusAddr_v is array (integer range <>) of user.t_HlsBusAddr;

  constant c_HlsBusAddrNull : user.t_HlsBusAddr
            := to_unsigned(0, user.t_HlsBusAddr'length);

  subtype t_HlsBusSize is unsigned (32-1 downto 0);
  type t_HlsBusSize_v is array (integer range <>) of user.t_HlsBusSize;

  constant c_HlsBusSizeNull : user.t_HlsBusSize
            := to_unsigned(0, user.t_HlsBusSize'length);

  type t_HlsBus_ms is record
    req_addr   : user.t_HlsBusAddr;
    req_write  : dfaccto.t_Logic;
    req_size   : user.t_HlsBusSize;
    req_wdata  : user.t_HlsBusData;
    req_strobe : dfaccto.t_Logic;
    rsp_strobe : dfaccto.t_Logic;
  end record;
  type t_HlsBus_sm is record
    req_ready  : dfaccto.t_Logic;
    rsp_rdata  : user.t_HlsBusData;
    rsp_ready  : dfaccto.t_Logic;
  end record;
  type t_HlsBus_v_ms is array (integer range <>) of user.t_HlsBus_ms;
  type t_HlsBus_v_sm is array (integer range <>) of user.t_HlsBus_sm;

  constant c_HlsBusNull_ms : user.t_HlsBus_ms
            := (req_addr   => user.c_HlsBusAddrNull,
                req_write  => dfaccto.c_LogicNull,
                req_size   => user.c_HlsBusSizeNull,
                req_wdata  => user.c_HlsBusDataNull,
                req_strobe => dfaccto.c_LogicNull,
                rsp_strobe => dfaccto.c_LogicNull);
  constant c_HlsBusNull_sm : user.t_HlsBus_sm
            := (req_ready  => dfaccto.c_LogicNull,
                rsp_rdata  => user.c_HlsBusDataNull,
                rsp_ready => dfaccto.c_LogicNull);

  subtype t_HlsAxiData is unsigned (32-1 downto 0);
  type t_HlsAxiData_v is array (integer range <>) of user.t_HlsAxiData;

  constant c_HlsAxiDataNull : user.t_HlsAxiData
            := to_unsigned(0, user.t_HlsAxiData'length);

  subtype t_HlsAxiStrb is unsigned (4-1 downto 0);
  type t_HlsAxiStrb_v is array (integer range <>) of user.t_HlsAxiStrb;

  constant c_HlsAxiStrbNull : user.t_HlsAxiStrb
            := to_unsigned(0, user.t_HlsAxiStrb'length);

  subtype t_HlsAxiAddr is unsigned (32-1 downto 0);
  type t_HlsAxiAddr_v is array (integer range <>) of user.t_HlsAxiAddr;

  constant c_HlsAxiAddrNull : user.t_HlsAxiAddr
            := to_unsigned(0, user.t_HlsAxiAddr'length);

  subtype t_HlsAxiWordIdx is unsigned (2-1 downto 0);
  type t_HlsAxiWordIdx_v is array (integer range <>) of user.t_HlsAxiWordIdx;

  constant c_HlsAxiWordIdxNull : user.t_HlsAxiWordIdx
            := to_unsigned(0, user.t_HlsAxiWordIdx'length);

  subtype t_HlsAxiWordAddr is unsigned (30-1 downto 0);
  type t_HlsAxiWordAddr_v is array (integer range <>) of user.t_HlsAxiWordAddr;

  constant c_HlsAxiWordAddrNull : user.t_HlsAxiWordAddr
            := to_unsigned(0, user.t_HlsAxiWordAddr'length);

  constant c_HlsAxiFullSize : dfaccto_axi.t_AxiSize
            := to_unsigned(2, dfaccto_axi.t_AxiSize'length);

  subtype t_HlsAxiId is unsigned (2-1 downto 0);
  type t_HlsAxiId_v is array (integer range <>) of user.t_HlsAxiId;

  constant c_HlsAxiIdNull : user.t_HlsAxiId
            := to_unsigned(0, user.t_HlsAxiId'length);

  subtype t_HlsAxiLen is unsigned (8-1 downto 0);
  type t_HlsAxiLen_v is array (integer range <>) of user.t_HlsAxiLen;

  constant c_HlsAxiLenNull : user.t_HlsAxiLen
            := to_unsigned(0, user.t_HlsAxiLen'length);

  type t_HlsAxi_ms is record
    awaddr   : user.t_HlsAxiAddr;
    awlen    : user.t_HlsAxiLen;
    awsize   : dfaccto_axi.t_AxiSize;
    awburst  : dfaccto_axi.t_AxiBurst;
    awid     : user.t_HlsAxiId;
    awvalid  : dfaccto.t_Logic;
    wdata    : user.t_HlsAxiData;
    wstrb    : user.t_HlsAxiStrb;
    wlast    : dfaccto.t_Logic;
    wvalid   : dfaccto.t_Logic;
    bready   : dfaccto.t_Logic;
    araddr   : user.t_HlsAxiAddr;
    arlen    : user.t_HlsAxiLen;
    arsize   : dfaccto_axi.t_AxiSize;
    arburst  : dfaccto_axi.t_AxiBurst;
    arid     : user.t_HlsAxiId;
    arvalid  : dfaccto.t_Logic;
    rready   : dfaccto.t_Logic;
  end record;
  type t_HlsAxi_sm is record
    awready  : dfaccto.t_Logic;
    wready   : dfaccto.t_Logic;
    bresp    : dfaccto_axi.t_AxiResp;
    bid      : user.t_HlsAxiId;
    bvalid   : dfaccto.t_Logic;
    arready  : dfaccto.t_Logic;
    rdata    : user.t_HlsAxiData;
    rresp    : dfaccto_axi.t_AxiResp;
    rlast    : dfaccto.t_Logic;
    rid      : user.t_HlsAxiId;
    rvalid   : dfaccto.t_Logic;
  end record;
  type t_HlsAxi_v_ms is array (integer range <>) of user.t_HlsAxi_ms;
  type t_HlsAxi_v_sm is array (integer range <>) of user.t_HlsAxi_sm;

  constant c_HlsAxiNull_ms : user.t_HlsAxi_ms
            := -- (user).t_HlsAxi   |   {'awsize': 2, 'arsize': 2}
               (awaddr   => user.c_HlsAxiAddrNull,
                awlen    => user.c_HlsAxiLenNull,
                awsize   => to_unsigned(2, dfaccto_axi.t_AxiSize'length),
                awburst  => dfaccto_axi.c_AxiBurstNull,
                awid     => user.c_HlsAxiIdNull,
                awvalid  => dfaccto.c_LogicNull,
                wdata    => user.c_HlsAxiDataNull,
                wstrb    => user.c_HlsAxiStrbNull,
                wlast    => dfaccto.c_LogicNull,
                wvalid   => dfaccto.c_LogicNull,
                bready   => dfaccto.c_LogicNull,
                araddr   => user.c_HlsAxiAddrNull,
                arlen    => user.c_HlsAxiLenNull,
                arsize   => to_unsigned(2, dfaccto_axi.t_AxiSize'length),
                arburst  => dfaccto_axi.c_AxiBurstNull,
                arid     => user.c_HlsAxiIdNull,
                arvalid  => dfaccto.c_LogicNull,
                rready   => dfaccto.c_LogicNull);
  constant c_HlsAxiNull_sm : user.t_HlsAxi_sm
            := (awready  => dfaccto.c_LogicNull,
                wready   => dfaccto.c_LogicNull,
                bid      => user.c_HlsAxiIdNull,
                bresp    => dfaccto_axi.c_AxiRespNull,
                bvalid   => dfaccto.c_LogicNull,
                arready  => dfaccto.c_LogicNull,
                rdata    => user.c_HlsAxiDataNull,
                rresp    => dfaccto_axi.c_AxiRespNull,
                rlast    => dfaccto.c_LogicNull,
                rid      => user.c_HlsAxiIdNull,
                rvalid   => dfaccto.c_LogicNull);

  subtype t_HlsCtrlData is unsigned (32-1 downto 0);
  type t_HlsCtrlData_v is array (integer range <>) of user.t_HlsCtrlData;

  constant c_HlsCtrlDataNull : user.t_HlsCtrlData
            := to_unsigned(0, user.t_HlsCtrlData'length);

  subtype t_HlsCtrlStrb is unsigned (4-1 downto 0);
  type t_HlsCtrlStrb_v is array (integer range <>) of user.t_HlsCtrlStrb;

  constant c_HlsCtrlStrbNull : user.t_HlsCtrlStrb
            := to_unsigned(0, user.t_HlsCtrlStrb'length);

  subtype t_HlsCtrlAddr is unsigned (5-1 downto 0);
  type t_HlsCtrlAddr_v is array (integer range <>) of user.t_HlsCtrlAddr;

  constant c_HlsCtrlAddrNull : user.t_HlsCtrlAddr
            := to_unsigned(0, user.t_HlsCtrlAddr'length);

  subtype t_HlsCtrlWordIdx is unsigned (2-1 downto 0);
  type t_HlsCtrlWordIdx_v is array (integer range <>) of user.t_HlsCtrlWordIdx;

  constant c_HlsCtrlWordIdxNull : user.t_HlsCtrlWordIdx
            := to_unsigned(0, user.t_HlsCtrlWordIdx'length);

  subtype t_HlsCtrlWordAddr is unsigned (3-1 downto 0);
  type t_HlsCtrlWordAddr_v is array (integer range <>) of user.t_HlsCtrlWordAddr;

  constant c_HlsCtrlWordAddrNull : user.t_HlsCtrlWordAddr
            := to_unsigned(0, user.t_HlsCtrlWordAddr'length);

  constant c_HlsCtrlFullSize : dfaccto_axi.t_AxiSize
            := to_unsigned(2, dfaccto_axi.t_AxiSize'length);

  type t_HlsCtrl_ms is record
    awaddr   : user.t_HlsCtrlAddr;
    awvalid  : dfaccto.t_Logic;
    wdata    : user.t_HlsCtrlData;
    wstrb    : user.t_HlsCtrlStrb;
    wvalid   : dfaccto.t_Logic;
    bready   : dfaccto.t_Logic;
    araddr   : user.t_HlsCtrlAddr;
    arvalid  : dfaccto.t_Logic;
    rready   : dfaccto.t_Logic;
  end record;
  type t_HlsCtrl_sm is record
    awready  : dfaccto.t_Logic;
    wready   : dfaccto.t_Logic;
    bresp    : dfaccto_axi.t_AxiResp;
    bvalid   : dfaccto.t_Logic;
    arready  : dfaccto.t_Logic;
    rdata    : user.t_HlsCtrlData;
    rresp    : dfaccto_axi.t_AxiResp;
    rvalid   : dfaccto.t_Logic;
  end record;
  type t_HlsCtrl_v_ms is array (integer range <>) of user.t_HlsCtrl_ms;
  type t_HlsCtrl_v_sm is array (integer range <>) of user.t_HlsCtrl_sm;

  constant c_HlsCtrlNull_ms : user.t_HlsCtrl_ms
            := -- (user).t_HlsCtrl   |   {'awsize': 2, 'arsize': 2}
               (awaddr   => user.c_HlsCtrlAddrNull,
                awvalid  => dfaccto.c_LogicNull,
                wdata    => user.c_HlsCtrlDataNull,
                wstrb    => user.c_HlsCtrlStrbNull,
                wvalid   => dfaccto.c_LogicNull,
                bready   => dfaccto.c_LogicNull,
                araddr   => user.c_HlsCtrlAddrNull,
                arvalid  => dfaccto.c_LogicNull,
                rready   => dfaccto.c_LogicNull);
  constant c_HlsCtrlNull_sm : user.t_HlsCtrl_sm
            := (awready  => dfaccto.c_LogicNull,
                wready   => dfaccto.c_LogicNull,
                bresp    => dfaccto_axi.c_AxiRespNull,
                bvalid   => dfaccto.c_LogicNull,
                arready  => dfaccto.c_LogicNull,
                rdata    => user.c_HlsCtrlDataNull,
                rresp    => dfaccto_axi.c_AxiRespNull,
                rvalid   => dfaccto.c_LogicNull);

  subtype t_HlsStreamData is unsigned (32-1 downto 0);
  type t_HlsStreamData_v is array (integer range <>) of user.t_HlsStreamData;

  constant c_HlsStreamDataNull : user.t_HlsStreamData
            := to_unsigned(0, user.t_HlsStreamData'length);

  subtype t_HlsStreamKeep is unsigned (4-1 downto 0);
  type t_HlsStreamKeep_v is array (integer range <>) of user.t_HlsStreamKeep;

  constant c_HlsStreamKeepNull : user.t_HlsStreamKeep
            := to_unsigned(0, user.t_HlsStreamKeep'length);

  type t_HlsStream_ms is record
    tdata   : user.t_HlsStreamData;
    tkeep   : user.t_HlsStreamKeep;
    tlast   : dfaccto.t_Logic;
    tvalid  : dfaccto.t_Logic;
  end record;
  type t_HlsStream_sm is record
    tready  : dfaccto.t_Logic;
  end record;
  type t_HlsStream_v_ms is array (integer range <>) of user.t_HlsStream_ms;
  type t_HlsStream_v_sm is array (integer range <>) of user.t_HlsStream_sm;

  constant c_HlsStreamNull_ms : user.t_HlsStream_ms
            := (tdata  => user.c_HlsStreamDataNull,
                tkeep  => user.c_HlsStreamKeepNull,
                tlast  => dfaccto.c_LogicNull,
                tvalid => dfaccto.c_LogicNull);
  constant c_HlsStreamNull_sm : user.t_HlsStream_sm
            := (tready => dfaccto.c_LogicNull);

  subtype t_StmHbmData is unsigned (256-1 downto 0);
  type t_StmHbmData_v is array (integer range <>) of user.t_StmHbmData;

  constant c_StmHbmDataNull : user.t_StmHbmData
            := to_unsigned(0, user.t_StmHbmData'length);

  subtype t_StmHbmKeep is unsigned (32-1 downto 0);
  type t_StmHbmKeep_v is array (integer range <>) of user.t_StmHbmKeep;

  constant c_StmHbmKeepNull : user.t_StmHbmKeep
            := to_unsigned(0, user.t_StmHbmKeep'length);

  subtype t_StmHbmId is unsigned (6-1 downto 0);
  type t_StmHbmId_v is array (integer range <>) of user.t_StmHbmId;

  constant c_StmHbmIdNull : user.t_StmHbmId
            := to_unsigned(0, user.t_StmHbmId'length);

  subtype t_StmHbmUser is unsigned (1-1 downto 0);
  type t_StmHbmUser_v is array (integer range <>) of user.t_StmHbmUser;

  constant c_StmHbmUserNull : user.t_StmHbmUser
            := to_unsigned(0, user.t_StmHbmUser'length);

  type t_StmHbm_ms is record
    tdata   : user.t_StmHbmData;
    tkeep   : user.t_StmHbmKeep;
    tid     : user.t_StmHbmId;
    tuser   : user.t_StmHbmUser;
    tlast   : dfaccto.t_Logic;
    tvalid  : dfaccto.t_Logic;
  end record;
  type t_StmHbm_sm is record
    tready  : dfaccto.t_Logic;
  end record;
  type t_StmHbm_v_ms is array (integer range <>) of user.t_StmHbm_ms;
  type t_StmHbm_v_sm is array (integer range <>) of user.t_StmHbm_sm;

  constant c_StmHbmNull_ms : user.t_StmHbm_ms
            := (tdata  => user.c_StmHbmDataNull,
                tkeep  => user.c_StmHbmKeepNull,
                tid    => user.c_StmHbmIdNull,
                tuser  => user.c_StmHbmUserNull,
                tlast  => dfaccto.c_LogicNull,
                tvalid => dfaccto.c_LogicNull);
  constant c_StmHbmNull_sm : user.t_StmHbm_sm
            := (tready => dfaccto.c_LogicNull);

  subtype t_RegAddr is unsigned (2-1 downto 0);
  type t_RegAddr_v is array (integer range <>) of user.t_RegAddr;

  constant c_RegAddrNull : user.t_RegAddr
            := to_unsigned(0, user.t_RegAddr'length);

  subtype t_RegData is unsigned (32-1 downto 0);
  type t_RegData_v is array (integer range <>) of user.t_RegData;

  constant c_RegDataNull : user.t_RegData
            := to_unsigned(0, user.t_RegData'length);

  subtype t_RegStrb is unsigned (4-1 downto 0);
  type t_RegStrb_v is array (integer range <>) of user.t_RegStrb;

  constant c_RegStrbNull : user.t_RegStrb
            := to_unsigned(0, user.t_RegStrb'length);

  type t_RegPort_ms is record
    addr : user.t_RegAddr;
    wrdata : user.t_RegData;
    wrstrb : user.t_RegStrb;
    wrnotrd : dfaccto.t_Logic;
    valid : dfaccto.t_Logic;
  end record;
  type t_RegPort_sm is record
    rddata : user.t_RegData;
    ready : dfaccto.t_Logic;
  end record;
  type t_RegPort_v_ms is array (integer range <>) of user.t_RegPort_ms;
  type t_RegPort_v_sm is array (integer range <>) of user.t_RegPort_sm;

  constant c_RegPortNull_ms : user.t_RegPort_ms
            := (addr => user.c_RegAddrNull,
                wrdata => user.c_RegDataNull,
                wrstrb => user.c_RegStrbNull,
                wrnotrd => dfaccto.c_LogicNull,
                valid => dfaccto.c_LogicNull);
  constant c_RegPortNull_sm : user.t_RegPort_sm
            := (rddata => user.c_RegDataNull,
               ready => dfaccto.c_LogicNull);

  subtype t_Status is unsigned (20-1 downto 0);
  type t_Status_v is array (integer range <>) of user.t_Status;

  constant c_StatusNull : user.t_Status
            := to_unsigned(0, user.t_Status'length);

end user;
