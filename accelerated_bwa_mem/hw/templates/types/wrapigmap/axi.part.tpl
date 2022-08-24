{{?.x_target_addr}}
c_{{.x_wrapname}}_target_addr => {{.x_target_addr}},
{{/.x_target_addr}}
{{?.x_user_value}}
c_{{.x_wrapname}}_user_value => {{.x_user_value}},
{{/.x_user_value}}
{{?.x_prot_value}}
c_{{.x_wrapname}}_prot_value => {{.x_prot_value}},
{{/.x_prot_value}}
{{?.x_cache_value}}
c_{{.x_wrapname}}_cache_value => {{.x_cache_value}},
{{/.x_cache_value}}
{{?.type.x_has_wr}}
{{? .type.x_tawuser}}
c_{{.x_wrapname}}_awuser_width => {{.type.x_tawuser.x_width}},
{{/ .type.x_tawuser}}
{{? .type.x_twuser}}
c_{{.x_wrapname}}_wuser_width => {{.type.x_twuser.x_width}},
{{/ .type.x_twuser}}
{{? .type.x_tbuser}}
c_{{.x_wrapname}}_buser_width => {{.type.x_tbuser.x_width}},
{{/ .type.x_tbuser}}
{{/.type.x_has_wr}}
{{?.type.x_has_rd}}
{{? .type.x_taruser}}
c_{{.x_wrapname}}_aruser_width => {{.type.x_taruser.x_width}},
{{/ .type.x_taruser}}
{{? .type.x_truser}}
c_{{.x_wrapname}}_ruser_width => {{.type.x_truser.x_width}},
{{/ .type.x_truser}}
{{/.type.x_has_rd}}
{{?.type.x_tid}}
c_{{.x_wrapname}}_id_width => {{.type.x_tid.x_width}},
{{/.type.x_tid}}
c_{{.x_wrapname}}_addr_width => {{.type.x_taddr.x_width}},
c_{{.x_wrapname}}_data_width => {{.type.x_tdata.x_width}}
