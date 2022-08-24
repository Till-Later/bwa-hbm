library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}

entity {{identifier}} is
{{?generics}}
  generic (
{{# generics}}
{{#  is_complex}}
    {{identifier_ms}} : {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
    {{identifier_sm}} : {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/ is_complex}}
{{/generics}}
{{/generics}}
{{?ports}}
  port (
{{# ports}}
{{#  is_complex}}
    {{identifier_ms}} : {{mode_ms}} {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}};
    {{identifier_sm}} : {{mode_sm}} {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{mode}} {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/ is_complex}}
{{/ports}}
{{/ports}}
end {{identifier}};

architecture AxiNullSlave of {{identifier}} is
    alias as_slave_ms is {{x_ps_slave.identifier_ms}};
    alias as_slave_sm is {{x_ps_slave.identifier_sm}};
begin

-- Slave to Master
    -- Write Channel
{{?x_ps_slave.type.x_has_wr}}
    as_slave_sm.awready <= {{x_ps_slave.type.x_tlogic.x_cnull.qualified}};

    as_slave_sm.wready <= {{x_ps_slave.type.x_tlogic.x_cnull.qualified}};

    as_slave_sm.bresp <= {{x_ps_slave.type.x_tresp.x_cnull.qualified}};

    {{?x_ps_slave.type.x_tid}}
    as_slave_sm.bid <= {{x_ps_slave.type.x_tid.x_cnull.qualified}};
    {{/x_ps_slave.type.x_tid}}

    {{?x_ps_slave.type.x_tbuser}}
    as_slave_sm.buser <= {{x_ps_slave.type.x_tbuser.x_cnull.qualified}};
    {{/x_ps_slave.type.x_tbuser}}

    as_slave_sm.bvalid <= {{x_ps_slave.type.x_tlogic.x_cnull.qualified}};
{{/x_ps_slave.type.x_has_wr}}

    -- Read Channel
{{?x_ps_slave.type.x_has_rd}}
    as_slave_sm.arready <= {{x_ps_slave.type.x_tlogic.x_cnull.qualified}};

    as_slave_sm.rdata <= {{x_ps_slave.type.x_tdata.x_cnull.qualified}};

    as_slave_sm.rresp <= {{x_ps_slave.type.x_tresp.x_cnull.qualified}};

    {{?x_ps_slave.type.x_tlast}}
    as_slave_sm.rlast <= {{x_ps_slave.type.x_tlogic.x_cnull.qualified}};
    {{/x_ps_slave.type.x_tlast}}

    {{?x_ps_slave.type.x_tid}}
    as_slave_sm.rid <= {{x_ps_slave.type.x_tid.x_cnull.qualified}};
    {{/x_ps_slave.type.x_tid}}

    {{?x_ps_slave.type.x_truser}}
    as_slave_sm.ruser <= {{x_ps_slave.type.x_truser.x_cnull.qualified}};
    {{/x_ps_slave.type.x_truser}}

    as_slave_sm.rvalid <= {{x_ps_slave.type.x_tlogic.x_cnull.qualified}};
{{/x_ps_slave.type.x_has_rd}}

end AxiNullSlave;