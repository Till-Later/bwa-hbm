(addr => {{=..x_tRegAddr}}{{=..addr}}{{*..x_format}}{{|..addr}}{{.x_cnull.qualified}}{{/..addr}}{{/..x_tRegAddr}},
 wrdata => {{=..x_tRegData}}{{=..wrdata}}{{*..x_format}}{{|..wrdata}}{{.x_cnull.qualified}}{{/..wrdata}}{{/..x_tRegData}},
 wrstrb => {{=..x_tRegStrb}}{{=..wrstrb}}{{*..x_format}}{{|..wrstrb}}{{.x_cnull.qualified}}{{/..wrstrb}}{{/..x_tRegStrb}},
 wrnotrd => {{=..x_tlogic}}{{=..wrnotrd}}{{*..x_format}}{{|..wrnotrd}}{{.x_cnull.qualified}}{{/..wrnotrd}}{{/..x_tlogic}},
 valid => {{=..x_tlogic}}{{=..valid}}{{*..x_format}}{{|..valid}}{{.x_cnull.qualified}}{{/..valid}}{{/..x_tlogic}})
