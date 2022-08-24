{{?.type.x_has_wr}}
{{.x_wrapname}}_awaddr   => {{.x_wrapname}}_awaddr,
{{? .type.x_tlen}}
{{.x_wrapname}}_awlen    => {{.x_wrapname}}_awlen,
{{/ .type.x_tlen}}
{{? .type.x_tsize}}
{{.x_wrapname}}_awsize   => {{.x_wrapname}}_awsize,
{{/ .type.x_tsize}}
{{? .type.x_tburst}}
{{.x_wrapname}}_awburst  => {{.x_wrapname}}_awburst,
{{/ .type.x_tburst}}
{{? .type.x_tlock}}
{{.x_wrapname}}_awlock   => {{.x_wrapname}}_awlock,
{{/ .type.x_tlock}}
{{? .type.x_tcache}}
{{.x_wrapname}}_awcache  => {{.x_wrapname}}_awcache,
{{/ .type.x_tcache}}
{{? .type.x_tprot}}
{{.x_wrapname}}_awprot   => {{.x_wrapname}}_awprot,
{{/ .type.x_tprot}}
{{? .type.x_tqos}}
{{.x_wrapname}}_awqos    => {{.x_wrapname}}_awqos,
{{/ .type.x_tqos}}
{{? .type.x_tregion}}
{{.x_wrapname}}_awregion => {{.x_wrapname}}_awregion,
{{/ .type.x_tregion}}
{{? .type.x_tid}}
{{.x_wrapname}}_awid     => {{.x_wrapname}}_awid,
{{/ .type.x_tid}}
{{? .type.x_tawuser}}
{{.x_wrapname}}_awuser   => {{.x_wrapname}}_awuser,
{{/ .type.x_tawuser}}
{{.x_wrapname}}_awvalid  => {{.x_wrapname}}_awvalid,
{{.x_wrapname}}_awready  => {{.x_wrapname}}_awready,
{{.x_wrapname}}_wdata    => {{.x_wrapname}}_wdata,
{{.x_wrapname}}_wstrb    => {{.x_wrapname}}_wstrb,
{{? .type.x_tlast}}
{{.x_wrapname}}_wlast    => {{.x_wrapname}}_wlast,
{{/ .type.x_tlast}}
{{? .type.x_twuser}}
{{.x_wrapname}}_wuser    => {{.x_wrapname}}_wuser,
{{/ .type.x_twuser}}
{{.x_wrapname}}_wvalid   => {{.x_wrapname}}_wvalid,
{{.x_wrapname}}_wready   => {{.x_wrapname}}_wready,
{{.x_wrapname}}_bresp    => {{.x_wrapname}}_bresp,
{{? .type.x_tid}}
{{.x_wrapname}}_bid      => {{.x_wrapname}}_bid,
{{/ .type.x_tid}}
{{? .type.x_tbuser}}
{{.x_wrapname}}_buser    => {{.x_wrapname}}_buser,
{{/ .type.x_tbuser}}
{{.x_wrapname}}_bvalid   => {{.x_wrapname}}_bvalid,
{{.x_wrapname}}_bready   => {{.x_wrapname}}_bready{{?.type.x_has_rd}},{{/.type.x_has_rd}}
{{/.type.x_has_wr}}
{{?.type.x_has_rd}}
{{.x_wrapname}}_araddr   => {{.x_wrapname}}_araddr,
{{? .type.x_tlen}}
{{.x_wrapname}}_arlen    => {{.x_wrapname}}_arlen,
{{/ .type.x_tlen}}
{{? .type.x_tsize}}
{{.x_wrapname}}_arsize   => {{.x_wrapname}}_arsize,
{{/ .type.x_tsize}}
{{? .type.x_tburst}}
{{.x_wrapname}}_arburst  => {{.x_wrapname}}_arburst,
{{/ .type.x_tburst}}
{{? .type.x_tlock}}
{{.x_wrapname}}_arlock   => {{.x_wrapname}}_arlock,
{{/ .type.x_tlock}}
{{? .type.x_tcache}}
{{.x_wrapname}}_arcache  => {{.x_wrapname}}_arcache,
{{/ .type.x_tcache}}
{{? .type.x_tprot}}
{{.x_wrapname}}_arprot   => {{.x_wrapname}}_arprot,
{{/ .type.x_tprot}}
{{? .type.x_tqos}}
{{.x_wrapname}}_arqos    => {{.x_wrapname}}_arqos,
{{/ .type.x_tqos}}
{{? .type.x_tregion}}
{{.x_wrapname}}_arregion => {{.x_wrapname}}_arregion,
{{/ .type.x_tregion}}
{{? .type.x_tid}}
{{.x_wrapname}}_arid     => {{.x_wrapname}}_arid,
{{/ .type.x_tid}}
{{? .type.x_taruser}}
{{.x_wrapname}}_aruser   => {{.x_wrapname}}_aruser,
{{/ .type.x_taruser}}
{{.x_wrapname}}_arvalid  => {{.x_wrapname}}_arvalid,
{{.x_wrapname}}_arready  => {{.x_wrapname}}_arready,
{{.x_wrapname}}_rdata    => {{.x_wrapname}}_rdata,
{{.x_wrapname}}_rresp    => {{.x_wrapname}}_rresp,
{{? .type.x_tlast}}
{{.x_wrapname}}_rlast    => {{.x_wrapname}}_rlast,
{{/ .type.x_tlast}}
{{? .type.x_tid}}
{{.x_wrapname}}_rid      => {{.x_wrapname}}_rid,
{{/ .type.x_tid}}
{{? .type.x_truser}}
{{.x_wrapname}}_ruser    => {{.x_wrapname}}_ruser,
{{/ .type.x_truser}}
{{.x_wrapname}}_rvalid   => {{.x_wrapname}}_rvalid,
{{.x_wrapname}}_rready   => {{.x_wrapname}}_rready
{{/.type.x_has_rd}}
