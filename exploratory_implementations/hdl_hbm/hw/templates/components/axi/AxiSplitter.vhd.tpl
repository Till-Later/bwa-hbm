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

architecture AxiSplitter of AxiSplitter is

  alias ai_sys is {{x_psys.identifier}};

{{^ x_pm_axi.type.x_is_axi}}
  report "Axi is not an Axi type!"; severity failure;
{{/ x_pm_axi.type.x_is_axi}}
  alias am_axi_ms is {{x_pm_axi.identifier_ms}};
  alias am_axi_sm is {{x_pm_axi.identifier_sm}};

{{^ x_ps_axiRd.type.x_is_axi}}
  report "AxiRd is not an Axi type!"; severity failure;
{{/ x_ps_axiRd.type.x_is_axi}}
  alias as_axiRd_ms is {{x_ps_axiRd.identifier_ms}};
  alias as_axiRd_sm is {{x_ps_axiRd.identifier_sm}};

{{^ x_ps_axiWr.type.x_is_axi}}
  report "AxiWr is not an Axi type!"; severity failure;
{{/ x_ps_axiWr.type.x_is_axi}}
  alias as_axiWr_ms is {{x_ps_axiWr.identifier_ms}};
  alias as_axiWr_sm is {{x_ps_axiWr.identifier_sm}};


begin

  am_axi_ms <= f_nativeAxiJoinRdWr_ms(as_axiRd_ms, as_axiWr_ms);
  as_axiRd_sm <= f_nativeAxiSplitRd_sm(am_axi_sm);
  as_axiWr_sm <= f_nativeAxiSplitWr_sm(am_axi_sm);

end AxiSplitter;
