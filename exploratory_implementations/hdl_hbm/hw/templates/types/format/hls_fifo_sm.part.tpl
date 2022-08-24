{{?..x_is_sink}}
(data   => {{=..x_tdata}}{{=..data}}{{*..x_format}}{{|..data}}{{.x_cnull.qualified}}{{/..data}}{{/..x_tdata}},
{{/..x_is_sink}}
{{?..x_is_sink}} {{|..x_is_sink}}({{/..x_is_sink}}ready  => {{=..x_tlogic}}{{=..ready}}{{*..x_format}}{{|..ready}}{{.x_cnull.qualified}}{{/..ready}}{{/..x_tlogic}})
