{{?.is_ms_input}}
{{? .type.x_has_wr}}
{{.identifier_ms}}.awaddr   <= {{.type.x_taddr.qualified}}({{.x_wrapname}}_awaddr);
{{?  .type.x_tlen}}
{{.identifier_ms}}.awlen    <= {{.type.x_tlen.qualified}}({{.x_wrapname}}_awlen);
{{/  .type.x_tlen}}
{{?  .type.x_tsize}}
{{.identifier_ms}}.awsize   <= {{.type.x_tsize.qualified}}({{.x_wrapname}}_awsize);
{{/  .type.x_tsize}}
{{?  .type.x_tburst}}
{{.identifier_ms}}.awburst  <= {{.type.x_tburst.qualified}}({{.x_wrapname}}_awburst);
{{/  .type.x_tburst}}
{{?  .type.x_tlock}}
{{.identifier_ms}}.awlock   <= {{.type.x_tlock.qualified}}({{.x_wrapname}}_awlock);
{{/  .type.x_tlock}}
{{?  .type.x_tcache}}
{{.identifier_ms}}.awcache  <= {{.type.x_tcache.qualified}}({{.x_wrapname}}_awcache);
{{/  .type.x_tcache}}
{{?  .type.x_tprot}}
{{.identifier_ms}}.awprot   <= {{.type.x_tprot.qualified}}({{.x_wrapname}}_awprot);
{{/  .type.x_tprot}}
{{?  .type.x_tqos}}
{{.identifier_ms}}.awqos    <= {{.type.x_tqos.qualified}}({{.x_wrapname}}_awqos);
{{/  .type.x_tqos}}
{{?  .type.x_tregion}}
{{.identifier_ms}}.awregion <= {{.type.x_tregion.qualified}}({{.x_wrapname}}_awregion);
{{/  .type.x_tregion}}
{{?  .type.x_tid}}
{{.identifier_ms}}.awid     <= {{.type.x_tid.qualified}}({{.x_wrapname}}_awid);
{{/  .type.x_tid}}
{{?  .type.x_tawuser}}
{{.identifier_ms}}.awuser   <= {{.type.x_tawuser.qualified}}({{.x_wrapname}}_awuser);
{{/  .type.x_tawuser}}
{{.identifier_ms}}.awvalid  <= {{.x_wrapname}}_awvalid;
{{.identifier_ms}}.wdata    <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_wdata);
{{.identifier_ms}}.wstrb    <= {{.type.x_tstrb.qualified}}({{.x_wrapname}}_wstrb);
{{?  .type.x_tlast}}
{{.identifier_ms}}.wlast    <= {{.x_wrapname}}_wlast;
{{/  .type.x_tlast}}
{{?  .type.x_twuser}}
{{.identifier_ms}}.wuser    <= {{.type.x_twuser.qualified}}({{.x_wrapname}}_wuser);
{{/  .type.x_twuser}}
{{.identifier_ms}}.wvalid   <= {{.x_wrapname}}_wvalid;
{{.identifier_ms}}.bready   <= {{.x_wrapname}}_bready;
{{/ .type.x_has_wr}}
{{? .type.x_has_rd}}
{{.identifier_ms}}.araddr   <= {{.type.x_taddr.qualified}}({{.x_wrapname}}_araddr);
{{?  .type.x_tlen}}
{{.identifier_ms}}.arlen    <= {{.type.x_tlen.qualified}}({{.x_wrapname}}_arlen);
{{/  .type.x_tlen}}
{{?  .type.x_tsize}}
{{.identifier_ms}}.arsize   <= {{.type.x_tsize.qualified}}({{.x_wrapname}}_arsize);
{{/  .type.x_tsize}}
{{?  .type.x_tburst}}
{{.identifier_ms}}.arburst  <= {{.type.x_tburst.qualified}}({{.x_wrapname}}_arburst);
{{/  .type.x_tburst}}
{{?  .type.x_tlock}}
{{.identifier_ms}}.arlock   <= {{.type.x_tlock.qualified}}({{.x_wrapname}}_arlock);
{{/  .type.x_tlock}}
{{?  .type.x_tcache}}
{{.identifier_ms}}.arcache  <= {{.type.x_tcache.qualified}}({{.x_wrapname}}_arcache);
{{/  .type.x_tcache}}
{{?  .type.x_tprot}}
{{.identifier_ms}}.arprot   <= {{.type.x_tprot.qualified}}({{.x_wrapname}}_arprot);
{{/  .type.x_tprot}}
{{?  .type.x_tqos}}
{{.identifier_ms}}.arqos    <= {{.type.x_tqos.qualified}}({{.x_wrapname}}_arqos);
{{/  .type.x_tqos}}
{{?  .type.x_tregion}}
{{.identifier_ms}}.arregion <= {{.type.x_tregion.qualified}}({{.x_wrapname}}_arregion);
{{/  .type.x_tregion}}
{{?  .type.x_tid}}
{{.identifier_ms}}.arid     <= {{.type.x_tid.qualified}}({{.x_wrapname}}_arid);
{{/  .type.x_tid}}
{{?  .type.x_taruser}}
{{.identifier_ms}}.aruser   <= {{.type.x_taruser.qualified}}({{.x_wrapname}}_aruser);
{{/  .type.x_taruser}}
{{.identifier_ms}}.arvalid  <= {{.x_wrapname}}_arvalid;
{{.identifier_ms}}.rready   <= {{.x_wrapname}}_rready;
{{/ .type.x_has_rd}}
{{|.is_ms_input}}
{{? .type.x_has_wr}}
{{.x_wrapname}}_awaddr   <= std_logic_vector({{.identifier_ms}}.awaddr);
{{?  .type.x_tlen}}
{{.x_wrapname}}_awlen    <= std_logic_vector({{.identifier_ms}}.awlen);
{{/  .type.x_tlen}}
{{?  .type.x_tsize}}
{{.x_wrapname}}_awsize   <= std_logic_vector({{.identifier_ms}}.awsize);
{{/  .type.x_tsize}}
{{?  .type.x_tburst}}
{{.x_wrapname}}_awburst  <= std_logic_vector({{.identifier_ms}}.awburst);
{{/  .type.x_tburst}}
{{?  .type.x_tlock}}
{{.x_wrapname}}_awlock   <= std_logic_vector({{.identifier_ms}}.awlock);
{{/  .type.x_tlock}}
{{?  .type.x_tcache}}
{{.x_wrapname}}_awcache  <= std_logic_vector({{.identifier_ms}}.awcache);
{{/  .type.x_tcache}}
{{?  .type.x_tprot}}
{{.x_wrapname}}_awprot   <= std_logic_vector({{.identifier_ms}}.awprot);
{{/  .type.x_tprot}}
{{?  .type.x_tqos}}
{{.x_wrapname}}_awqos    <= std_logic_vector({{.identifier_ms}}.awqos);
{{/  .type.x_tqos}}
{{?  .type.x_tregion}}
{{.x_wrapname}}_awregion <= std_logic_vector({{.identifier_ms}}.awregion);
{{/  .type.x_tregion}}
{{?  .type.x_tid}}
{{.x_wrapname}}_awid     <= std_logic_vector({{.identifier_ms}}.awid);
{{/  .type.x_tid}}
{{?  .type.x_tawuser}}
{{.x_wrapname}}_awuser   <= std_logic_vector({{.identifier_ms}}.awuser);
{{/  .type.x_tawuser}}
{{.x_wrapname}}_awvalid  <= {{.identifier_ms}}.awvalid;
{{.x_wrapname}}_wdata    <= std_logic_vector({{.identifier_ms}}.wdata);
{{.x_wrapname}}_wstrb    <= std_logic_vector({{.identifier_ms}}.wstrb);
{{?  .type.x_tlast}}
{{.x_wrapname}}_wlast    <= {{.identifier_ms}}.wlast;
{{/  .type.x_tlast}}
{{?  .type.x_twuser}}
{{.x_wrapname}}_wuser    <= std_logic_vector({{.identifier_ms}}.wuser);
{{/  .type.x_twuser}}
{{.x_wrapname}}_wvalid   <= {{.identifier_ms}}.wvalid;
{{.x_wrapname}}_bready   <= {{.identifier_ms}}.bready;
{{/ .type.x_has_wr}}
{{? .type.x_has_rd}}
{{.x_wrapname}}_araddr   <= std_logic_vector({{.identifier_ms}}.araddr);
{{?  .type.x_tlen}}
{{.x_wrapname}}_arlen    <= std_logic_vector({{.identifier_ms}}.arlen);
{{/  .type.x_tlen}}
{{?  .type.x_tsize}}
{{.x_wrapname}}_arsize   <= std_logic_vector({{.identifier_ms}}.arsize);
{{/  .type.x_tsize}}
{{?  .type.x_tburst}}
{{.x_wrapname}}_arburst  <= std_logic_vector({{.identifier_ms}}.arburst);
{{/  .type.x_tburst}}
{{?  .type.x_tlock}}
{{.x_wrapname}}_arlock   <= std_logic_vector({{.identifier_ms}}.arlock);
{{/  .type.x_tlock}}
{{?  .type.x_tcache}}
{{.x_wrapname}}_arcache  <= std_logic_vector({{.identifier_ms}}.arcache);
{{/  .type.x_tcache}}
{{?  .type.x_tprot}}
{{.x_wrapname}}_arprot   <= std_logic_vector({{.identifier_ms}}.arprot);
{{/  .type.x_tprot}}
{{?  .type.x_tqos}}
{{.x_wrapname}}_arqos    <= std_logic_vector({{.identifier_ms}}.arqos);
{{/  .type.x_tqos}}
{{?  .type.x_tregion}}
{{.x_wrapname}}_arregion <= std_logic_vector({{.identifier_ms}}.arregion);
{{/  .type.x_tregion}}
{{?  .type.x_tid}}
{{.x_wrapname}}_arid     <= std_logic_vector({{.identifier_ms}}.arid);
{{/  .type.x_tid}}
{{?  .type.x_taruser}}
{{.x_wrapname}}_aruser   <= std_logic_vector({{.identifier_ms}}.aruser);
{{/  .type.x_taruser}}
{{.x_wrapname}}_arvalid  <= {{.identifier_ms}}.arvalid;
{{.x_wrapname}}_rready   <= {{.identifier_ms}}.rready;
{{/ .type.x_has_rd}}
{{/.is_ms_input}}
{{?.is_sm_input}}
{{? .type.x_has_wr}}
{{.identifier_sm}}.awready <= {{.x_wrapname}}_awready;
{{.identifier_sm}}.wready  <= {{.x_wrapname}}_wready;
{{.identifier_sm}}.bresp   <= {{.type.x_tresp.qualified}}({{.x_wrapname}}_bresp);
{{?  .type.x_tid}}
{{.identifier_sm}}.bid     <= {{.type.x_tid.qualified}}({{.x_wrapname}}_bid);
{{/  .type.x_tid}}
{{?  .type.x_tbuser}}
{{.identifier_sm}}.buser   <= {{.type.x_tbuser.qualified}}({{.x_wrapname}}_buser);
{{/  .type.x_tbuser}}
{{.identifier_sm}}.bvalid  <= {{.x_wrapname}}_bvalid;
{{/ .type.x_has_wr}}
{{? .type.x_has_rd}}
{{.identifier_sm}}.arready <= {{.x_wrapname}}_arready;
{{.identifier_sm}}.rdata   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_rdata);
{{.identifier_sm}}.rresp   <= {{.type.x_tresp.qualified}}({{.x_wrapname}}_rresp);
{{?  .type.x_tlast}}
{{.identifier_sm}}.rlast   <= {{.x_wrapname}}_rlast;
{{/  .type.x_tlast}}
{{?  .type.x_tid}}
{{.identifier_sm}}.rid     <= {{.type.x_tid.qualified}}({{.x_wrapname}}_rid);
{{/  .type.x_tid}}
{{?  .type.x_truser}}
{{.identifier_sm}}.ruser   <= {{.type.x_truser.qualified}}({{.x_wrapname}}_ruser);
{{/  .type.x_truser}}
{{.identifier_sm}}.rvalid  <= {{.x_wrapname}}_rvalid;
{{/ .type.x_has_rd}}
{{|.is_sm_input}}
{{? .type.x_has_wr}}
{{.x_wrapname}}_awready  <= {{.identifier_sm}}.awready;
{{.x_wrapname}}_wready   <= {{.identifier_sm}}.wready;
{{.x_wrapname}}_bresp    <= std_logic_vector({{.identifier_sm}}.bresp);
{{?  .type.x_tid}}
{{.x_wrapname}}_bid      <= std_logic_vector({{.identifier_sm}}.bid);
{{/  .type.x_tid}}
{{?  .type.x_tbuser}}
{{.x_wrapname}}_buser    <= std_logic_vector({{.identifier_sm}}.buser);
{{/  .type.x_tbuser}}
{{.x_wrapname}}_bvalid   <= {{.identifier_sm}}.bvalid;
{{/ .type.x_has_wr}}
{{? .type.x_has_rd}}
{{.x_wrapname}}_arready  <= {{.identifier_sm}}.arready;
{{.x_wrapname}}_rdata    <= std_logic_vector({{.identifier_sm}}.rdata);
{{.x_wrapname}}_rresp    <= std_logic_vector({{.identifier_sm}}.rresp);
{{?  .type.x_tlast}}
{{.x_wrapname}}_rlast    <= {{.identifier_sm}}.rlast;
{{/  .type.x_tlast}}
{{?  .type.x_tid}}
{{.x_wrapname}}_rid      <= std_logic_vector({{.identifier_sm}}.rid);
{{/  .type.x_tid}}
{{?  .type.x_truser}}
{{.x_wrapname}}_ruser    <= std_logic_vector({{.identifier_sm}}.ruser);
{{/  .type.x_truser}}
{{.x_wrapname}}_rvalid   <= {{.identifier_sm}}.rvalid;
{{/ .type.x_has_rd}}
{{/.is_sm_input}}
