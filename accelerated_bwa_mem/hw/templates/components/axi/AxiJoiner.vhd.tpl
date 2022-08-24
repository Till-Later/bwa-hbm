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

architecture AxiJoiner of {{identifier}} is

  alias ai_sys is {{x_psys.identifier}};

{{^ x_ps_axi.type.x_is_axi}}
  report "Axi is not an Axi type!"; severity failure;
{{/ x_ps_axi.type.x_is_axi}}
  alias as_axi_ms is {{x_ps_axi.identifier_ms}};
  alias as_axi_sm is {{x_ps_axi.identifier_sm}};

{{^ x_pm_axiRd.type.x_is_axi}}
  report "AxiRd is not an Axi type!"; severity failure;
{{/ x_pm_axiRd.type.x_is_axi}}
  alias am_axiRd_ms is {{x_pm_axiRd.identifier_ms}};
  alias am_axiRd_sm is {{x_pm_axiRd.identifier_sm}};

{{^ x_pm_axiWr.type.x_is_axi}}
  report "AxiWr is not an Axi type!"; severity failure;
{{/ x_pm_axiWr.type.x_is_axi}}
  alias am_axiWr_ms is {{x_pm_axiWr.identifier_ms}};
  alias am_axiWr_sm is {{x_pm_axiWr.identifier_sm}};


begin
  am_axiWr_ms.awaddr   <= as_axi_ms.awaddr;
  am_axiWr_ms.awlen    <= as_axi_ms.awlen;
  am_axiWr_ms.awsize   <= as_axi_ms.awsize;
  am_axiWr_ms.awburst  <= as_axi_ms.awburst;
  am_axiWr_ms.awlock   <= as_axi_ms.awlock;
  am_axiWr_ms.awcache  <= as_axi_ms.awcache;
  am_axiWr_ms.awprot   <= as_axi_ms.awprot;
  am_axiWr_ms.awqos    <= as_axi_ms.awqos;
  am_axiWr_ms.awregion <= as_axi_ms.awregion;
  am_axiWr_ms.awid     <= as_axi_ms.awid;
  am_axiWr_ms.awuser   <= as_axi_ms.awuser;
  am_axiWr_ms.awvalid  <= as_axi_ms.awvalid;
  am_axiWr_ms.wdata    <= as_axi_ms.wdata;
  am_axiWr_ms.wstrb    <= as_axi_ms.wstrb;
  am_axiWr_ms.wlast    <= as_axi_ms.wlast;
  am_axiWr_ms.wuser    <= as_axi_ms.wuser;
  am_axiWr_ms.wvalid   <= as_axi_ms.wvalid;
  am_axiWr_ms.bready   <= as_axi_ms.bready;

  am_axiRd_ms.araddr   <= as_axi_ms.araddr;
  am_axiRd_ms.arlen    <= as_axi_ms.arlen;
  am_axiRd_ms.arsize   <= as_axi_ms.arsize;
  am_axiRd_ms.arburst  <= as_axi_ms.arburst;
  am_axiRd_ms.arlock   <= as_axi_ms.arlock;
  am_axiRd_ms.arcache  <= as_axi_ms.arcache;
  am_axiRd_ms.arprot   <= as_axi_ms.arprot;
  am_axiRd_ms.arqos    <= as_axi_ms.arqos;
  am_axiRd_ms.arregion <= as_axi_ms.arregion;
  am_axiRd_ms.arid     <= as_axi_ms.arid;
  am_axiRd_ms.aruser   <= as_axi_ms.aruser;
  am_axiRd_ms.arvalid  <= as_axi_ms.arvalid;
  am_axiRd_ms.rready   <= as_axi_ms.rready;

  as_axi_sm.arready  <= am_axiRd_sm.arready;
  as_axi_sm.rdata    <= am_axiRd_sm.rdata;
  as_axi_sm.rresp    <= am_axiRd_sm.rresp;
  as_axi_sm.rid      <= am_axiRd_sm.rid;
  as_axi_sm.ruser    <= am_axiRd_sm.ruser;
  as_axi_sm.rlast    <= am_axiRd_sm.rlast;
  as_axi_sm.rvalid   <= am_axiRd_sm.rvalid;

  as_axi_sm.awready  <= am_axiWr_sm.awready;
  as_axi_sm.wready   <= am_axiWr_sm.wready;
  as_axi_sm.bresp    <= am_axiWr_sm.bresp;
  as_axi_sm.bid      <= am_axiWr_sm.bid;
  as_axi_sm.buser    <= am_axiWr_sm.buser;
  as_axi_sm.bvalid   <= am_axiWr_sm.bvalid;
end AxiJoiner;
