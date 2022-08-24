{{?.type.x_is_input}}
{{? .type.x_has_ivld}}
{{.x_wrapname}}{{.type.x_iprefix}}_ap_vld => {{.x_wrapname}}{{.type.x_iprefix}}_ap_vld,
{{/ .type.x_has_ivld}}
{{? .type.x_has_iack}}
{{.x_wrapname}}{{.type.x_iprefix}}_ap_ack => {{.x_wrapname}}{{.type.x_iprefix}}_ap_ack,
{{/ .type.x_has_iack}}
{{.x_wrapname}}{{.type.x_iprefix}}        => {{.x_wrapname}}{{.type.x_iprefix}}{{?.type.x_is_output}},{{/.type.x_is_output}}
{{/.type.x_is_input}}
{{?.type.x_is_output}}
{{? .type.x_has_ovld}}
{{.x_wrapname}}{{.type.x_oprefix}}_ap_vld => {{.x_wrapname}}{{.type.x_oprefix}}_ap_vld,
{{/ .type.x_has_ovld}}
{{? .type.x_has_oack}}
{{.x_wrapname}}{{.type.x_oprefix}}_ap_ack => {{.x_wrapname}}{{.type.x_oprefix}}_ap_ack,
{{/ .type.x_has_oack}}
{{.x_wrapname}}{{.type.x_oprefix}}        => {{.x_wrapname}}{{.type.x_oprefix}}
{{/.type.x_is_output}}
