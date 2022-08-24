{{?.is_ms_input}}
{{.x_wrapname}}_address0 <= std_logic_vector({{.identifier_ms}}.addr);
{{? .type.x_has_wr}}
{{.x_wrapname}}_we0      <= {{.identifier_ms}}.write ;
{{.x_wrapname}}_d0       <= std_logic_vector({{.identifier_ms}}.wdata);
{{/ .type.x_has_wr}}
{{.x_wrapname}}_ce0      <= {{.identifier_ms}}.strobe ;
{{|.is_ms_input}}
{{.identifier_ms}}.addr   <= {{.type.x_taddr.qualified}}({{.x_wrapname}}_address0);
{{? .type.x_has_wr}}
{{.identifier_ms}}.write  <= {{.x_wrapname}}_we0;
{{.identifier_ms}}.wdata  <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_d0);
{{/ .type.x_has_wr}}
{{.identifier_ms}}.strobe <= {{.x_wrapname}}_ce0;
{{/.is_ms_input}}
{{?.is_sm_input}}
{{? .type.x_has_rd}}
{{.x_wrapname}}_q0       <= std_logic_vector({{.identifier_sm}}.data);
{{/ .type.x_has_rd}}
{{|.is_sm_input}}
{{? .type.x_has_rd}}
{{.identifier_sm}}.data   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_q0);
{{/ .type.x_has_rd}}
{{/.is_sm_input}}
