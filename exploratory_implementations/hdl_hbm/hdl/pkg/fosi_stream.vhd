library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_axi.all;

package fosi_stream is

  -------------------------------------------------------------------------------
  -- Stream Interface: Base
  -------------------------------------------------------------------------------
  --Scalars:

  constant c_NativeStreamDataWidth : integer := c_NativeAxiDataWidth;
  subtype t_NativeStreamData is unsigned (c_NativeStreamDataWidth-1 downto 0);

  constant c_NativeStreamStrbWidth : integer := c_NativeStreamDataWidth/8;
  subtype t_NativeStreamStrb is unsigned (c_NativeStreamStrbWidth-1 downto 0);

  -- Complete Bundle:
  type t_NativeStream_ms is record
    tdata   : t_NativeStreamData;
    tkeep   : t_NativeStreamStrb;
    tlast   : std_logic;
    tvalid  : std_logic;
  end record;
  type t_NativeStream_sm is record
    tready  : std_logic;
  end record;
  constant c_NativeStreamNull_ms : t_NativeStream_ms := (
    tdata  => (others => '0'),
    tkeep  => (others => '0'),
    tlast  => '0',
    tvalid => '0');
  constant c_NativeStreamNull_sm : t_NativeStream_sm := (
    tready => '0');

  -- Interface List:
  type t_NativeStream_v_ms is array (integer range <>) of t_NativeStream_ms;
  type t_NativeStream_v_sm is array (integer range <>) of t_NativeStream_sm;

end fosi_stream;
