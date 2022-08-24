{{?.type.x_has_wr}}
signal {{.x_wrapname}}_awaddr   : std_logic_vector({{.type.x_taddr.x_width}}-1 downto 0);
{{? .type.x_tlen}}
signal {{.x_wrapname}}_awlen    : std_logic_vector({{.type.x_tlen.x_width}}-1 downto 0);
{{/ .type.x_tlen}}
{{? .type.x_tsize}}
signal {{.x_wrapname}}_awsize   : std_logic_vector({{.type.x_tsize.x_width}}-1 downto 0);
{{/ .type.x_tsize}}
{{? .type.x_tburst}}
signal {{.x_wrapname}}_awburst  : std_logic_vector({{.type.x_tburst.x_width}}-1 downto 0);
{{/ .type.x_tburst}}
{{? .type.x_tlock}}
signal {{.x_wrapname}}_awlock   : std_logic_vector({{.type.x_tlock.x_width}}-1 downto 0);
{{/ .type.x_tlock}}
{{? .type.x_tcache}}
signal {{.x_wrapname}}_awcache  : std_logic_vector({{.type.x_tcache.x_width}}-1 downto 0);
{{/ .type.x_tcache}}
{{? .type.x_tprot}}
signal {{.x_wrapname}}_awprot   : std_logic_vector({{.type.x_tprot.x_width}}-1 downto 0);
{{/ .type.x_tprot}}
{{? .type.x_tqos}}
signal {{.x_wrapname}}_awqos    : std_logic_vector({{.type.x_tqos.x_width}}-1 downto 0);
{{/ .type.x_tqos}}
{{? .type.x_tregion}}
signal {{.x_wrapname}}_awregion : std_logic_vector({{.type.x_tregion.x_width}}-1 downto 0);
{{/ .type.x_tregion}}
{{? .type.x_tid}}
signal {{.x_wrapname}}_awid     : std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_tawuser}}
signal {{.x_wrapname}}_awuser   : std_logic_vector({{.type.x_tawuser.x_width}}-1 downto 0);
{{/ .type.x_tawuser}}
signal {{.x_wrapname}}_awvalid  : std_logic;
signal {{.x_wrapname}}_awready  : std_logic;
signal {{.x_wrapname}}_wdata    : std_logic_vector({{.x_tdata.x_width}}-1 downto 0);
signal {{.x_wrapname}}_wstrb    : std_logic_vector({{.x_tstrb.x_width}}-1 downto 0);
{{? .type.x_tlast}}
signal {{.x_wrapname}}_wlast    : std_logic;
{{/ .type.x_tlast}}
{{? .type.x_twuser}}
signal {{.x_wrapname}}_wuser    : std_logic_vector({{.type.x_twuser.x_width}}-1 downto 0);
{{/ .type.x_twuser}}
signal {{.x_wrapname}}_wvalid   : std_logic;
signal {{.x_wrapname}}_wready   : std_logic;
signal {{.x_wrapname}}_bresp    : std_logic_vector({{.x_tresp.x_width}}-1 downto 0);
{{? .type.x_tid}}
signal {{.x_wrapname}}_bid      : std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_tbuser}}
signal {{.x_wrapname}}_buser    : std_logic_vector({{.type.x_tbuser.x_width}}-1 downto 0);
{{/ .type.x_tbuser}}
signal {{.x_wrapname}}_bvalid   : std_logic;
signal {{.x_wrapname}}_bready   : std_logic;
{{/.type.x_has_wr}}
{{?.type.x_has_rd}}
signal {{.x_wrapname}}_araddr   : std_logic_vector({{.type.x_taddr.x_width}}-1 downto 0);
{{? .type.x_tlen}}
signal {{.x_wrapname}}_arlen    : std_logic_vector({{.type.x_tlen.x_width}}-1 downto 0);
{{/ .type.x_tlen}}
{{? .type.x_tsize}}
signal {{.x_wrapname}}_arsize   : std_logic_vector({{.type.x_tsize.x_width}}-1 downto 0);
{{/ .type.x_tsize}}
{{? .type.x_tburst}}
signal {{.x_wrapname}}_arburst  : std_logic_vector({{.type.x_tburst.x_width}}-1 downto 0);
{{/ .type.x_tburst}}
{{? .type.x_tlock}}
signal {{.x_wrapname}}_arlock   : std_logic_vector({{.type.x_tlock.x_width}}-1 downto 0);
{{/ .type.x_tlock}}
{{? .type.x_tcache}}
signal {{.x_wrapname}}_arcache  : std_logic_vector({{.type.x_tcache.x_width}}-1 downto 0);
{{/ .type.x_tcache}}
{{? .type.x_tprot}}
signal {{.x_wrapname}}_arprot   : std_logic_vector({{.type.x_tprot.x_width}}-1 downto 0);
{{/ .type.x_tprot}}
{{? .type.x_tqos}}
signal {{.x_wrapname}}_arqos    : std_logic_vector({{.type.x_tqos.x_width}}-1 downto 0);
{{/ .type.x_tqos}}
{{? .type.x_tregion}}
signal {{.x_wrapname}}_arregion : std_logic_vector({{.type.x_tregion.x_width}}-1 downto 0);
{{/ .type.x_tregion}}
{{? .type.x_tid}}
signal {{.x_wrapname}}_arid     : std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_taruser}}
signal {{.x_wrapname}}_aruser   : std_logic_vector({{.type.x_taruser.x_width}}-1 downto 0);
{{/ .type.x_taruser}}
signal {{.x_wrapname}}_arvalid  : std_logic;
signal {{.x_wrapname}}_arready  : std_logic;
signal {{.x_wrapname}}_rdata    : std_logic_vector({{.x_tdata.x_width}}-1 downto 0);
signal {{.x_wrapname}}_rresp    : std_logic_vector({{.x_tresp.x_width}}-1 downto 0);
{{? .type.x_tlast}}
signal {{.x_wrapname}}_rlast    : std_logic;
{{/ .type.x_tlast}}
{{? .type.x_tid}}
signal {{.x_wrapname}}_rid      : std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/ .type.x_tid}}
{{? .type.x_truser}}
signal {{.x_wrapname}}_ruser    : std_logic_vector({{.type.x_truser.x_width}}-1 downto 0);
{{/ .type.x_truser}}
signal {{.x_wrapname}}_rvalid   : std_logic;
signal {{.x_wrapname}}_rready   : std_logic;
{{/.type.x_has_rd}}
