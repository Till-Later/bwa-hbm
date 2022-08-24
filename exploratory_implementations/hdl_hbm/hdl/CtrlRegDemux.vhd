library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_ctrl.all;
use work.fosi_util.all;


-- entity CtrlRegDemux is
--   generic (
--     g_Ports : t_RegMap);
--   port (
--     pi_clk          : in std_logic;
--     pi_rst_n        : in std_logic;
--
--     pi_ctrl_ms      : in  t_Ctrl_ms;
--     po_ctrl_sm      : out t_Ctrl_sm;
--
--     po_ports_ms     : out t_RegPort_v_ms(g_Ports'length-1 downto 0);
--     pi_ports_sm     : in  t_RegPort_v_sm(g_Ports'length-1 downto 0));
-- end CtrlRegDemux;

architecture CtrlRegDemux of CtrlRegDemux is

  subtype t_PortNumber is integer range g_Ports'range;
  constant c_PortNumLow : integer := g_Ports'low;
  constant c_PortNumHigh : integer := g_Ports'high;
  constant c_PortNumCount : integer := g_Ports'length;
  constant c_PortNumWidth : integer := f_clog2(g_Ports'length);

  -- valid & portNumber & relAddr
  subtype t_DecodedAddr is unsigned (c_PortNumWidth+c_RegAddrWidth downto 0);

  function f_decode(v_absAddr : t_RegAddr) return t_DecodedAddr is
    variable v_idx : t_PortNumber;
    variable v_portBegin : t_RegAddr;
    variable v_portCount : t_RegAddr;
    variable v_portAddr : t_RegAddr;
    variable v_resPort : t_PortNumber;
    variable v_resAddr : t_RegAddr;
    variable v_guard : boolean;
  begin
    v_guard := false;
    v_resPort := 0;
    v_resAddr := (others => '0');
    for v_idx in g_Ports'range loop
      v_portBegin := g_Ports(v_idx)(0);
      v_portCount := g_Ports(v_idx)(1);
      v_portAddr := v_absAddr - v_portBegin;
      if v_absAddr >= v_portBegin and v_portAddr < v_portCount and not v_guard then
        v_guard := true;
        v_resPort := v_idx;
        v_resAddr := v_portAddr;
      end if;
    end loop;
    return f_logic(v_guard) &
            to_unsigned(v_resPort-g_Ports'low, c_PortNumWidth) &
            v_resAddr;
  end f_decode;

  signal s_decodedAddr : t_DecodedAddr;

  -- AXI protocol state
  type t_State is (Idle, ReadWait, ReadAck, WriteWait, WriteAck);
  signal s_state : t_State;
  signal s_portNumber : t_PortNumber;

begin

  process (pi_clk)
    variable v_decAddr : t_DecodedAddr;
    variable v_valid : std_logic;
    variable v_portNumber : t_PortNumber;
    variable v_relAddr : t_RegAddr;
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_state <= Idle;
        s_portNumber <= g_Ports'low;
        po_ctrl_sm <= c_CtrlNull_sm;
        po_ports_ms <= (others => c_RegPortNull_ms);
      else
        case s_state is

          when Idle =>
            if pi_ctrl_ms.awvalid = '1' and pi_ctrl_ms.wvalid = '1' then
              v_decAddr := f_decode(pi_ctrl_ms.awaddr(c_RegAddrWidth+1 downto 2));
              v_valid := v_decAddr(c_PortNumWidth + c_RegAddrWidth);
              v_portNumber := g_Ports'low + to_integer(f_resize(v_decAddr, c_PortNumWidth, c_RegAddrWidth));
              v_relAddr := f_resize(v_decAddr, c_RegAddrWidth);
              s_decodedAddr <= v_decAddr;
              if v_valid = '1' then
                s_portNumber <= v_portNumber;
                po_ports_ms(v_portNumber).addr <= v_relAddr;
                po_ports_ms(v_portNumber).wrdata <= pi_ctrl_ms.wdata;
                po_ports_ms(v_portNumber).wrstrb <= pi_ctrl_ms.wstrb;
                po_ports_ms(v_portNumber).wrnotrd <= '1';
                po_ports_ms(v_portNumber).valid <= '1';
                s_state <= WriteWait;
              else
                po_ctrl_sm.awready <= '1';
                po_ctrl_sm.wready <= '1';
                -- bresp is always OKAY, absent registers ignore writes
                po_ctrl_sm.bresp <= "00";
                po_ctrl_sm.bvalid <= '1';
                s_state <= WriteAck;
              end if;
            elsif pi_ctrl_ms.arvalid = '1' then
              v_decAddr := f_decode(pi_ctrl_ms.araddr(c_RegAddrWidth+1 downto 2));
              v_valid := v_decAddr(c_PortNumWidth + c_RegAddrWidth);
              v_portNumber := g_Ports'low + to_integer(f_resize(v_decAddr, c_PortNumWidth, c_RegAddrWidth));
              v_relAddr := f_resize(v_decAddr, c_RegAddrWidth);
              s_decodedAddr <= v_decAddr;
              if v_valid = '1' then
                s_portNumber <= v_portNumber;
                po_ports_ms(v_portNumber).addr <= v_relAddr;
                po_ports_ms(v_portNumber).wrdata <= (others => '0');
                po_ports_ms(v_portNumber).wrstrb <= (others => '0');
                po_ports_ms(v_portNumber).wrnotrd <= '0';
                po_ports_ms(v_portNumber).valid <= '1';
                s_state <= ReadWait;
              else
                po_ctrl_sm.arready <= '1';
                -- rresp is always OKAY, absent registers read zero
                po_ctrl_sm.rdata <= (others => '0');
                po_ctrl_sm.rresp <= "00";
                po_ctrl_sm.rvalid <= '1';
                s_state <= ReadAck;
              end if;
            end if;

          when WriteWait =>
            if pi_ports_sm(s_portNumber).ready = '1' then
              po_ports_ms(v_portNumber).valid <= '0';
              po_ctrl_sm.awready <= '1';
              po_ctrl_sm.wready <= '1';
              po_ctrl_sm.bresp <= "00";
              po_ctrl_sm.bvalid <= '1';
              s_state <= WriteAck;
            end if;

          when WriteAck =>
            po_ctrl_sm.wready <= '0';
            po_ctrl_sm.awready <= '0';
            if pi_ctrl_ms.bready = '1' then
              po_ctrl_sm.bvalid <= '0';
              s_state <= Idle;
            end if;

          when ReadWait =>
            if pi_ports_sm(s_portNumber).ready = '1' then
              po_ports_ms(v_portNumber).valid <= '0';
              po_ctrl_sm.arready <= '1';
              po_ctrl_sm.rdata <= pi_ports_sm(s_portNumber).rddata;
              po_ctrl_sm.rresp <= "00";
              po_ctrl_sm.rvalid <= '1';
              s_state <= ReadAck;
            end if;

          when ReadAck =>
            po_ctrl_sm.arready <= '0';
            if pi_ctrl_ms.rready = '1' then
              po_ctrl_sm.rvalid <= '0';
              s_state <= Idle;
            end if;

        end case;
      end if;
    end if;
  end process;

end CtrlRegDemux;
