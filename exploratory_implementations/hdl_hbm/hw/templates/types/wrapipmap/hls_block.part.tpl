{{.x_wrapname}}_idle      => {{.x_wrapname}}_idle,
{{.x_wrapname}}_start     => {{.x_wrapname}}_start,
{{.x_wrapname}}_ready     => {{.x_wrapname}}_ready,
{{?.type.x_tdata}}
{{.x_wrapname}}_return    => {{.x_wrapname}}_return,
{{/.type.x_tdata}}
{{.x_wrapname}}_done      => {{.x_wrapname}}_done{{?.type.x_has_continue}},{{/.type.x_has_continue}}
{{?.type.x_has_continue}}
{{.x_wrapname}}_continue  => {{.x_wrapname}}_continue
{{/.type.x_has_continue}}
