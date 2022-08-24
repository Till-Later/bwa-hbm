library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_axi.all;
use work.fosi_blockmap.all;
use work.fosi_util.all;


entity AxiBlockMapper is
  port (
    pi_clk       : in  std_logic;
    pi_rst_n     : in  std_logic;

    pi_axiLog_od : in  t_NativeAxiA_od;
    po_axiLog_do : out t_NativeAxiA_do;
    po_axiPhy_od : out t_NativeAxiA_od;
    pi_axiPhy_do : in  t_NativeAxiA_do;

    po_store_ms : out t_BlkMap_ms;
    pi_store_sm : in  t_BlkMap_sm;

    po_status   : out unsigned(11 downto 0));
end AxiBlockMapper;

architecture AxiBlockMapper of AxiBlockMapper is

  signal s_logAddr : t_LBlk;
  signal s_phyAddr : t_PBlk;
  signal s_phyAddrConcat : unsigned (t_PBlk'length+t_BlkOffset'length-1 downto 0);
  signal s_blkOffset : t_BlkOffset;
  signal s_relativeBlk : t_LBlk;
  signal s_match : std_logic;

  type t_State is (Idle, FlushAck, MapWait, TestAddr, Pass, Blocked);
  signal s_state : t_State;

  signal s_cacheLBase  : t_LBlk;
  signal s_cacheLLimit : t_LBlk;
  signal s_cachePBase  : t_PBlk;

  -- Status Output
  signal s_stateEnc : unsigned (3 downto 0);

begin

  -- Splice relevant signals from address channels
  s_logAddr <= f_resize(pi_axiLog_od.addr, c_LBlkWidth, c_BlkOffsetWidth);
  s_blkOffset <= f_resize(pi_axiLog_od.addr, c_BlkOffsetWidth);
  s_phyAddrConcat <= s_phyAddr & s_blkOffset;
  po_axiPhy_od.addr <= f_resize(s_phyAddrConcat, po_axiPhy_od.addr'length);
  po_axiPhy_od.len <= pi_axiLog_od.len;
  po_axiPhy_od.size <= pi_axiLog_od.size;
  po_axiPhy_od.burst <= pi_axiLog_od.burst;

  with s_state select po_store_ms.flushAck <=
    '1' when FlushAck,
    '1' when MapWait, -- Fetching new Mapping implies Flushing Cached Mapping
    '0' when others;
  po_store_ms.mapLBlk <= s_logAddr;
  with s_state select po_store_ms.mapReq <=
    '1' when MapWait,
    '0' when others;

  with s_state select po_axiPhy_od.valid <=
    '1' when Pass,
    '0' when others;
  with s_state select po_axiLog_do.ready <=
    pi_axiPhy_do.ready when Pass,
    '0' when others;

  with s_state select po_store_ms.blocked <=
    '1' when Blocked,
    '0' when others;

  -- Mapping State Machine
  process(pi_clk)
    variable v_relativeBlk : t_LBlk;
    variable v_match : boolean;
  begin
    if pi_clk'event and pi_clk = '1' then
      v_relativeBlk := s_logAddr - s_cacheLBase;
      s_relativeBlk <= v_relativeBlk;
      v_match := s_logAddr >= s_cacheLBase and s_logAddr < s_cacheLLimit;
      s_match <= f_logic(v_match);

      if pi_rst_n = '0' then
        s_cacheLBase <= c_InvalidLBlk;
        s_cacheLLimit <= c_InvalidLBlk;
        s_cachePBase <= c_InvalidPBlk;
        s_phyAddr <= (others => '0');
        s_state <= Idle;
      else
        case s_state is
          when Idle =>
            if pi_store_sm.flushReq = '1' then
              s_cacheLBase <= c_InvalidLBlk;
              s_cacheLLimit <= c_InvalidLBlk;
              s_cachePBase <= c_InvalidPBlk;
              s_state <= FlushAck;
            elsif pi_axiLog_od.valid = '1' and v_match then
              s_phyAddr <= s_cachePBase + v_relativeBlk;
              s_state <= Pass;
            elsif pi_axiLog_od.valid = '1' then
              s_state <= MapWait;
            end if;

          when FlushAck =>
            if pi_axiLog_od.valid = '1' then
              s_state <= MapWait;
            end if;

          when MapWait =>
            if pi_store_sm.mapAck = '1' then
              s_cacheLBase <= pi_store_sm.mapLBase;
              s_cacheLLimit <= pi_store_sm.mapLLimit;
              s_cachePBase <= pi_store_sm.mapPBase;
              s_state <= TestAddr;
            end if;

          when TestAddr =>
            if v_match then
              s_phyAddr <= s_cachePBase + v_relativeBlk;
              s_state <= Pass;
            else
              s_state <= Blocked;
            end if;

          when Pass =>
            if pi_axiPhy_do.ready = '1' then
              s_phyAddr <= (others => '0');
              s_state <= Idle;
            end if;

          when Blocked =>
            if pi_store_sm.flushReq = '1' then
              s_cacheLBase <= c_InvalidLBlk;
              s_cacheLLimit <= c_InvalidLBlk;
              s_cachePBase <= c_InvalidPBlk;
              s_state <= FlushAck;
            end if;

        end case;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Status Output
  -----------------------------------------------------------------------------
  with s_state select s_stateEnc <=
    "0000" when Idle,
    "0001" when MapWait,
    "0010" when TestAddr,
    "0011" when Pass,
    "0100" when FlushAck,
    "0111" when Blocked;
  po_status <= s_stateEnc & f_resize(s_cacheLBase, 4) & f_resize(s_cacheLLimit, 4);

end AxiBlockMapper;
