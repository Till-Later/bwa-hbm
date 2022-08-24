library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.action_types.all;
use work.psl_accel_types.all;

use work.fosi_axi.all;
use work.fosi_util.all;

package fosi_ctrl is

  subtype t_Logic is std_logic;
  subtype t_Logic_v is unsigned;

  subtype t_Handshake_ms is std_logic;
  subtype t_Handshake_sm is std_logic;
  subtype t_Handshake_v_ms is unsigned;
  subtype t_Handshake_v_sm is unsigned;

  -----------------------------------------------------------------------------
  -- General Action Signal Definitions
  -----------------------------------------------------------------------------
  -- Interrupt source range is split into user and snap range
  --  so only the lower n-1 bits can be used by the action
  constant c_IntSrcWidth : integer := INT_BITS - 1;
  subtype t_InterruptSrc is unsigned(c_IntSrcWidth-1 downto 0);

  constant c_ContextWidth : integer := CONTEXT_BITS;
  subtype t_Context is unsigned(c_ContextWidth-1 downto 0);

  -------------------------------------------------------------------------------
  -- Axi Interface: Ctrl
  -------------------------------------------------------------------------------
  --Scalars:

  constant c_CtrlDataWidth : integer := C_REG_DATA_WIDTH;
  subtype t_CtrlData is unsigned (c_CtrlDataWidth-1 downto 0);

  constant c_CtrlStrbWidth : integer := c_CtrlDataWidth/8;
  subtype t_CtrlStrb is unsigned (c_CtrlStrbWidth-1 downto 0);

  constant c_CtrlByteAddrWidth : integer := f_clog2(c_CtrlStrbWidth);
  constant c_CtrlFullSize : t_AxiSize := to_unsigned(c_CtrlByteAddrWidth, t_AxiSize'length);
  subtype t_CtrlByteAddr is unsigned (c_CtrlByteAddrWidth-1 downto 0);

  constant c_CtrlBurstLenWidth : integer := c_AxiBurstAlignWidth - c_CtrlByteAddrWidth;
  subtype t_CtrlBurstLen is unsigned(c_CtrlBurstLenWidth-1 downto 0);

  constant c_CtrlAddrWidth : integer := C_REG_ADDR_WIDTH;
  subtype t_CtrlAddr is unsigned (c_CtrlAddrWidth-1 downto 0);

  constant c_CtrlWordAddrWidth : integer := c_CtrlAddrWidth - c_CtrlByteAddrWidth;
  subtype t_CtrlWordAddr is unsigned(c_CtrlWordAddrWidth-1 downto 0);

  --Complete Bundle:
  type t_Ctrl_ms is record
    awaddr   : t_CtrlAddr;
    awvalid  : std_logic;
    wdata    : t_CtrlData;
    wstrb    : t_CtrlStrb;
    wvalid   : std_logic;
    bready   : std_logic;
    araddr   : t_CtrlAddr;
    arvalid  : std_logic;
    rready   : std_logic;
  end record;
  type t_Ctrl_sm is record
    awready  : std_logic;
    wready   : std_logic;
    bresp    : t_AxiResp;
    bvalid   : std_logic;
    arready  : std_logic;
    rdata    : t_CtrlData;
    rresp    : t_AxiResp;
    rlast    : std_logic;
    rvalid   : std_logic;
  end record;
  constant c_CtrlNull_ms : t_Ctrl_ms := (
    awaddr   => (others => '0'),
    awvalid  => '0',
    wdata    => (others => '0'),
    wstrb    => (others => '0'),
    wvalid   => '0',
    bready   => '0',
    araddr   => (others => '0'),
    arvalid  => '0',
    rready   => '0' );
  constant c_CtrlNull_sm : t_Ctrl_sm := (
    awready  => '0',
    wready   => '0',
    bresp    => (others => '0'),
    bvalid   => '0',
    arready  => '0',
    rdata    => (others => '0'),
    rresp    => (others => '0'),
    rlast    => '0',
    rvalid   => '0' );


  -------------------------------------------------------------------------------
  -- Simplified Register Interface
  -------------------------------------------------------------------------------

  -- Actual Register Space Spans 1Kx4B Registers (= 10 Bit Register Numbers)
  constant c_RegAddrWidth  : integer := 10;
  subtype t_RegAddr is unsigned (c_RegAddrWidth-1 downto 0);

  -- Address Range for a Single Port (Offset, Count)
  type t_RegRange is array (0 to 1) of t_RegAddr;
  -- Set of Address Ranges to configure the Register Port Demux
  type t_RegMap is array (integer range <>) of t_RegRange;

  constant c_RegDataWidth  : integer := c_CtrlDataWidth;
  subtype t_RegData is unsigned (c_RegDataWidth-1  downto 0);
  type t_RegData_v is array (integer range <>) of t_RegData;
  type t_RegFile is array (integer range <>) of t_RegData;

  constant c_RegStrbWidth  : integer := c_RegDataWidth/8;
  subtype t_RegStrb is unsigned (c_RegStrbWidth-1 downto 0);

  type t_RegPort_ms is record
    addr      : t_RegAddr;
    wrdata    : t_RegData;
    wrstrb    : t_RegStrb;
    wrnotrd   : std_logic;
    valid     : std_logic;
  end record;
  type t_RegPort_sm is record
    rddata    : t_RegData;
    ready     : std_logic;
  end record;
  constant c_RegPortNull_ms : t_RegPort_ms := (
    addr     => (others => '0'),
    wrdata   => (others => '0'),
    wrstrb   => (others => '0'),
    wrnotrd  => '0',
    valid    => '0');
  constant c_RegPortNull_sm : t_RegPort_sm := (
    rddata   => (others => '0'),
    ready    => '0');

  type t_RegPort_v_ms is array (integer range <>) of t_RegPort_ms;
  type t_RegPort_v_sm is array (integer range <>) of t_RegPort_sm;

end fosi_ctrl;
