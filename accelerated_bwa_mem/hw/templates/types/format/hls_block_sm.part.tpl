(idle  => {{=..x_tlogic}}{{=..idle}}{{*..x_format}}{{|..idle}}{{.x_cnull.qualified}}{{/..idle}}{{/..x_tlogic}},
 ready => {{=..x_tlogic}}{{=..ready}}{{*..x_format}}{{|..ready}}{{.x_cnull.qualified}}{{/..ready}}{{/..x_tlogic}},
{{?..x_tdata}}
 data  => {{=..x_tdata}}{{=..data}}{{*..x_format}}{{|..data}}{{.x_cnull.qualified}}{{/..data}}{{/..x_tdata}},
{{/..x_tdata}}
 done  => {{=..x_tlogic}}{{=..done}}{{*..x_format}}{{|..done}}{{.x_cnull.qualified}}{{/..done}}{{/..x_tlogic}})
