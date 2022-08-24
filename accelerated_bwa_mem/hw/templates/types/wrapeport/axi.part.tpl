{{?.type.x_has_wr}}
{{.x_wrapname}}_awaddr   : {{.mode_ms}} std_logic_vector({{.type.x_taddr.x_width}}-1 downto 0);
{{? .type.x_tlen}}
{{.x_wrapname}}_awlen    : {{.mode_ms}} std_logic_vector({{.type.x_tlen.x_width}}-1 downto 0);
{{/ .type.x_tlen}}
{{? .type.x_tsize}}
{{.x_wrapname}}_awsize   : {{.mode_ms}} std_logic_vector({{.type.x_tsize.x_width}}-1 downto 0);
{{/ .type.x_tsize}}
{{? .type.x_tburst}}
{{.x_wrapname}}_awburst  : {{.mode_ms}} std_logic_vector({{.type.x_tburst.x_width}}-1 downto 0);
{{/ .type.x_tburst}}
{{? .type.x_tlock}}
{{.x_wrapname}}_awlock   : {{.mode_ms}} std_logic_vector({{.type.x_tlock.x_width}}-1 downto 0);
{{/ .type.x_tlock}}
{{? .type.x_tcache}}
{{.x_wrapname}}_awcache  : {{.mode_ms}} std_logic_vector({{.type.x_tcache.x_width}}-1 downto 0);
{{/ .type.x_tcache}}
{{? .type.x_tprot}}
{{.x_wrapname}}_awprot   : {{.mode_ms}} std_logic_vector({{.type.x_tprot.x_width}}-1 downto 0);
{{/ .type.x_tprot}}
{{? .type.x_tqos}}
{{.x_wrapname}}_awqos    : {{.mode_ms}} std_logic_vector({{.type.x_tqos.x_width}}-1 downto 0);
{{/ .type.x_tqos}}
{{? .type.x_tregion}}
{{.x_wrapname}}_awregion : {{.mode_ms}} std_logic_vector({{.type.x_tregion.x_width}}-1 downto 0);
{{/ .type.x_tregion}}
{{? .type.x_tid}}
{{.x_wrapname}}_awid     : {{.mode_ms}} std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_tawuser}}
{{.x_wrapname}}_awuser   : {{.mode_ms}} std_logic_vector({{.type.x_tawuser.x_width}}-1 downto 0);
{{/ .type.x_tawuser}}
{{.x_wrapname}}_awvalid  : {{.mode_ms}} std_logic;
{{.x_wrapname}}_awready  : {{.mode_sm}} std_logic;
{{.x_wrapname}}_wdata    : {{.mode_ms}} std_logic_vector({{.type.x_tdata.x_width}}-1 downto 0);
{{.x_wrapname}}_wstrb    : {{.mode_ms}} std_logic_vector({{.type.x_tstrb.x_width}}-1 downto 0);
{{? .type.x_tlast}}
{{.x_wrapname}}_wlast    : {{.mode_ms}} std_logic;
{{/ .type.x_tlast}}
{{? .type.x_twuser}}
{{.x_wrapname}}_wuser    : {{.mode_ms}} std_logic_vector({{.type.x_twuser.x_width}}-1 downto 0);
{{/ .type.x_twuser}}
{{.x_wrapname}}_wvalid   : {{.mode_ms}} std_logic;
{{.x_wrapname}}_wready   : {{.mode_sm}} std_logic;
{{.x_wrapname}}_bresp    : {{.mode_sm}} std_logic_vector({{.type.x_tresp.x_width}}-1 downto 0);
{{? .type.x_tid}}
{{.x_wrapname}}_bid      : {{.mode_sm}} std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_tbuser}}
{{.x_wrapname}}_buser    : {{.mode_sm}} std_logic_vector({{.type.x_tbuser.x_width}}-1 downto 0);
{{/ .type.x_tbuser}}
{{.x_wrapname}}_bvalid   : {{.mode_sm}} std_logic;
{{.x_wrapname}}_bready   : {{.mode_ms}} std_logic{{!.type.x_has_rd}};{{/.type.x_has_rd}}
{{/.type.x_has_wr}}
{{?.type.x_has_rd}}
{{.x_wrapname}}_araddr   : {{.mode_ms}} std_logic_vector({{.type.x_taddr.x_width}}-1 downto 0);
{{? .type.x_tlen}}
{{.x_wrapname}}_arlen    : {{.mode_ms}} std_logic_vector({{.type.x_tlen.x_width}}-1 downto 0);
{{/ .type.x_tlen}}
{{? .type.x_tsize}}
{{.x_wrapname}}_arsize   : {{.mode_ms}} std_logic_vector({{.type.x_tsize.x_width}}-1 downto 0);
{{/ .type.x_tsize}}
{{? .type.x_tburst}}
{{.x_wrapname}}_arburst  : {{.mode_ms}} std_logic_vector({{.type.x_tburst.x_width}}-1 downto 0);
{{/ .type.x_tburst}}
{{? .type.x_tlock}}
{{.x_wrapname}}_arlock   : {{.mode_ms}} std_logic_vector({{.type.x_tlock.x_width}}-1 downto 0);
{{/ .type.x_tlock}}
{{? .type.x_tcache}}
{{.x_wrapname}}_arcache  : {{.mode_ms}} std_logic_vector({{.type.x_tcache.x_width}}-1 downto 0);
{{/ .type.x_tcache}}
{{? .type.x_tprot}}
{{.x_wrapname}}_arprot   : {{.mode_ms}} std_logic_vector({{.type.x_tprot.x_width}}-1 downto 0);
{{/ .type.x_tprot}}
{{? .type.x_tqos}}
{{.x_wrapname}}_arqos    : {{.mode_ms}} std_logic_vector({{.type.x_tqos.x_width}}-1 downto 0);
{{/ .type.x_tqos}}
{{? .type.x_tregion}}
{{.x_wrapname}}_arregion : {{.mode_ms}} std_logic_vector({{.type.x_tregion.x_width}}-1 downto 0);
{{/ .type.x_tregion}}
{{? .type.x_tid}}
{{.x_wrapname}}_arid     : {{.mode_ms}} std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_taruser}}
{{.x_wrapname}}_aruser   : {{.mode_ms}} std_logic_vector({{.type.x_taruser.x_width}}-1 downto 0);
{{/ .type.x_taruser}}
{{.x_wrapname}}_arvalid  : {{.mode_ms}} std_logic;
{{.x_wrapname}}_arready  : {{.mode_sm}} std_logic;
{{.x_wrapname}}_rdata    : {{.mode_sm}} std_logic_vector({{.type.x_tdata.x_width}}-1 downto 0);
{{.x_wrapname}}_rresp    : {{.mode_sm}} std_logic_vector({{.type.x_tresp.x_width}}-1 downto 0);
{{? .type.x_tlast}}
{{.x_wrapname}}_rlast    : {{.mode_sm}} std_logic;
{{/ .type.x_tlast}}
{{? .type.x_tid}}
{{.x_wrapname}}_rid      : {{.mode_sm}} std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_truser}}
{{.x_wrapname}}_ruser    : {{.mode_sm}} std_logic_vector({{.type.x_truser.x_width}}-1 downto 0);
{{/ .type.x_truser}}
{{.x_wrapname}}_rvalid   : {{.mode_sm}} std_logic;
{{.x_wrapname}}_rready   : {{.mode_ms}} std_logic
{{/.type.x_has_rd}}
