library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



package dfaccto_axi is

  subtype t_AxiLen is unsigned (8-1 downto 0);
  type t_AxiLen_v is array (integer range <>) of dfaccto_axi.t_AxiLen;

  constant c_AxiLenNull : dfaccto_axi.t_AxiLen
            := to_unsigned(0, dfaccto_axi.t_AxiLen'length);

  subtype t_AxiSize is unsigned (3-1 downto 0);
  type t_AxiSize_v is array (integer range <>) of dfaccto_axi.t_AxiSize;

  constant c_AxiSizeNull : dfaccto_axi.t_AxiSize
            := to_unsigned(0, dfaccto_axi.t_AxiSize'length);

  subtype t_AxiBurst is unsigned (2-1 downto 0);
  type t_AxiBurst_v is array (integer range <>) of dfaccto_axi.t_AxiBurst;

  constant c_AxiBurstNull : dfaccto_axi.t_AxiBurst
            := to_unsigned(0, dfaccto_axi.t_AxiBurst'length);

  constant c_AxiBurstFixed : dfaccto_axi.t_AxiBurst
            := to_unsigned(0, dfaccto_axi.t_AxiBurst'length);

  constant c_AxiBurstIncr : dfaccto_axi.t_AxiBurst
            := to_unsigned(1, dfaccto_axi.t_AxiBurst'length);

  constant c_AxiBurstWrap : dfaccto_axi.t_AxiBurst
            := to_unsigned(2, dfaccto_axi.t_AxiBurst'length);

  subtype t_AxiLock is unsigned (2-1 downto 0);
  type t_AxiLock_v is array (integer range <>) of dfaccto_axi.t_AxiLock;

  constant c_AxiLockNull : dfaccto_axi.t_AxiLock
            := to_unsigned(0, dfaccto_axi.t_AxiLock'length);

  constant c_AxiLockNormal : dfaccto_axi.t_AxiLock
            := to_unsigned(0, dfaccto_axi.t_AxiLock'length);

  constant c_AxiLockExclusive : dfaccto_axi.t_AxiLock
            := to_unsigned(1, dfaccto_axi.t_AxiLock'length);

  constant c_AxiLockLocked : dfaccto_axi.t_AxiLock
            := to_unsigned(2, dfaccto_axi.t_AxiLock'length);

  subtype t_AxiCache is unsigned (4-1 downto 0);
  type t_AxiCache_v is array (integer range <>) of dfaccto_axi.t_AxiCache;

  constant c_AxiCacheNull : dfaccto_axi.t_AxiCache
            := to_unsigned(0, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheDevNoBuf : dfaccto_axi.t_AxiCache
            := to_unsigned(0, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheDevBuf : dfaccto_axi.t_AxiCache
            := to_unsigned(1, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheNormNoBuf : dfaccto_axi.t_AxiCache
            := to_unsigned(2, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheNormBuf : dfaccto_axi.t_AxiCache
            := to_unsigned(3, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheThruRdNoA : dfaccto_axi.t_AxiCache
            := to_unsigned(10, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheThruWrNoA : dfaccto_axi.t_AxiCache
            := to_unsigned(6, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheThruAlloc : dfaccto_axi.t_AxiCache
            := to_unsigned(14, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheBackRdNoA : dfaccto_axi.t_AxiCache
            := to_unsigned(11, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheBackWrNoA : dfaccto_axi.t_AxiCache
            := to_unsigned(7, dfaccto_axi.t_AxiCache'length);

  constant c_AxiCacheBackAlloc : dfaccto_axi.t_AxiCache
            := to_unsigned(15, dfaccto_axi.t_AxiCache'length);

  subtype t_AxiProt is unsigned (3-1 downto 0);
  type t_AxiProt_v is array (integer range <>) of dfaccto_axi.t_AxiProt;

  constant c_AxiProtNull : dfaccto_axi.t_AxiProt
            := to_unsigned(0, dfaccto_axi.t_AxiProt'length);

  constant c_AxiProtFlagPriv : dfaccto_axi.t_AxiProt
            := to_unsigned(1, dfaccto_axi.t_AxiProt'length);

  constant c_AxiProtFlagSec : dfaccto_axi.t_AxiProt
            := to_unsigned(2, dfaccto_axi.t_AxiProt'length);

  constant c_AxiProtFlagInst : dfaccto_axi.t_AxiProt
            := to_unsigned(4, dfaccto_axi.t_AxiProt'length);

  subtype t_AxiQos is unsigned (4-1 downto 0);
  type t_AxiQos_v is array (integer range <>) of dfaccto_axi.t_AxiQos;

  constant c_AxiQosNull : dfaccto_axi.t_AxiQos
            := to_unsigned(0, dfaccto_axi.t_AxiQos'length);

  subtype t_AxiRegion is unsigned (4-1 downto 0);
  type t_AxiRegion_v is array (integer range <>) of dfaccto_axi.t_AxiRegion;

  constant c_AxiRegionNull : dfaccto_axi.t_AxiRegion
            := to_unsigned(0, dfaccto_axi.t_AxiRegion'length);

  subtype t_AxiResp is unsigned (2-1 downto 0);
  type t_AxiResp_v is array (integer range <>) of dfaccto_axi.t_AxiResp;

  constant c_AxiRespNull : dfaccto_axi.t_AxiResp
            := to_unsigned(0, dfaccto_axi.t_AxiResp'length);

  constant c_AxiRespOkay : dfaccto_axi.t_AxiResp
            := to_unsigned(0, dfaccto_axi.t_AxiResp'length);

  constant c_AxiRespExOkay : dfaccto_axi.t_AxiResp
            := to_unsigned(1, dfaccto_axi.t_AxiResp'length);

  constant c_AxiRespSlvErr : dfaccto_axi.t_AxiResp
            := to_unsigned(2, dfaccto_axi.t_AxiResp'length);

  constant c_AxiRespDecErr : dfaccto_axi.t_AxiResp
            := to_unsigned(3, dfaccto_axi.t_AxiResp'length);

end dfaccto_axi;
