library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_ctrl.all;
use work.fosi_stream.all;
use work.fosi_user.all;
use work.fosi_util.all;


{{#x_type.x_stream}}
entity {{name}} is
  generic (
    g_InPortCount  : integer range 1 to 15;
    g_OutPortCount : integer range 1 to 16);
  port (
    pi_clk       : in std_logic;
    pi_rst_n     : in std_logic;

    pi_stmIn_ms  : in  {{x_type.identifier_v_ms}}(g_InPortCount-1 downto 0);
    po_stmIn_sm  : out {{x_type.identifier_v_sm}}(g_InPortCount-1 downto 0);

    po_stmOut_ms : out {{x_type.identifier_v_ms}}(g_OutPortCount-1 downto 0);
    pi_stmOut_sm : in  {{x_type.identifier_v_sm}}(g_OutPortCount-1 downto 0);

    -- Control port (2 registers):
    --  OutPort n is mapped to InPort Reg1&Reg0(4n+3..4n)
    --  Reg0: Mappings for OutPorts 0 to 7
    --  Reg1: Mappings for OutPorts 8 to 15
    --  InPort 15 disables the OutPort
    --  Unmapped InPorts are disabled
    pi_regs_ms   : in  t_RegPort_ms;
    po_regs_sm   : out t_RegPort_sm);
end {{name}};

architecture {{name}} of {{name}} is

  subtype t_PortIndex is integer range 0 to 15;
  type t_PortGuards is array (0 to 15) of boolean;

  signal s_mapping        : unsigned(g_OutPortCount*4-1 downto 0);
  signal s_inPorts_ms     : {{x_type.identifier_v_ms}}(g_InPortCount-1 downto 0);
  signal s_inPorts_sm     : {{x_type.identifier_v_sm}}(g_InPortCount-1 downto 0);
  signal s_outPorts_ms    : {{x_type.identifier_v_ms}}(g_OutPortCount-1 downto 0);
  signal s_outPorts_sm    : {{x_type.identifier_v_sm}}(g_OutPortCount-1 downto 0);

  signal so_regs_sm_ready : std_logic;
  signal s_regMap : unsigned(2*c_RegDataWidth-1 downto 0);
  alias  a_regMapLo is s_regMap(c_RegDataWidth-1 downto 0);
  alias  a_regMapHi is s_regMap(2*c_RegDataWidth-1 downto c_RegDataWidth);

begin

  s_mapping <= f_resize(s_regMap, s_mapping'length);

  -----------------------------------------------------------------------------
  -- Stream Switch
  -----------------------------------------------------------------------------
  s_inPorts_ms   <= pi_stmIn_ms;
  po_stmIn_sm  <= s_inPorts_sm;
  po_stmOut_ms <= s_outPorts_ms;
  s_outPorts_sm  <= pi_stmOut_sm;
  process(s_mapping, s_inPorts_ms, s_outPorts_sm)
    variable v_guards : t_PortGuards;
    variable v_srcPort : t_PortIndex;
    variable v_dstPort : t_PortIndex;
  begin
    v_guards := (others => false);
    s_inPorts_sm <= (others => {{x_type.const_null_sm}});
    for v_dstPort in 0 to g_OutPortCount-1 loop
      v_srcPort := to_integer(s_mapping(4*v_dstPort+3 downto 4*v_dstPort));
      if v_srcPort < g_InPortCount and not v_guards(v_srcPort) then
        v_guards(v_srcPort) := true;
        s_outPorts_ms(v_dstPort) <= s_inPorts_ms(v_srcPort);
        s_inPorts_sm(v_srcPort) <= s_outPorts_sm(v_dstPort);
      else
        s_outPorts_ms(v_dstPort) <= {{x_type.const_null_ms}};
      end if;
    end loop;
  end process;

  -----------------------------------------------------------------------------
  -- Register Access
  -----------------------------------------------------------------------------
  po_regs_sm.ready <= so_regs_sm_ready;
  process (pi_clk)
    variable v_portAddr : integer range 0 to 2**pi_regs_ms.addr'length-1;
  begin
    if pi_clk'event and pi_clk = '1' then
      v_portAddr := to_integer(pi_regs_ms.addr);
      if pi_rst_n = '0' then
        po_regs_sm.rddata <= (others => '0');
        so_regs_sm_ready <= '0';
        s_regMap <= (others => '0');
      else
        if pi_regs_ms.valid = '1' and so_regs_sm_ready = '0' then
          so_regs_sm_ready <= '1';
          case v_portAddr is
            when 0 =>
              po_regs_sm.rddata <= a_regMapLo;
              if pi_regs_ms.wrnotrd = '1' then
                a_regMapLo <= f_byteMux(pi_regs_ms.wrstrb, a_regMapLo, pi_regs_ms.wrdata);
              end if;
            when 1 =>
              po_regs_sm.rddata <= a_regMapHi;
              if pi_regs_ms.wrnotrd = '1' then
                a_regMapHi <= f_byteMux(pi_regs_ms.wrstrb, a_regMapHi, pi_regs_ms.wrdata);
              end if;
            when others =>
              po_regs_sm.rddata <= (others => '0');
          end case;
        else
          so_regs_sm_ready <= '0';
        end if;
      end if;
    end if;
  end process;

end {{name}};
{{/x_type.x_stream}}
{{^x_type.x_stream}}
-- {{x_type}} is not an AxiStream Type
{{/x_type.x_stream}}
