{{?..x_is_input}}
(idata  => {{=..x_tdata}}{{=..idata}}{{*..x_format}}{{|..idata}}{{.x_cnull.qualified}}{{/..idata}}{{/..x_tdata}}{{?..x_has_ivld}},{{|..x_has_ivld}}{{?..x_has_oack}},{{|..x_has_oack}}){{/..x_has_oack}}{{/..x_has_ivld}}
{{? ..x_has_ivld}}
 ivld   => {{=..x_tlogic}}{{=..ivld}}{{*..x_format}}{{|..ivld}}{{.x_cnull.qualified}}{{/..ivld}}{{/..x_tlogic}}{{?..x_has_oack}},{{|..x_has_oack}}){{/..x_has_oack}}
{{/ ..x_has_ivld}}
{{/..x_is_input}}
{{?..x_has_oack}}
{{?..x_is_input}} {{|..x_is_input}}({{/..x_is_input}}oack   => {{=..x_tlogic}}{{=..oack}}{{*..x_format}}{{|..oack}}{{.x_cnull.qualified}}{{/..oack}}{{/..x_tlogic}})
{{/..x_has_oack}}
{{^..x_is_input}}{{^..x_has_oack}}(dummy => '-'){{/..x_has_oack}}{{/..x_is_input}}
