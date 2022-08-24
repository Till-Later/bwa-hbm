{{?..x_has_wr}}
-- {{..}}   |   {{.}}
(awaddr   => {{=..x_taddr}}{{=..awaddr}}{{*..x_format}}{{|..awaddr}}{{.x_cnull.qualified}}{{/..awaddr}}{{/..x_taddr}},
{{? ..x_tlen}}
 awlen    => {{=..x_tlen}}{{=..awlen}}{{*..x_format}}{{|..awlen}}{{.x_cnull.qualified}}{{/..awlen}}{{/..x_tlen}},
{{/ ..x_tlen}}
{{? ..x_tsize}}
 awsize   => {{=..x_tsize}}{{=..awsize}}{{*..x_format}}{{|..awsize}}{{.x_cnull.qualified}}{{/..awsize}}{{/..x_tsize}},
{{/ ..x_tsize}}
{{? ..x_tburst}}
 awburst  => {{=..x_tburst}}{{=..awburst}}{{*..x_format}}{{|..awburst}}{{.x_cnull.qualified}}{{/..awburst}}{{/..x_tburst}},
{{/ ..x_tburst}}
{{? ..x_tlock}}
 awlock   => {{=..x_tlock}}{{=..awlock}}{{*..x_format}}{{|..awlock}}{{.x_cnull.qualified}}{{/..awlock}}{{/..x_tlock}},
{{/ ..x_tlock}}
{{? ..x_tcache}}
 awcache  => {{=..x_tcache}}{{=..awcache}}{{*..x_format}}{{|..awcache}}{{.x_cnull.qualified}}{{/..awcache}}{{/..x_tcache}},
{{/ ..x_tcache}}
{{? ..x_tprot}}
 awprot   => {{=..x_tprot}}{{=..awprot}}{{*..x_format}}{{|..awprot}}{{.x_cnull.qualified}}{{/..awprot}}{{/..x_tprot}},
{{/ ..x_tprot}}
{{? ..x_tqos}}
 awqos    => {{=..x_tqos}}{{=..awqos}}{{*..x_format}}{{|..awqos}}{{.x_cnull.qualified}}{{/..awqos}}{{/..x_tqos}},
{{/ ..x_tqos}}
{{? ..x_tregion}}
 awregion => {{=..x_tregion}}{{=..awregion}}{{*..x_format}}{{|..awregion}}{{.x_cnull.qualified}}{{/..awregion}}{{/..x_tregion}},
{{/ ..x_tregion}}
{{? ..x_tid}}
 awid     => {{=..x_tid}}{{=..awid}}{{*..x_format}}{{|..awid}}{{.x_cnull.qualified}}{{/..awid}}{{/..x_tid}},
{{/ ..x_tid}}
{{? ..x_tawuser}}
 awuser   => {{=..x_tawuser}}{{=..awuser}}{{*..x_format}}{{|..awuser}}{{.x_cnull.qualified}}{{/..awuser}}{{/..x_tawuser}},
{{/ ..x_tawuser}}
 awvalid  => {{=..x_tlogic}}{{=..awvalid}}{{*..x_format}}{{|..awvalid}}{{.x_cnull.qualified}}{{/..awvalid}}{{/..x_tlogic}},
 wdata    => {{=..x_tdata}}{{=..wdata}}{{*..x_format}}{{|..wdata}}{{.x_cnull.qualified}}{{/..wdata}}{{/..x_tdata}},
 wstrb    => {{=..x_tstrb}}{{=..wstrb}}{{*..x_format}}{{|..wstrb}}{{.x_cnull.qualified}}{{/..wstrb}}{{/..x_tstrb}},
{{? ..x_tlast}}
 wlast    => {{=..x_tlast}}{{=..wlast}}{{*..x_format}}{{|..wlast}}{{.x_cnull.qualified}}{{/..wlast}}{{/..x_tlast}},
{{/ ..x_tlast}}
{{? ..x_twuser}}
 wuser    => {{=..x_twuser}}{{=..wuser}}{{*..x_format}}{{|..wuser}}{{.x_cnull.qualified}}{{/..wuser}}{{/..x_twuser}},
{{/ ..x_twuser}}
 wvalid   => {{=..x_tlogic}}{{=..wvalid}}{{*..x_format}}{{|..wvalid}}{{.x_cnull.qualified}}{{/..wvalid}}{{/..x_tlogic}},
 bready   => {{=..x_tlogic}}{{=..bready}}{{*..x_format}}{{|..bready}}{{.x_cnull.qualified}}{{/..bready}}{{/..x_tlogic}}{{?..x_has_rd}},{{|..x_has_rd}}){{/..x_has_rd}}
{{/..x_has_wr}}
{{?..x_has_rd}}
{{?..x_has_wr}} {{|..x_has_wr}}({{/..x_has_wr}}araddr   => {{=..x_taddr}}{{=..araddr}}{{*..x_format}}{{|..araddr}}{{.x_cnull.qualified}}{{/..araddr}}{{/..x_taddr}},
{{? ..x_tlen}}
 arlen    => {{=..x_tlen}}{{=..arlen}}{{*..x_format}}{{|..arlen}}{{.x_cnull.qualified}}{{/..arlen}}{{/..x_tlen}},
{{/ ..x_tlen}}
{{? ..x_tsize}}
 arsize   => {{=..x_tsize}}{{=..arsize}}{{*..x_format}}{{|..arsize}}{{.x_cnull.qualified}}{{/..arsize}}{{/..x_tsize}},
{{/ ..x_tsize}}
{{? ..x_tburst}}
 arburst  => {{=..x_tburst}}{{=..arburst}}{{*..x_format}}{{|..arburst}}{{.x_cnull.qualified}}{{/..arburst}}{{/..x_tburst}},
{{/ ..x_tburst}}
{{? ..x_tlock}}
 arlock   => {{=..x_tlock}}{{=..arlock}}{{*..x_format}}{{|..arlock}}{{.x_cnull.qualified}}{{/..arlock}}{{/..x_tlock}},
{{/ ..x_tlock}}
{{? ..x_tcache}}
 arcache  => {{=..x_tcache}}{{=..arcache}}{{*..x_format}}{{|..arcache}}{{.x_cnull.qualified}}{{/..arcache}}{{/..x_tcache}},
{{/ ..x_tcache}}
{{? ..x_tprot}}
 arprot   => {{=..x_tprot}}{{=..arprot}}{{*..x_format}}{{|..arprot}}{{.x_cnull.qualified}}{{/..arprot}}{{/..x_tprot}},
{{/ ..x_tprot}}
{{? ..x_tqos}}
 arqos    => {{=..x_tqos}}{{=..arqos}}{{*..x_format}}{{|..arqos}}{{.x_cnull.qualified}}{{/..arqos}}{{/..x_tqos}},
{{/ ..x_tqos}}
{{? ..x_tregion}}
 arregion => {{=..x_tregion}}{{=..arregion}}{{*..x_format}}{{|..arregion}}{{.x_cnull.qualified}}{{/..arregion}}{{/..x_tregion}},
{{/ ..x_tregion}}
{{? ..x_tid}}
 arid     => {{=..x_tid}}{{=..arid}}{{*..x_format}}{{|..arid}}{{.x_cnull.qualified}}{{/..arid}}{{/..x_tid}},
{{/ ..x_tid}}
{{? ..x_taruser}}
 aruser   => {{=..x_taruser}}{{=..aruser}}{{*..x_format}}{{|..aruser}}{{.x_cnull.qualified}}{{/..aruser}}{{/..x_taruser}},
{{/ ..x_taruser}}
 arvalid  => {{=..x_tlogic}}{{=..arvalid}}{{*..x_format}}{{|..arvalid}}{{.x_cnull.qualified}}{{/..arvalid}}{{/..x_tlogic}},
 rready   => {{=..x_tlogic}}{{=..rready}}{{*..x_format}}{{|..rready}}{{.x_cnull.qualified}}{{/..rready}}{{/..x_tlogic}})
{{/..x_has_rd}}
