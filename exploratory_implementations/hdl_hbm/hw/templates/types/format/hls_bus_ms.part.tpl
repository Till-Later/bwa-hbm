(req_addr   => {{=..x_taddr}}{{=..req_addr}}{{*..x_format}}{{|..req_addr}}{{.x_cnull.qualified}}{{/..req_addr}}{{/..x_taddr}},
 req_write  => {{=..x_tlogic}}{{=..req_write}}{{*..x_format}}{{|..req_write}}{{.x_cnull.qualified}}{{/..req_write}}{{/..x_tlogic}},
 req_size   => {{=..x_tsize}}{{=..req_size}}{{*..x_format}}{{|..req_size}}{{.x_cnull.qualified}}{{/..req_size}}{{/..x_tsize}},
 req_wdata  => {{=..x_tdata}}{{=..req_wdata}}{{*..x_format}}{{|..req_wdata}}{{.x_cnull.qualified}}{{/..req_wdata}}{{/..x_tdata}},
 req_strobe => {{=..x_tlogic}}{{=..req_strobe}}{{*..x_format}}{{|..req_strobe}}{{.x_cnull.qualified}}{{/..req_strobe}}{{/..x_tlogic}},
 rsp_strobe => {{=..x_tlogic}}{{=..rsp_strobe}}{{*..x_format}}{{|..rsp_strobe}}{{.x_cnull.qualified}}{{/..rsp_strobe}}{{/..x_tlogic}})
