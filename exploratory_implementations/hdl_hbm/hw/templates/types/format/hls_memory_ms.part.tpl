(addr   => {{=..x_taddr}}{{=..addr}}{{*..x_format}}{{|..addr}}{{.x_cnull.qualified}}{{/..addr}}{{/..x_taddr}},
{{?..x_has_wr}}
 write  => {{=..x_tlogic}}{{=..write}}{{*..x_format}}{{|..write}}{{.x_cnull.qualified}}{{/..write}}{{/..x_tlogic}},
 wdata  => {{=..x_tdata}}{{=..wdata}}{{*..x_format}}{{|..wdata}}{{.x_cnull.qualified}}{{/..wdata}}{{/..x_tdata}},
{{/..x_has_wr}}
 strobe  => {{=..x_tlogic}}{{=..strobe}}{{*..x_format}}{{|..strobe}}{{.x_cnull.qualified}}{{/..strobe}}{{/..x_tlogic}})
