library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util;

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

architecture AxiPipelineStage of {{identifier}} is
    alias ai_sys is {{x_psys.identifier}};

    alias as_slave_ms is {{x_ps_slave.identifier_ms}};
    alias as_slave_sm is {{x_ps_slave.identifier_sm}};

    alias am_master_ms is {{x_pm_master.identifier_ms}};
    alias am_master_sm is {{x_pm_master.identifier_sm}};

    subtype t_combinedAW is unsigned((
        {{x_pm_master.type.x_taddr.x_width}}
        {{? x_pm_master.type.x_tlen}} + {{x_pm_master.type.x_tlen.x_width}}{{/x_pm_master.type.x_tlen}}
        {{? x_pm_master.type.x_tsize}}  + {{x_pm_master.type.x_tsize.x_width}}{{/x_pm_master.type.x_tsize}}
        {{? x_pm_master.type.x_tburst}} + {{x_pm_master.type.x_tburst.x_width}}{{/x_pm_master.type.x_tburst}}
        {{? x_pm_master.type.x_tlock}}  + {{x_pm_master.type.x_tlock.x_width}}{{/x_pm_master.type.x_tlock}}
        {{? x_pm_master.type.x_tcache}} + {{x_pm_master.type.x_tcache.x_width}}{{/x_pm_master.type.x_tcache}}
        {{? x_pm_master.type.x_tprot}}  + {{x_pm_master.type.x_tprot.x_width}}{{/x_pm_master.type.x_tprot}}
        {{? x_pm_master.type.x_tqos}} + {{x_pm_master.type.x_tqos.x_width}}{{/x_pm_master.type.x_tqos}}
        {{? x_pm_master.type.x_tregion}}  + {{x_pm_master.type.x_tregion.x_width}}{{/x_pm_master.type.x_tregion}}
        {{? x_pm_master.type.x_tid}}  + {{x_pm_master.type.x_tid.x_width}}{{/x_pm_master.type.x_tid}}
        {{? x_pm_master.type.x_tawuser}}  + {{x_pm_master.type.x_tawuser.x_width}}{{/x_pm_master.type.x_tawuser}}
         - 1) downto 0
    );
    signal s_combinedAWIn : t_combinedAW;
    signal s_combinedAWOut : t_combinedAW;

    subtype t_combinedAR is unsigned((
        {{x_pm_master.type.x_taddr.x_width}}
        {{? x_pm_master.type.x_tlen}} + {{x_pm_master.type.x_tlen.x_width}}{{/x_pm_master.type.x_tlen}}
        {{? x_pm_master.type.x_tsize}}  + {{x_pm_master.type.x_tsize.x_width}}{{/x_pm_master.type.x_tsize}}
        {{? x_pm_master.type.x_tburst}} + {{x_pm_master.type.x_tburst.x_width}}{{/x_pm_master.type.x_tburst}}
        {{? x_pm_master.type.x_tlock}}  + {{x_pm_master.type.x_tlock.x_width}}{{/x_pm_master.type.x_tlock}}
        {{? x_pm_master.type.x_tcache}} + {{x_pm_master.type.x_tcache.x_width}}{{/x_pm_master.type.x_tcache}}
        {{? x_pm_master.type.x_tprot}}  + {{x_pm_master.type.x_tprot.x_width}}{{/x_pm_master.type.x_tprot}}
        {{? x_pm_master.type.x_tqos}} + {{x_pm_master.type.x_tqos.x_width}}{{/x_pm_master.type.x_tqos}}
        {{? x_pm_master.type.x_tregion}}  + {{x_pm_master.type.x_tregion.x_width}}{{/x_pm_master.type.x_tregion}}
        {{? x_pm_master.type.x_tid}}  + {{x_pm_master.type.x_tid.x_width}}{{/x_pm_master.type.x_tid}}
        {{? x_pm_master.type.x_taruser}}  + {{x_pm_master.type.x_taruser.x_width}}{{/x_pm_master.type.x_taruser}}
        - 1) downto 0
    );
    signal s_combinedARIn : t_combinedAR;
    signal s_combinedAROut : t_combinedAR;

    subtype t_combinedW is unsigned((
        {{x_pm_master.type.x_tdata.x_width}}
        + {{x_pm_master.type.x_tstrb.x_width}}
        {{? x_pm_master.type.x_tlast}} + 1{{/x_pm_master.type.x_tlast}}
        {{? x_pm_master.type.x_twuser}} + {{x_pm_master.type.x_twuser.x_width}}{{/x_pm_master.type.x_twuser}}
         - 1) downto 0
    );
    signal s_combinedWIn : t_combinedW;
    signal s_combinedWOut : t_combinedW;

    subtype t_combinedR is unsigned((
        {{x_pm_master.type.x_tdata.x_width}}
        + {{x_pm_master.type.x_tresp.x_width}}
        {{?x_pm_master.type.x_tid}} + {{x_pm_master.type.x_tid.x_width}}{{/x_pm_master.type.x_tid}}
        {{?x_pm_master.type.x_truser}} +{{x_pm_master.type.x_truser.x_width}}{{/x_pm_master.type.x_truser}}
        {{?x_pm_master.type.x_tlast}} + 1{{/x_pm_master.type.x_tlast}}
        - 1) downto 0
    );
    signal s_combinedRIn : t_combinedR;
    signal s_combinedROut : t_combinedR;

    subtype t_combinedB is unsigned((
        {{x_pm_master.type.x_tresp.x_width}}
        {{?x_pm_master.type.x_tid}} + {{x_pm_master.type.x_tid.x_width}}{{/x_pm_master.type.x_tid}}
        {{?x_pm_master.type.x_tbuser}} + {{x_pm_master.type.x_tbuser.x_width}}{{/x_pm_master.type.x_tbuser}} 
        - 1) downto 0
    );
    signal s_combinedBIn : t_combinedB;
    signal s_combinedBOut : t_combinedB;
begin
    s_combinedAWIn <= as_slave_ms.awaddr
      {{? x_pm_master.type.x_tlen}}     & as_slave_ms.awlen   {{/x_pm_master.type.x_tlen}}       
      {{? x_pm_master.type.x_tsize}}    & as_slave_ms.awsize  {{/x_pm_master.type.x_tsize}}
      {{? x_pm_master.type.x_tburst}}   & as_slave_ms.awburst {{/x_pm_master.type.x_tburst}}
      {{? x_pm_master.type.x_tlock}}    & as_slave_ms.awlock  {{/x_pm_master.type.x_tlock}}
      {{? x_pm_master.type.x_tcache}}   & as_slave_ms.awcache {{/x_pm_master.type.x_tcache}}
      {{? x_pm_master.type.x_tprot}}    & as_slave_ms.awprot  {{/x_pm_master.type.x_tprot}}
      {{? x_pm_master.type.x_tqos}}     & as_slave_ms.awqos   {{/x_pm_master.type.x_tqos}}
      {{? x_pm_master.type.x_tregion}}  & as_slave_ms.awregion{{/x_pm_master.type.x_tregion}}
      {{? x_pm_master.type.x_tid}}      & as_slave_ms.awid    {{/x_pm_master.type.x_tid}}
      {{? x_pm_master.type.x_tawuser}}  & as_slave_ms.awuser  {{/x_pm_master.type.x_tawuser}};
      
    i_pipelineStageAW : entity work.PipelineStage
    generic map(g_DataWidth => t_combinedAW'length)
    port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_inData     => s_combinedAWIn,
      pi_inValid    => as_slave_ms.awvalid,
      po_inReady    => as_slave_sm.awready,
      po_outData    => s_combinedAWOut,
      po_outValid   => am_master_ms.awvalid,
      pi_outReady   => am_master_sm.awready);
    (am_master_ms.awaddr
    {{? x_pm_master.type.x_tlen}}     , am_master_ms.awlen   {{/x_pm_master.type.x_tlen}}       
    {{? x_pm_master.type.x_tsize}}    , am_master_ms.awsize  {{/x_pm_master.type.x_tsize}}
    {{? x_pm_master.type.x_tburst}}   , am_master_ms.awburst {{/x_pm_master.type.x_tburst}}
    {{? x_pm_master.type.x_tlock}}    , am_master_ms.awlock  {{/x_pm_master.type.x_tlock}}
    {{? x_pm_master.type.x_tcache}}   , am_master_ms.awcache {{/x_pm_master.type.x_tcache}}
    {{? x_pm_master.type.x_tprot}}    , am_master_ms.awprot  {{/x_pm_master.type.x_tprot}}
    {{? x_pm_master.type.x_tqos}}     , am_master_ms.awqos   {{/x_pm_master.type.x_tqos}}
    {{? x_pm_master.type.x_tregion}}  , am_master_ms.awregion{{/x_pm_master.type.x_tregion}}
    {{? x_pm_master.type.x_tid}}      , am_master_ms.awid    {{/x_pm_master.type.x_tid}}
    {{? x_pm_master.type.x_tawuser}}  , am_master_ms.awuser  {{/x_pm_master.type.x_tawuser}}) <= s_combinedAWOut;

    s_combinedARIn <= as_slave_ms.araddr 
      {{? x_pm_master.type.x_tlen}}    & as_slave_ms.arlen    {{/x_pm_master.type.x_tlen}}
      {{? x_pm_master.type.x_tsize}}   & as_slave_ms.arsize   {{/x_pm_master.type.x_tsize}}
      {{? x_pm_master.type.x_tburst}}  & as_slave_ms.arburst  {{/x_pm_master.type.x_tburst}}
      {{? x_pm_master.type.x_tlock}}   & as_slave_ms.arlock   {{/x_pm_master.type.x_tlock}}
      {{? x_pm_master.type.x_tcache}}  & as_slave_ms.arcache  {{/x_pm_master.type.x_tcache}}
      {{? x_pm_master.type.x_tprot}}   & as_slave_ms.arprot   {{/x_pm_master.type.x_tprot}}
      {{? x_pm_master.type.x_tqos}}    & as_slave_ms.arqos    {{/x_pm_master.type.x_tqos}}
      {{? x_pm_master.type.x_tregion}} & as_slave_ms.arregion {{/x_pm_master.type.x_tregion}}
      {{? x_pm_master.type.x_tid}}     & as_slave_ms.arid     {{/x_pm_master.type.x_tid}}
      {{? x_pm_master.type.x_taruser}} & as_slave_ms.aruser   {{/x_pm_master.type.x_taruser}};

    i_pipelineStageAR : entity work.PipelineStage
    generic map(g_DataWidth => t_combinedAR'length)
    port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_inData     => s_combinedARIn,
      pi_inValid    => as_slave_ms.arvalid,
      po_inReady    => as_slave_sm.arready,
      po_outData    => s_combinedAROut,
      po_outValid   => am_master_ms.arvalid,
      pi_outReady   => am_master_sm.arready);
    (am_master_ms.araddr 
      {{? x_pm_master.type.x_tlen}}    , am_master_ms.arlen     {{/x_pm_master.type.x_tlen}}
      {{? x_pm_master.type.x_tsize}}   , am_master_ms.arsize    {{/x_pm_master.type.x_tsize}}
      {{? x_pm_master.type.x_tburst}}  , am_master_ms.arburst   {{/x_pm_master.type.x_tburst}}
      {{? x_pm_master.type.x_tlock}}   , am_master_ms.arlock    {{/x_pm_master.type.x_tlock}}
      {{? x_pm_master.type.x_tcache}}  , am_master_ms.arcache   {{/x_pm_master.type.x_tcache}}
      {{? x_pm_master.type.x_tprot}}   , am_master_ms.arprot    {{/x_pm_master.type.x_tprot}}
      {{? x_pm_master.type.x_tqos}}    , am_master_ms.arqos     {{/x_pm_master.type.x_tqos}}
      {{? x_pm_master.type.x_tregion}} , am_master_ms.arregion  {{/x_pm_master.type.x_tregion}}
      {{? x_pm_master.type.x_tid}}     , am_master_ms.arid      {{/x_pm_master.type.x_tid}}
      {{? x_pm_master.type.x_taruser}} , am_master_ms.aruser    {{/x_pm_master.type.x_taruser}}) <= s_combinedAROut;

    s_combinedWIn <=  as_slave_ms.wdata 
      & as_slave_ms.wstrb 
      {{? x_pm_master.type.x_tlast}}& as_slave_ms.wlast {{/x_pm_master.type.x_tlast}}
      {{? x_pm_master.type.x_twuser}}& as_slave_ms.wuser {{/x_pm_master.type.x_twuser}};
    i_pipelineStageW : entity work.PipelineStage
    generic map(g_DataWidth => t_combinedW'length)
    port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_inData     => s_combinedWIn,
      pi_inValid    => as_slave_ms.wvalid,
      po_inReady    => as_slave_sm.wready,
      po_outData    => s_combinedWOut,
      po_outValid   => am_master_ms.wvalid,
      pi_outReady   => am_master_sm.wready);
    (am_master_ms.wdata
     , am_master_ms.wstrb
     {{? x_pm_master.type.x_tlast}} , am_master_ms.wlast{{/x_pm_master.type.x_tlast}}
     {{? x_pm_master.type.x_twuser}}, am_master_ms.wuser{{/x_pm_master.type.x_twuser}}) <= s_combinedWOut;

    s_combinedRIn <= am_master_sm.rdata 
      & am_master_sm.rresp 
      {{?x_pm_master.type.x_tid}}     & am_master_sm.rid    {{/x_pm_master.type.x_tid}}
      {{?x_pm_master.type.x_truser}}  & am_master_sm.ruser  {{/x_pm_master.type.x_truser}}
      {{?x_pm_master.type.x_tlast}}   & am_master_sm.rlast  {{/x_pm_master.type.x_tlast}};
    i_pipelineStageR : entity work.PipelineStage
    generic map(g_DataWidth => t_combinedR'length)
    port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_inData     => s_combinedRIn,
      pi_inValid    => am_master_sm.rvalid,
      po_inReady    => am_master_ms.rready,
      po_outData    => s_combinedROut,
      po_outValid   => as_slave_sm.rvalid,
      pi_outReady   => as_slave_ms.rready);
    (as_slave_sm.rdata
     , as_slave_sm.rresp
     {{?x_pm_master.type.x_tid}}   , as_slave_sm.rid {{/x_pm_master.type.x_tid}}
     {{?x_pm_master.type.x_truser}}, as_slave_sm.ruser{{/x_pm_master.type.x_truser}}
     {{?x_pm_master.type.x_tlast}} , as_slave_sm.rlast{{/x_pm_master.type.x_tlast}}) <= s_combinedROut;

    s_combinedBIn <= am_master_sm.bresp 
    {{?x_pm_master.type.x_tid}}    & am_master_sm.bid {{/x_pm_master.type.x_tid}} 
    {{?x_pm_master.type.x_tbuser}} & am_master_sm.buser {{/ x_pm_master.type.x_tbuser}};
    i_pipelineStageB : entity work.PipelineStage
    generic map(g_DataWidth => t_combinedB'length)
    port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_inData     => s_combinedBIn,
      pi_inValid    => am_master_sm.bvalid,
      po_inReady    => am_master_ms.bready,
      po_outData    => s_combinedBOut,
      po_outValid   => as_slave_sm.bvalid,
      pi_outReady   => as_slave_ms.bready);
    (as_slave_sm.bresp
    {{?x_pm_master.type.x_tid}}    , as_slave_sm.bid{{/x_pm_master.type.x_tid}} 
    {{?x_pm_master.type.x_tbuser}} , as_slave_sm.buser{{/ x_pm_master.type.x_tbuser}}) <= s_combinedBOut;
end AxiPipelineStage;
