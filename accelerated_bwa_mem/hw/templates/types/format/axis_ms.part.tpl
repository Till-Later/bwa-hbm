(tdata  => {{=..x_tdata}}{{=..tdata}}{{*..x_format}}{{|..tdata}}{{.x_cnull.qualified}}{{/..tdata}}{{/..x_tdata}},
 tkeep  => {{=..x_tkeep}}{{=..tkeep}}{{*..x_format}}{{|..tkeep}}{{.x_cnull.qualified}}{{/..tkeep}}{{/..x_tkeep}},
{{?x_tid}}
 tid    => {{=..x_tid}}{{=..tid}}{{*..x_format}}{{|..tid}}{{.x_cnull.qualified}}{{/..tid}}{{/..x_tid}},
{{/x_tid}}
{{?x_tuser}}
 tuser  => {{=..x_tuser}}{{=..tuser}}{{*..x_format}}{{|..tuser}}{{.x_cnull.qualified}}{{/..tuser}}{{/..x_tuser}},
{{/x_tuser}}
 tlast  => {{=..x_tlogic}}{{=..tlast}}{{*..x_format}}{{|..tlast}}{{.x_cnull.qualified}}{{/..tlast}}{{/..x_tlogic}},
 tvalid => {{=..x_tlogic}}{{=..tvalid}}{{*..x_format}}{{|..tvalid}}{{.x_cnull.qualified}}{{/..tvalid}}{{/..x_tlogic}})
