library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_ctrl.all;
use work.fosi_util.all;

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
-- entity RegisterFile is
--   generic (
--     g_RegCount    : natural);
--   port (
--     ai_sys.clk        : in  std_logic;
--     ai_sys.rst_n      : in  std_logic;
--
--     pi_regs_ms    : in  t_RegPort_ms;
--     po_regs_sm    : out t_RegPort_sm;
--
--     pi_regRd      : in  t_RegData_v (g_RegCount-1 downto 0);
--     po_regWr      : out t_RegData_v (g_RegCount-1 downto 0);
--
--     po_eventRdAny : out std_logic;
--     po_eventWrAny : out std_logic;
--     po_eventRd    : out unsigned (g_RegCount-1 downto 0);
--     po_eventWr    : out unsigned (g_RegCount-1 downto 0));
-- end RegisterFile;

architecture RegisterFile of RegisterFile is
  alias ai_sys is {{x_psys.identifier}};

  alias as_reg_ms is {{x_ps_reg.identifier_ms}};
  alias as_reg_sm is {{x_ps_reg.identifier_ms}};

  signal so_regs_sm_ready : std_logic;
  signal so_regWr         : t_RegData_v (g_RegCount-1 downto 0);

begin

  po_regs_sm.ready <= so_regs_sm_ready;
  po_regWr <= so_regWr;
  process (ai_sys.clk)
    variable v_portAddr : integer range 0 to 2**pi_regs_ms.addr'length-1;
  begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      v_portAddr := to_integer(pi_regs_ms.addr);
      po_eventRdAny <= '0';
      po_eventWrAny <= '0';
      po_eventRd    <= (others => '0');
      po_eventWr    <= (others => '0');

      if ai_sys.rst_n = '0' then
        po_regs_sm.rddata <= (others => '0');
        so_regs_sm_ready <= '0';
        so_regWr <= (others => (others => '0'));
      else
        if pi_regs_ms.valid = '1' and so_regs_sm_ready = '0' then
          so_regs_sm_ready <= '1';
          if v_portAddr < g_RegCount then
            po_regs_sm.rddata <= pi_regRd(v_portAddr);
            if pi_regs_ms.wrnotrd = '1' then
              so_regWr(v_portAddr) <= f_byteMux(pi_regs_ms.wrstrb, so_regWr(v_portAddr), pi_regs_ms.wrdata);
              po_eventWr(v_portAddr) <= '1';
              po_eventWrAny <= '1';
            else
              po_eventRd(v_portAddr) <= '1';
              po_eventRdAny <= '1';
            end if;
          else
            po_regs_sm.rddata <= (others => '0');
          end if;
        else
          so_regs_sm_ready <= '0';
        end if;
      end if;
    end if;
  end process;

end RegisterFile;
