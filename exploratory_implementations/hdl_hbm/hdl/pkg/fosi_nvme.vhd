library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_axi.all;
use work.fosi_util.all;

package fosi_nvme is

  subtype t_NvmeCmdCounter is unsigned (8 downto 0);
  constant c_NvmeCmdCounterZero : t_NvmeCmdCounter := to_unsigned(0, t_CmdCounter'length);
  constant c_NvmeCmdCounterOne : t_NvmeCmdCounter := to_unsigned(1, t_CmdCounter'length);
  constant c_NvmeCmdCounterLimit : t_NvmeCmdCounter := to_unsigned(218, t_CmdCounter'length);

  constant c_NvmeDrivesPresent : integer := 2;
  type t_NvmeDriveCounters is array (c_NvmeDrivesPresent-1 downto 0) of t_NvmeCmdCounter;
  subtype t_NvmeDriveVector is unsigned (c_NvmeDrivesPresent-1 downto 0);

  constant c_NvmeDriveAddrWidth : integer := 3;
  constant c_NvmeDriveCount : integer := 2**c_NvmeDriveAddrWidth;
  subtype t_NvmeDriveAddr  is unsigned (t_NvmeDriveAddrWidth-1 downto 0);

  subtype t_NvmeBlockAddr  is unsigned (63 downto 0);
  subtype t_NvmeBlockCount is unsigned (31 downto 0);

  type t_NvmeCommandStream_ms is record
    bufferAddr : t_NativeAxiAddr;
    drive : t_NvmeDriveAddr;
    blockAddr : t_NvmeBlockAddr;
    blockCnt : t_NvmeBlockCount;
    valid : std_logic;
  end record;
  type t_NvmeCommandStream_sm is record
    ready : std_logic;
  end record;

  type t_NvmeResponseStream_ms is record
    status : std_logic; -- 0: success, 1: error
    valid : std_logic;
  end record;

  type t_NvmeResponseStream_sm is record
    ready : std_logic;
  end record;

  subtype t_NvmePackedCmd is std_logic_vector (t_NativeAxiAddr'length + t_NvmeDriveAddr'length + t_NvmeBlockAddr'length + t_NvmeBlockCount'length -1 downto 0);
  subtype t_NvmePackedRsp is std_logic_vector (0 downto 0);

end fosi_nvme;
