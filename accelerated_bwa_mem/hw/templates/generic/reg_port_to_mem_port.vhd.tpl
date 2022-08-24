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

architecture RegPortToMemPort of {{identifier}} is
    -- g_MemoryLatency
    alias ai_sys is {{x_psys.identifier}};

    alias am_mem_ms is {{x_pm_mem.identifier_ms}};
    alias am_mem_sm is {{x_pm_mem.identifier_sm}};

    alias as_reg_ms is {{x_ps_reg.identifier_ms}};
    alias as_reg_sm is {{x_ps_reg.identifier_sm}};

    signal s_readyBuffer : std_logic_vector(g_MemoryLatency downto 0);
begin
    process (ai_sys.clk)
    begin
        if ai_sys.clk'event and ai_sys.clk = '1' then
            if ai_sys.rst_n = '0' then
                s_readyBuffer <= (others => '0');
            else 
                am_mem_ms.addr <= as_reg_ms.addr({{x_pm_mem.type.x_taddr.x_width}}-1 downto 0);
                am_mem_ms.wdata <= as_reg_ms.wrdata;
                am_mem_ms.write <= as_reg_ms.wrnotrd;
                am_mem_ms.strobe <= as_reg_ms.valid;
                s_readyBuffer <= as_reg_ms.valid & s_readyBuffer(s_readyBuffer'high downto 1);

                as_reg_sm.rddata <= am_mem_sm.rdata;
                as_reg_sm.ready <= s_readyBuffer(s_readyBuffer'low);

            end if;
        end if;
    end process;
end RegPortToMemPort;