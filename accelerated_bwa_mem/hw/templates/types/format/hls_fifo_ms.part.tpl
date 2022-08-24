{{^..x_is_sink}}
(data   => {{=..x_tdata}}{{=..data}}{{*..x_format}}{{|..data}}{{.x_cnull.qualified}}{{/..data}}{{/..x_tdata}},
{{?..x_has_id}}
 id     => {{=..x_tid}}{{=..data}}{{*..x_format}}{{|..data}}{{.x_cnull.qualified}}{{/..data}}{{/..x_tid}},
{{/..x_has_id}}
{{/..x_is_sink}}
{{?..x_is_sink}}({{|..x_is_sink}} {{/..x_is_sink}}strobe => {{=..x_tlogic}}{{=..strobe}}{{*..x_format}}{{|..strobe}}{{.x_cnull.qualified}}{{/..strobe}}{{/..x_tlogic}})
