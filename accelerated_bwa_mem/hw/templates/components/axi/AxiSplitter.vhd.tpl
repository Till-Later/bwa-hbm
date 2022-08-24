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

architecture AxiSplitter of {{identifier}} is

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
  --am_axi_ms <= f_nativeAxiJoinRdWr_ms(as_axiRd_ms, as_axiWr_ms);
  am_axi_ms.awaddr   <= as_axiWr_ms.awaddr;
  am_axi_ms.awlen    <= as_axiWr_ms.awlen;
  am_axi_ms.awsize   <= as_axiWr_ms.awsize;
  am_axi_ms.awburst  <= as_axiWr_ms.awburst;
  am_axi_ms.awlock   <= as_axiWr_ms.awlock;
  am_axi_ms.awcache  <= as_axiWr_ms.awcache;
  am_axi_ms.awprot   <= as_axiWr_ms.awprot;
  am_axi_ms.awqos    <= as_axiWr_ms.awqos;
  am_axi_ms.awregion <= as_axiWr_ms.awregion;
  am_axi_ms.awid     <= as_axiWr_ms.awid;
  am_axi_ms.awuser   <= as_axiWr_ms.awuser;
  am_axi_ms.awvalid  <= as_axiWr_ms.awvalid;
  am_axi_ms.wdata    <= as_axiWr_ms.wdata;
  am_axi_ms.wstrb    <= as_axiWr_ms.wstrb;
  am_axi_ms.wlast    <= as_axiWr_ms.wlast;
  am_axi_ms.wuser     <= as_axiWr_ms.wuser;
  am_axi_ms.wvalid   <= as_axiWr_ms.wvalid;
  am_axi_ms.bready   <= as_axiWr_ms.bready;
  am_axi_ms.araddr   <= as_axiRd_ms.araddr;
  am_axi_ms.arlen    <= as_axiRd_ms.arlen;
  am_axi_ms.arsize   <= as_axiRd_ms.arsize;
  am_axi_ms.arburst  <= as_axiRd_ms.arburst;
  am_axi_ms.arlock   <= as_axiRd_ms.arlock;
  am_axi_ms.arcache  <= as_axiRd_ms.arcache;
  am_axi_ms.arprot   <= as_axiRd_ms.arprot;
  am_axi_ms.arqos    <= as_axiRd_ms.arqos;
  am_axi_ms.arregion <= as_axiRd_ms.arregion;
  am_axi_ms.arid     <= as_axiRd_ms.arid;
  am_axi_ms.aruser   <= as_axiRd_ms.aruser;
  am_axi_ms.arvalid  <= as_axiRd_ms.arvalid;
  am_axi_ms.rready   <= as_axiRd_ms.rready;

  -- as_axiRd_sm <= f_nativeAxiSplitRd_sm(am_axi_sm);
  as_axiRd_sm.arready  <= am_axi_sm.arready;
  as_axiRd_sm.rdata    <= am_axi_sm.rdata;
  as_axiRd_sm.rresp    <= am_axi_sm.rresp;
  as_axiRd_sm.rid      <= am_axi_sm.rid;
  as_axiRd_sm.ruser    <= am_axi_sm.ruser;
  as_axiRd_sm.rlast    <= am_axi_sm.rlast;
  as_axiRd_sm.rvalid   <= am_axi_sm.rvalid;

  -- as_axiWr_sm <= f_nativeAxiSplitWr_sm(am_axi_sm);
  as_axiWr_sm.awready  <= am_axi_sm.awready;
  as_axiWr_sm.wready   <= am_axi_sm.wready;
  as_axiWr_sm.bresp    <= am_axi_sm.bresp;
  as_axiWr_sm.bid      <= am_axi_sm.bid;
  as_axiWr_sm.buser    <= am_axi_sm.buser;
  as_axiWr_sm.bvalid   <= am_axi_sm.bvalid;

end AxiSplitter;
