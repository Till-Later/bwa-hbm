library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util.all;

entity {{identifier}} is
{{?generics}}
  generic (
{{# generics}}
{{#  is_complex}}
    {{identifier_ms}} : {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
    {{identifier_sm}} : {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/  is_complex}}
{{/ generics}}
{{/generics}}
{{?ports}}
  port (
{{# ports}}
{{#  is_complex}}
    {{identifier_ms}} : {{mode_ms}} {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}};
    {{identifier_sm}} : {{mode_sm}} {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{mode}} {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/  is_complex}}
{{/ ports}}
{{/ports}}
end {{identifier}};
-- entity CtrlRegDemux is
--   generic (
--     g_Ports : t_RegMap);
--   port (
--     ai_sys.clk          : in std_logic;
--     ai_sys.rst_n        : in std_logic;
--
--     as_ctrl_ms      : in  t_Ctrl_ms;
--     as_ctrl_ms      : out t_Ctrl_sm;
--
--     am_regPorts_ms     : out t_RegPort_v_ms(g_Ports'length-1 downto 0);
--     am_regPorts_sm     : in  t_RegPort_v_sm(g_Ports'length-1 downto 0));
-- end CtrlRegDemux;

architecture CtrlRegDemux of CtrlRegDemux is
  alias ai_sys is {{x_psys.identifier}};

  alias as_ctrl_ms is {{x_ps_ctrl.identifier_ms}};
  alias as_ctrl_sm is {{x_ps_ctrl.identifier_sm}};

  alias am_regPorts_ms is {{x_pm_regPorts.identifier_ms}};
  alias am_regPorts_sm is {{x_pm_regPorts.identifier_sm}};

  subtype t_PortNumber is integer range g_Ports'range;
  constant c_PortNumLow : integer := g_Ports'low;
  constant c_PortNumHigh : integer := g_Ports'high;
  constant c_PortNumCount : integer := g_Ports'length;
  constant c_PortNumWidth : integer := f_clog2(g_Ports'length);

  -- valid & portNumber & relAddr
  subtype t_DecodedAddr is unsigned (c_PortNumWidth+{{x_pm_regPorts.type.x_tRegAddr.x_width}} downto 0);

  function f_decode(v_absAddr : {{x_pm_regPorts.type.x_tRegAddr.qualified}}) return t_DecodedAddr is
    variable v_idx : t_PortNumber;
    variable v_portBegin : {{x_pm_regPorts.type.x_tRegAddr.qualified}};
    variable v_portCount : {{x_pm_regPorts.type.x_tRegAddr.qualified}};
    variable v_portAddr  : {{x_pm_regPorts.type.x_tRegAddr.qualified}};
    variable v_resPort   : t_PortNumber;
    variable v_resAddr   : {{x_pm_regPorts.type.x_tRegAddr.qualified}};
    variable v_guard : boolean;
  begin
    v_guard := false;
    v_resPort := 0;
    v_resAddr := (others => '0');
    for v_idx in g_Ports'range loop
      v_portBegin := g_Ports(v_idx).offset;
      v_portCount := g_Ports(v_idx).count;
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

  process (ai_sys.clk)
    variable v_decAddr : t_DecodedAddr;
    variable v_valid : std_logic;
    variable v_portNumber : t_PortNumber;
    variable v_relAddr : {{x_pm_regPorts.type.x_tRegAddr.qualified}};
  begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      if ai_sys.rst_n = '0' then
        s_state <= Idle;
        s_portNumber <= g_Ports'low;
        as_ctrl_sm <= {{x_ps_ctrl.type.x_cnull.qualified_sm}};
        am_regPorts_ms <= (others => {{x_pm_regPorts.type.x_cnull.qualified_ms}});
      else
        case s_state is
          when Idle =>
            if as_ctrl_ms.awvalid = '1' and as_ctrl_ms.wvalid = '1' then
              v_decAddr := f_decode(as_ctrl_ms.awaddr({{x_pm_regPorts.type.x_tRegAddr.x_width}}+1 downto 2));
              v_valid := v_decAddr(c_PortNumWidth + {{x_pm_regPorts.type.x_tRegAddr.x_width}});
              v_portNumber := g_Ports'low + to_integer(f_resize(v_decAddr, c_PortNumWidth, {{x_pm_regPorts.type.x_tRegAddr.x_width}}));
              v_relAddr := f_resize(v_decAddr, {{x_pm_regPorts.type.x_tRegAddr.x_width}});
              s_decodedAddr <= v_decAddr;
              if v_valid = '1' then
                s_portNumber <= v_portNumber;
                am_regPorts_ms(v_portNumber).addr <= v_relAddr;
                am_regPorts_ms(v_portNumber).wrdata <= as_ctrl_ms.wdata;
                am_regPorts_ms(v_portNumber).wrstrb <= as_ctrl_ms.wstrb;
                am_regPorts_ms(v_portNumber).wrnotrd <= '1';
                am_regPorts_ms(v_portNumber).valid <= '1';
                s_state <= WriteWait;
              else
                as_ctrl_sm.awready <= '1';
                as_ctrl_sm.wready <= '1';
                -- bresp is always OKAY, absent registers ignore writes
                as_ctrl_sm.bresp <= "00";
                as_ctrl_sm.bvalid <= '1';
                s_state <= WriteAck;
              end if;
            elsif as_ctrl_ms.arvalid = '1' then
              v_decAddr := f_decode(as_ctrl_ms.araddr({{x_pm_regPorts.type.x_tRegAddr.x_width}}+1 downto 2));
              v_valid := v_decAddr(c_PortNumWidth + {{x_pm_regPorts.type.x_tRegAddr.x_width}});
              v_portNumber := g_Ports'low + to_integer(f_resize(v_decAddr, c_PortNumWidth, {{x_pm_regPorts.type.x_tRegAddr.x_width}}));
              v_relAddr := f_resize(v_decAddr, {{x_pm_regPorts.type.x_tRegAddr.x_width}});
              s_decodedAddr <= v_decAddr;
              if v_valid = '1' then
                s_portNumber <= v_portNumber;
                am_regPorts_ms(v_portNumber).addr <= v_relAddr;
                am_regPorts_ms(v_portNumber).wrdata <= (others => '0');
                am_regPorts_ms(v_portNumber).wrstrb <= (others => '0');
                am_regPorts_ms(v_portNumber).wrnotrd <= '0';
                am_regPorts_ms(v_portNumber).valid <= '1';
                s_state <= ReadWait;
              else
                as_ctrl_sm.arready <= '1';
                -- rresp is always OKAY, absent registers read zero
                as_ctrl_sm.rdata <= (others => '0');
                as_ctrl_sm.rresp <= "00";
                as_ctrl_sm.rvalid <= '1';
                s_state <= ReadAck;
              end if;
            end if;

          when WriteWait =>
            if am_regPorts_sm(s_portNumber).ready = '1' then
              am_regPorts_ms(v_portNumber).valid <= '0';
              as_ctrl_sm.awready <= '1';
              as_ctrl_sm.wready <= '1';
              as_ctrl_sm.bresp <= "00";
              as_ctrl_sm.bvalid <= '1';
              s_state <= WriteAck;
            end if;

          when WriteAck =>
            as_ctrl_sm.wready <= '0';
            as_ctrl_sm.awready <= '0';
            if as_ctrl_ms.bready = '1' then
              as_ctrl_sm.bvalid <= '0';
              s_state <= Idle;
            end if;

          when ReadWait =>
            if am_regPorts_sm(s_portNumber).ready = '1' then
              am_regPorts_ms(v_portNumber).valid <= '0';
              as_ctrl_sm.arready <= '1';
              as_ctrl_sm.rdata <= am_regPorts_sm(s_portNumber).rddata;
              as_ctrl_sm.rresp <= "00";
              as_ctrl_sm.rvalid <= '1';
              s_state <= ReadAck;
            end if;

          when ReadAck =>
            as_ctrl_sm.arready <= '0';
            if as_ctrl_ms.rready = '1' then
              as_ctrl_sm.rvalid <= '0';
              s_state <= Idle;
            end if;

        end case;
      end if;
    end if;
  end process;

end CtrlRegDemux;
