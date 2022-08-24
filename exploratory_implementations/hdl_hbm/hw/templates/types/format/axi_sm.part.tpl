{{?..x_has_wr}}
(awready  => {{=..x_tlogic}}{{=..awready}}{{*..x_format}}{{|..awready}}{{.x_cnull.qualified}}{{/..awready}}{{/..x_tlogic}},
 wready   => {{=..x_tlogic}}{{=..wready}}{{*..x_format}}{{|..wready}}{{.x_cnull.qualified}}{{/..wready}}{{/..x_tlogic}},
{{? ..x_tid}}
 bid      => {{=..x_tid}}{{=..bid}}{{*..x_format}}{{|..bid}}{{.x_cnull.qualified}}{{/..bid}}{{/..x_tid}},
{{/ ..x_tid}}
{{? ..x_tbuser}}
 buser    => {{=..x_tbuser}}{{=..buser}}{{*..x_format}}{{|..buser}}{{.x_cnull.qualified}}{{/..buser}}{{/..x_tbuser}},
{{/ ..x_tbuser}}
 bresp    => {{=..x_tresp}}{{=..bresp}}{{*..x_format}}{{|..bresp}}{{.x_cnull.qualified}}{{/..bresp}}{{/..x_tresp}},
 bvalid   => {{=..x_tlogic}}{{=..bvalid}}{{*..x_format}}{{|..bvalid}}{{.x_cnull.qualified}}{{/..bvalid}}{{/..x_tlogic}}{{?..x_has_rd}},{{|..x_has_rd}}){{/..x_has_rd}}
{{/..x_has_wr}}
{{?..x_has_rd}}
{{?..x_has_wr}} {{|..x_has_wr}}({{/..x_has_wr}}arready  => {{=..x_tlogic}}{{=..arready}}{{*..x_format}}{{|..arready}}{{.x_cnull.qualified}}{{/..arready}}{{/..x_tlogic}},
 rdata    => {{=..x_tdata}}{{=..rdata}}{{*..x_format}}{{|..rdata}}{{.x_cnull.qualified}}{{/..rdata}}{{/..x_tdata}},
 rresp    => {{=..x_tresp}}{{=..rresp}}{{*..x_format}}{{|..rresp}}{{.x_cnull.qualified}}{{/..rresp}}{{/..x_tresp}},
{{? ..x_tlast}}
 rlast    => {{=..x_tlast}}{{=..rlast}}{{*..x_format}}{{|..rlast}}{{.x_cnull.qualified}}{{/..rlast}}{{/..x_tlast}},
{{/ ..x_tlast}}
{{? ..x_tid}}
 rid      => {{=..x_tid}}{{=..rid}}{{*..x_format}}{{|..rid}}{{.x_cnull.qualified}}{{/..rid}}{{/..x_tid}},
{{/ ..x_tid}}
{{? ..x_truser}}
 ruser    => {{=..x_truser}}{{=..ruser}}{{*..x_format}}{{|..ruser}}{{.x_cnull.qualified}}{{/..ruser}}{{/..x_truser}},
{{/ ..x_truser}}
 rvalid   => {{=..x_tlogic}}{{=..rvalid}}{{*..x_format}}{{|..rvalid}}{{.x_cnull.qualified}}{{/..rvalid}}{{/..x_tlogic}})
{{/..x_has_rd}}
