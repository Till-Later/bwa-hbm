library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fosi_blockmap is

  -----------------------------------------------------------------------------
  -- Block Mapper Definitions
  -----------------------------------------------------------------------------

  constant c_BlkOffsetWidth : integer := 12;
  subtype t_BlkOffset is unsigned (c_BlkOffsetWidth-1 downto 0);

  constant c_LBlkWidth : integer := 32;
  subtype t_LBlk is unsigned (c_LBlkWidth-1 downto 0);
  constant c_InvalidLBlk : t_LBlk := (others => '1');
  type t_LBlks is array (integer range <>) of t_LBlk;

  constant c_PBlkWidth : integer := 64;
  subtype t_PBlk is unsigned (c_PBlkWidth-1 downto 0);
  constant c_InvalidPBlk : t_PBlk := (others => '1');
  type t_PBlks is array (integer range <>) of t_PBlk;

  type t_BlkMap_ms is record
    mapLBlk   : t_LBlk;
    mapReq    : std_logic;
    blocked   : std_logic;
    flushAck  : std_logic;
  end record;
  type t_BlkMap_sm is record
    mapLBase  : t_LBlk;
    mapLLimit : t_LBlk;
    mapPBase  : t_PBlk;
    mapAck    : std_logic;
    flushReq  : std_logic;
  end record;

  type t_BlkMap_v_ms is array (integer range <>) of t_BlkMap_ms;
  type t_BlkMap_v_sm is array (integer range <>) of t_BlkMap_sm;

  -- ExtentStore Internals
  subtype t_BRAMw256x32r16x512_WrEn   is std_logic_vector(  0 downto 0);
  subtype t_BRAMw256x32r16x512_WrAddr is std_logic_vector(  7 downto 0);
  subtype t_BRAMw256x32r16x512_WrData is std_logic_vector( 31 downto 0);
  subtype t_BRAMw256x32r16x512_RdAddr is std_logic_vector(  3 downto 0);
  subtype t_BRAMw256x32r16x512_RdData is std_logic_vector(511 downto 0);
  component BRAMw256x32r16x512 is
    port (
      clka  : in  std_logic;
      wea   : in  t_BRAMw256x32r16x512_WrEn;
      addra : in  t_BRAMw256x32r16x512_WrAddr;
      dina  : in  t_BRAMw256x32r16x512_WrData;
      clkb  : in  std_logic;
      addrb : in  t_BRAMw256x32r16x512_RdAddr;
      doutb : out t_BRAMw256x32r16x512_RdData);
  end component;

  subtype t_BRAMw256x64r256x64_WrEn   is std_logic_vector(  0 downto 0);
  subtype t_BRAMw256x64r256x64_WrAddr is std_logic_vector(  7 downto 0);
  subtype t_BRAMw256x64r256x64_WrData is std_logic_vector( 63 downto 0);
  subtype t_BRAMw256x64r256x64_RdAddr is std_logic_vector(  7 downto 0);
  subtype t_BRAMw256x64r256x64_RdData is std_logic_vector( 63 downto 0);
  component BRAMw256x64r256x64 is
    port (
      clka  : in  std_logic;
      wea   : in  t_BRAMw256x64r256x64_WrEn;
      addra : in  t_BRAMw256x64r256x64_WrAddr;
      dina  : in  t_BRAMw256x64r256x64_WrData;
      clkb  : in  std_logic;
      addrb : in  t_BRAMw256x64r256x64_RdAddr;
      doutb : out t_BRAMw256x64r256x64_RdData);
  end component;

  constant c_LRowAddrWidth : integer := 4;
  constant c_LRowCount : integer := 2**c_LRowAddrWidth;
  subtype t_LRowAddr is unsigned (c_LRowAddrWidth-1 downto 0);
  type t_LRowAddrs is array (integer range <>) of t_LRowAddr;

  constant c_LColAddrWidth : integer := 4;
  subtype t_LColAddr is unsigned (c_LColAddrWidth-1 downto 0);
  constant c_LColCount : integer := 2**c_LColAddrWidth;
  subtype t_LColVector is unsigned (c_LColCount-1 downto 0);

  constant c_EntryAddrWidth : integer := c_LRowAddrWidth + c_LColAddrWidth;
  subtype t_EntryAddr is unsigned (c_EntryAddrWidth-1 downto 0);

  constant c_LRowWidth : integer := c_LColCount * c_LBlkWidth;
  subtype t_LRow is unsigned (c_LRowWidth-1 downto 0);

  type t_MapReq is record
    rowAddr : t_LRowAddr;
    lblock : t_LBlk;
  end record;
  type t_MapReqs is array (integer range <>) of t_MapReq;

  type t_MapRes is record
    lbase : t_LBlk;
    llimit : t_LBlk;
    pbase : t_PBlk;
    valid : std_logic;
  end record;

  type t_StoreWrite is record
    laddr : t_EntryAddr;
    ldata : t_LBlk;
    len   : std_logic;
    paddr : t_EntryAddr;
    pdata : t_PBlk;
    pen   : std_logic;
  end record;

end fosi_blockmap;

