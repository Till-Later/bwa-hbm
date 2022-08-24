{{?.type.x_is_sink}}
{{.x_wrapname}}_dout    => {{.x_wrapname}}_dout,
{{.x_wrapname}}_empty_n => {{.x_wrapname}}_empty_n,
{{.x_wrapname}}_read    => {{.x_wrapname}}_read
{{|.type.x_is_sink}}
{{.x_wrapname}}_din     => {{.x_wrapname}}_din,
{{.x_wrapname}}_full_n  => {{.x_wrapname}}_full_n,
{{.x_wrapname}}_write   => {{.x_wrapname}}_write
{{/.type.x_is_sink}}
