library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_blockmap.all;
use work.fosi_ctrl.all;
use work.fosi_util.all;


entity ExtentStore_PortMachine is
  generic (
    g_PortCount     : integer;
    g_PortNumber    : integer);
  port (
    pi_clk          : in  std_logic;
    pi_rst_n        : in  std_logic;

    pi_port_ms      : in  t_BlkMap_ms;
    po_port_sm      : out t_BlkMap_sm;

    pi_halt         : in  std_logic;
    pi_flush        : in  std_logic;
    pi_rowConfig    : in  t_RegData;
    po_currentLBlk  : out t_LBlk;
    po_blocked      : out std_logic;

    po_reqEn        : out std_logic;
    po_reqData      : out t_MapReq;
    pi_reqAck       : in  std_logic;

    pi_resEn        : in  std_logic;
    pi_resPort      : in  unsigned(f_clog2(g_PortCount)-1 downto 0);
    pi_resData      : in  t_MapRes;

    po_status       : out unsigned(3 downto 0));
end ExtentStore_PortMachine;

architecture ExtentStore_PortMachine of ExtentStore_PortMachine is

  constant c_PortAddrWidth : integer := f_clog2(g_PortCount);
  subtype t_PortAddr is unsigned (c_PortAddrWidth-1 downto 0);
  constant c_ThisPort : t_PortAddr := to_unsigned(g_PortNumber, c_PortAddrWidth);

  constant c_LRowListWidth : integer := c_RegDataWidth - c_LRowAddrWidth;
  subtype t_LRowList is unsigned (c_LRowListWidth-1 downto 0);
  signal s_cfgRowList : t_LRowList;
  signal s_cfgRowCount : t_LRowAddr;

  signal s_flush : std_logic;

  type t_State is (Idle, Halt, ReqWait, ResCollect, MapAckCollect, Collect, FlushWait);
  signal s_state : t_State;

  constant c_CountOne : t_LRowAddr := to_unsigned(1, c_LRowAddrWidth);
  signal s_rowList  : t_LRowList;
  signal s_rowCount : t_LRowAddr;
  signal s_reqCount : t_LRowAddr;
  signal s_resCount : t_LRowAddr;

begin

  s_cfgRowCount <= f_resize(pi_rowConfig, c_LRowAddrWidth, 0);
  s_cfgRowList <= f_resize(pi_rowConfig, c_LRowListWidth, c_LRowAddrWidth);

  po_blocked <= pi_port_ms.blocked;
  po_currentLBlk <= pi_port_ms.mapLBlk;
  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_flush <= '0';
      else
        if s_state = FlushWait then
          s_flush <= '0';
        elsif pi_flush = '1' then
          s_flush <= '1';
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- State Machine
  -----------------------------------------------------------------------------

  process(s_reqCount, s_rowList)
    variable v_idx : integer range 0 to c_LRowCount;
  begin
    v_idx := to_integer(s_reqCount);
    po_reqData.rowAddr <= s_rowList(c_LRowAddrWidth*(v_idx+1)-1 downto c_LRowAddrWidth*v_idx);
  end process;
  po_reqData.lblock <= pi_port_ms.mapLBlk;

  with s_state select po_reqEn <=
    '1' when ReqWait,
    '0' when others;

  with s_state select po_port_sm.mapAck <=
    '1' when MapAckCollect,
    '0' when others;
  with s_state select po_port_sm.flushReq <=
    '1' when FlushWait,
    '0' when others;

  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        po_port_sm.mapLBase <= c_InvalidLBlk;
        po_port_sm.mapLLimit <= c_InvalidLBlk;
        po_port_sm.mapPBase <= c_InvalidPBlk;
        s_rowList  <= (others => '0');
        s_rowCount <= (others => '0');
        s_reqCount <= (others => '0');
        s_resCount <= (others => '0');
        s_state <= Idle;
      else
        if s_state = ReqWait and pi_reqAck = '1' then
          s_reqCount <= s_reqCount + c_CountOne;
        end if;
        if pi_resEn = '1' and pi_resPort = c_ThisPort then
          s_resCount <= s_resCount + c_CountOne;
        end if;
        case s_state is

          when Idle =>
            if pi_halt = '1' then
              s_state <= Halt;
            elsif s_flush = '1' then
              s_state <= FlushWait;
            elsif pi_port_ms.mapReq = '1' then
              if s_cfgRowCount = to_unsigned(0, c_LRowAddrWidth) then
                po_port_sm.mapLBase <= c_InvalidLBlk;
                po_port_sm.mapLLimit <= c_InvalidLBlk;
                po_port_sm.mapPBase <= c_InvalidPBlk;
                s_state <= MapAckCollect;
              else
                s_rowList  <= s_cfgRowList;
                s_rowCount <= s_cfgRowCount;
                s_reqCount <= (others => '0');
                s_resCount <= (others => '0');
                s_state <= ReqWait;
              end if;
            end if;

          when Halt =>
            if pi_halt = '0' then
              s_state <= Collect;
            end if;

          when ReqWait =>
            if pi_halt = '1' then
              s_state <= Halt;
            else
              if pi_resEn = '1' and pi_resPort = c_ThisPort and pi_resData.valid = '1' then
                po_port_sm.mapLBase <= pi_resData.lbase;
                po_port_sm.mapLLimit <= pi_resData.llimit;
                po_port_sm.mapPBase <= pi_resData.pbase;
                s_state <= MapAckCollect;
              elsif (s_reqCount + c_CountOne) = s_rowCount and pi_reqAck = '1' then
                s_state <= ResCollect;
              end if;
            end if;

          when ResCollect =>
            if pi_halt = '1' then
              s_state <= Halt;
            elsif pi_resEn = '1' and pi_resPort = c_ThisPort and pi_resData.valid = '1' then
              po_port_sm.mapLBase <= pi_resData.lbase;
              po_port_sm.mapLLimit <= pi_resData.llimit;
              po_port_sm.mapPBase <= pi_resData.pbase;
              s_state <= MapAckCollect;
            elsif (s_resCount + c_CountOne) = s_reqCount and pi_resEn = '1' and pi_resPort = c_ThisPort then
              -- TODO-lw: checking resCount >= reqCount is fragile if responses are not properly collected
              po_port_sm.mapLBase <= c_InvalidLBlk;
              po_port_sm.mapLLimit <= c_InvalidLBlk;
              po_port_sm.mapPBase <= c_InvalidPBlk;
              s_state <= MapAckCollect;
            end if;

          when MapAckCollect =>
            if pi_halt = '1' then
              s_state <= Halt;
            elsif s_resCount = s_reqCount then
              s_state <= Idle;
            else
              s_state <= Collect;
            end if;

          when Collect =>
            if pi_halt = '1' then
              s_state <= Halt;
            elsif s_resCount = s_reqCount then
              s_state <= Idle;
            end if;

          when FlushWait =>
            if pi_port_ms.flushAck = '1' then
              if pi_halt = '1' then
                s_state <= Halt;
              else
                s_state <= Idle;
              end if;
            end if;

        end case;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Status Output
  -----------------------------------------------------------------------------
  with s_state select po_status <=
    "0000" when Idle,
    "0100" when ReqWait,
    "0101" when ResCollect,
    "0110" when MapAckCollect,
    "0111" when Collect,
    "0001" when FlushWait,
    "0011" when Halt;

end ExtentStore_PortMachine;
