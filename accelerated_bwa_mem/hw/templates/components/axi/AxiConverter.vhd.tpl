library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util.f_resize;

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

architecture AxiConverter of {{identifier}} is
    alias am_master_ms is {{x_pm_master.identifier_ms}};
    alias am_master_sm is {{x_pm_master.identifier_sm}};

    alias as_slave_ms is {{x_ps_slave.identifier_ms}};
    alias as_slave_sm is {{x_ps_slave.identifier_sm}};
begin

-- Master to Slave
    -- Write Channel
{{?x_pm_master.type.x_has_wr}}
    {{^x_ps_slave.type.x_has_wr}}
    report "Master has write channel, but slave doesn't!" severity error;
    {{/x_ps_slave.type.x_has_wr}}

    am_master_ms.awaddr <= f_resize(as_slave_ms.awaddr, {{x_pm_master.type.x_taddr.x_width}});

    {{? x_pm_master.type.x_tlen}}
    {{=x_ps_slave.type}}
    am_master_ms.awlen <= {{=.x_tlen}}f_resize(as_slave_ms.awlen, {{x_pm_master.type.x_tlen.x_width}}) {{|.x_tlen}}{{x_pm_master.type.x_tlen.x_cnull.qualified}}{{/.x_tlen}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tlen}}

    {{? x_pm_master.type.x_tsize}}
    {{=x_ps_slave.type}}
    am_master_ms.awsize <= {{=.x_tsize}}f_resize(as_slave_ms.awsize, {{x_pm_master.type.x_tsize.x_width}}){{|.x_tsize}}{{x_pm_master.type.x_tsize.x_cnull.qualified}}{{/.x_tsize}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tsize}}

    {{? x_pm_master.type.x_tburst}}
    {{=x_ps_slave.type}}
    am_master_ms.awburst <= {{=.x_tburst}}f_resize(as_slave_ms.awburst, {{x_pm_master.type.x_tburst.x_width}}){{|.x_tburst}}{{x_pm_master.type.x_tlock.x_cnull.qualified}}{{/.x_tburst}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tburst}}

    {{? x_pm_master.type.x_tlock}}
    {{=x_ps_slave.type}}
    am_master_ms.awlock <= {{=.x_tlock}}f_resize(as_slave_ms.awlock, {{x_pm_master.type.x_tlock.x_width}}){{|.x_tlock}}{{x_pm_master.type.x_tlock.x_cnull.qualified}}{{/.x_tlock}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tlock}}

    {{? x_pm_master.type.x_tcache}}
    {{=x_ps_slave.type}}
    am_master_ms.awcache <= {{=.x_tcache}}f_resize(as_slave_ms.awcache, {{x_pm_master.type.x_tcache.x_width}}){{|.x_tcache}}{{x_pm_master.type.x_tcache.x_cnull.qualified}}{{/.x_tcache}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tcache}}

    {{? x_pm_master.type.x_tprot}}
    {{=x_ps_slave.type}}
    am_master_ms.awprot <= {{=.x_tprot}}f_resize(as_slave_ms.awprot, {{x_pm_master.type.x_tprot.x_width}}){{|.x_tprot}}{{x_pm_master.type.x_tprot.x_cnull.qualified}}{{/.x_tprot}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tprot}}

    {{? x_pm_master.type.x_tqos}}
    {{=x_ps_slave.type}}
    am_master_ms.awqos <= {{=.x_tqos}}f_resize(as_slave_ms.awqos, {{x_pm_master.type.x_tqos.x_width}}){{|.x_tqos}}{{x_pm_master.type.x_tqos.x_cnull.qualified}}{{/.x_tqos}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tqos}}

    {{? x_pm_master.type.x_tregion}}
    {{=x_ps_slave.type}}
    am_master_ms.awregion <= {{=.x_tregion}}f_resize(as_slave_ms.awregion, {{x_pm_master.type.x_tregion.x_width}}){{|.x_tregion}}{{x_pm_master.type.x_tregion.x_cnull.qualified}}{{/.x_tregion}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tregion}}

    {{? x_pm_master.type.x_tid}}
    {{=x_ps_slave.type}}
    am_master_ms.awid <= {{=.x_tid}}f_resize(as_slave_ms.awid, {{x_pm_master.type.x_tid.x_width}}){{|.x_tid}}{{x_pm_master.type.x_tid.x_cnull.qualified}}{{/.x_tid}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tid}}

    {{? x_pm_master.type.x_tawuser}}
    {{=x_ps_slave.type}}
    am_master_ms.awuser <= {{=.x_tawuser}}f_resize(as_slave_ms.awuser, {{x_pm_master.type.x_tawuser.x_width}}){{|.x_tawuser}}{{x_pm_master.type.x_tawuser.x_cnull.qualified}}{{/.x_tawuser}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tawuser}}

    am_master_ms.awvalid <= as_slave_ms.awvalid;

    am_master_ms.wdata <= f_resize(as_slave_ms.wdata, {{x_pm_master.type.x_tdata.x_width}});

    am_master_ms.wstrb <= f_resize(as_slave_ms.wstrb, {{x_pm_master.type.x_tstrb.x_width}});

    {{? x_pm_master.type.x_tlast}}
    {{=x_ps_slave.type}}
    am_master_ms.wlast <= {{=.x_tlast}}as_slave_ms.wlast{{|.x_tlast}}{{x_pm_master.type.x_tlast.x_cnull.qualified}}{{/.x_tlast}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tlast}}

    {{? x_pm_master.type.x_twuser}}
    {{=x_ps_slave.type}}
    am_master_ms.wuser <= {{=.x_twuser}}f_resize(as_slave_ms.wuser, {{x_pm_master.type.x_twuser.x_width}}){{|.x_twuser}}{{x_pm_master.type.x_twuser.x_cnull.qualified}}{{/.x_twuser}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_twuser}}

    am_master_ms.wvalid <= as_slave_ms.wvalid;

    am_master_ms.bready <= as_slave_ms.bready;
{{/x_pm_master.type.x_has_wr}}

    -- Read Channel
{{? x_pm_master.type.x_has_rd}}
    {{^x_ps_slave.type.x_has_rd}}
    report "Master has read channel, but slave doesn't!" severity error;
    {{/x_ps_slave.type.x_has_rd}}

    am_master_ms.araddr <= f_resize(as_slave_ms.araddr, {{x_pm_master.type.x_taddr.x_width}});

    {{? x_pm_master.type.x_tlen}}
    {{=x_ps_slave.type}}
    am_master_ms.arlen <= {{=.x_tlen}}f_resize(as_slave_ms.arlen, {{x_pm_master.type.x_tlen.x_width}}){{|.x_tlen}}{{x_pm_master.type.x_tlen.x_cnull.qualified}}{{/.x_tlen}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tlen}}

    {{? x_pm_master.type.x_tsize}}
    {{=x_ps_slave.type}}
    am_master_ms.arsize <= {{=.x_tsize}}f_resize(as_slave_ms.arsize, {{x_pm_master.type.x_tsize.x_width}}){{|.x_tsize}}{{x_pm_master.type.x_tsize.x_cnull.qualified}}{{/.x_tsize}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tsize}}

    {{? x_pm_master.type.x_tburst}}
    {{=x_ps_slave.type}}
    am_master_ms.arburst <= {{=.x_tburst}}f_resize(as_slave_ms.arburst, {{x_pm_master.type.x_tburst.x_width}}){{|.x_tburst}}{{x_pm_master.type.x_tburst.x_cnull.qualified}}{{/.x_tburst}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tburst}}

    {{? x_pm_master.type.x_tlock}}
    {{=x_ps_slave.type}}
    am_master_ms.arlock <= {{=.x_tlock}}f_resize(as_slave_ms.arlock, {{x_pm_master.type.x_tlock.x_width}}){{|.x_tlock}}{{x_pm_master.type.x_tlock.x_cnull.qualified}}{{/.x_tlock}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tlock}}

    {{? x_pm_master.type.x_tcache}}
    {{=x_ps_slave.type}}
    am_master_ms.arcache <= {{=.x_tcache}}f_resize(as_slave_ms.arcache, {{x_pm_master.type.x_tcache.x_width}}){{|.x_tcache}}{{x_pm_master.type.x_tcache.x_cnull.qualified}}{{/.x_tcache}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tcache}}

    {{? x_pm_master.type.x_tprot}}
    {{=x_ps_slave.type}}
    am_master_ms.arprot <= {{=.x_tprot}}f_resize(as_slave_ms.arprot, {{x_pm_master.type.x_tprot.x_width}}){{|.x_tprot}}{{x_pm_master.type.x_tprot.x_cnull.qualified}}{{/.x_tprot}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tprot}}

    {{? x_pm_master.type.x_tqos}}
    {{=x_ps_slave.type}}
    am_master_ms.arqos <= {{=.x_tqos}}f_resize(as_slave_ms.arqos, {{x_pm_master.type.x_tqos.x_width}}){{|.x_tqos}}{{x_pm_master.type.x_tqos.x_cnull.qualified}}{{/.x_tqos}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tqos}}

    {{? x_pm_master.type.x_tregion}}
    {{=x_ps_slave.type}}
    am_master_ms.arregion <= {{=.x_tregion}}f_resize(as_slave_ms.arregion, {{x_pm_master.type.x_tregion.x_width}}){{|.x_tregion}}{{x_pm_master.type.x_tregion.x_cnull.qualified}}{{/.x_tregion}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tregion}}

    {{? x_pm_master.type.x_tid}}
    {{=x_ps_slave.type}}
    am_master_ms.arid <= {{=.x_tid}}f_resize(as_slave_ms.arid, {{x_pm_master.type.x_tid.x_width}}){{|.x_tid}}{{x_pm_master.type.x_tid.x_cnull.qualified}}{{/.x_tid}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_tid}}

    {{? x_pm_master.type.x_taruser}}
    {{=x_ps_slave.type}}
    am_master_ms.aruser <= {{=.x_taruser}}f_resize(as_slave_ms.aruser, {{x_pm_master.type.x_taruser.x_width}}){{|.x_taruser}}{{x_pm_master.type.x_taruser.x_cnull.qualified}}{{/.x_taruser}};
    {{/x_ps_slave.type}}
    {{/x_pm_master.type.x_taruser}}

    am_master_ms.arvalid <= as_slave_ms.arvalid;

    am_master_ms.rready <= as_slave_ms.rready;
{{/x_pm_master.type.x_has_rd}}

-- Slave to Master
    -- Write Channel
{{?x_ps_slave.type.x_has_wr}}
    {{^x_pm_master.type.x_has_wr}}
    report "Slave has write channel, but master doesn't!" severity error;
    {{/x_pm_master.type.x_has_wr}}
    
    as_slave_sm.awready <= am_master_sm.awready;

    as_slave_sm.wready <= am_master_sm.wready;

    as_slave_sm.bresp <= f_resize(am_master_sm.bresp, {{x_ps_slave.type.x_tresp.x_width}});

    {{?x_ps_slave.type.x_tid}}
    {{=x_pm_master.type}}
    as_slave_sm.bid <= {{=.x_tid}}f_resize(am_master_sm.bid, {{x_ps_slave.type.x_tid.x_width}}){{|.x_tid}}{{x_ps_slave.type.x_tid.x_cnull.qualified}}{{/.x_tid}};
    {{/x_pm_master.type}}
    {{/x_ps_slave.type.x_tid}}

    {{?x_ps_slave.type.x_tbuser}}
    {{=x_pm_master.type}}
    as_slave_sm.buser <= {{=.x_tbuser}}f_resize(am_master_sm.buser, {{x_ps_slave.type.x_tbuser.x_width}}){{|.x_tbuser}}{{x_ps_slave.type.x_tbuser.x_cnull.qualified}}{{/.x_tbuser}};
    {{/x_pm_master.type}}
    {{/x_ps_slave.type.x_tbuser}}

    as_slave_sm.bvalid <= am_master_sm.bvalid;
{{/x_ps_slave.type.x_has_wr}}

    -- Read Channel
{{?x_ps_slave.type.x_has_rd}}
    {{^x_pm_master.type.x_has_rd}}
    report "Slave has read channel, but master doesn't!" severity error;
    {{/x_pm_master.type.x_has_rd}}

    as_slave_sm.arready <= am_master_sm.arready;

    as_slave_sm.rdata <= f_resize(am_master_sm.rdata, {{x_ps_slave.type.x_tdata.x_width}});

    as_slave_sm.rresp <= f_resize(am_master_sm.rresp, {{x_ps_slave.type.x_tresp.x_width}});

    {{?x_ps_slave.type.x_tlast}}
    {{=x_pm_master.type}}
    as_slave_sm.rlast <= {{=.x_tbuser}}am_master_sm.rlast{{|.x_tbuser}}{{x_ps_slave.type.x_tbuser.x_cnull.qualified}}{{/.x_tbuser}};
    {{/x_pm_master.type}}
    {{/x_ps_slave.type.x_tlast}}

    {{?x_ps_slave.type.x_tid}}
    {{=x_pm_master.type}}
    as_slave_sm.rid <= {{=.x_tid}}f_resize(am_master_sm.rid, {{x_ps_slave.type.x_tid.x_width}}){{|.x_tid}}{{x_ps_slave.type.x_tid.x_cnull.qualified}}{{/.x_tid}};
    {{/x_pm_master.type}}
    {{/x_ps_slave.type.x_tid}}

    {{?x_ps_slave.type.x_truser}}
    {{=x_pm_master.type}}
    as_slave_sm.ruser <= {{=.x_truser}}f_resize(am_master_sm.ruser, {{x_ps_slave.type.x_truser.x_width}}){{|.x_truser}}{{x_ps_slave.type.x_truser.x_cnull.qualified}}{{/.x_truser}};
    {{/x_pm_master.type}}
    {{/x_ps_slave.type.x_truser}}

    as_slave_sm.rvalid <= am_master_sm.rvalid;
{{/x_ps_slave.type.x_has_rd}}


end AxiConverter;