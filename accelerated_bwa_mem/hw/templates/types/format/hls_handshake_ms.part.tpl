{{?..x_is_output}}
(odata  => {{=..x_tdata}}{{=..odata}}{{*..x_format}}{{|..odata}}{{.x_cnull.qualified}}{{/..odata}}{{/..x_tdata}}{{?..x_has_ovld}},{{|..x_has_ovld}}{{?..x_has_iack}},{{|..x_has_iack}}){{/..x_has_iack}}{{/..x_has_ovld}}
{{? ..x_has_ovld}}
 ovld   => {{=..x_tlogic}}{{=..ovld}}{{*..x_format}}{{|..ovld}}{{.x_cnull.qualified}}{{/..ovld}}{{/..x_tlogic}}{{?..x_has_iack}},{{|..x_has_iack}}){{/..x_has_iack}}
{{/ ..x_has_ovld}}
{{/..x_is_output}}
{{?..x_has_iack}}
{{?..x_is_output}} {{|..x_is_output}}({{/..x_is_output}}iack   => {{=..x_tlogic}}{{=..iack}}{{*..x_format}}{{|..iack}}{{.x_cnull.qualified}}{{/..iack}}{{/..x_tlogic}})
{{/..x_has_iack}}
{{^..x_is_output}}{{^..x_has_iack}}(dummy => '-'){{/..x_has_iack}}{{/..x_is_output}}
