{{?.is_ms_input}}
{{.x_wrapname}}_start    <= {{.identifier_ms}}.start;
{{? .type.x_has_continue}}
{{.x_wrapname}}_continue <= {{.identifier_ms}}.continue;
{{/ .type.x_has_continue}}
{{|.is_ms_input}}
{{.identifier_ms}}.start    <= {{.x_wrapname}}_start;
{{? .type.x_has_continue}}
{{.identifier_ms}}.continue <= {{.x_wrapname}}_continue;
{{/ .type.x_has_continue}}
{{/.is_ms_input}}
{{?.is_sm_input}}
{{.x_wrapname}}_idle     <= {{.identifier_sm}}.idle;
{{.x_wrapname}}_ready    <= {{.identifier_sm}}.ready;
{{?.type.x_tdata}}
{{.x_wrapname}}_return   <= {{.identifier_sm}}.data;
{{/.type.x_tdata}}
{{.x_wrapname}}_done     <= {{.identifier_sm}}.done;
{{|.is_sm_input}}
{{.identifier_sm}}.idle     <= {{.x_wrapname}}_idle;
{{.identifier_sm}}.ready    <= {{.x_wrapname}}_ready;
{{?.type.x_tdata}}
{{.identifier_sm}}.data     <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_return);
{{/.type.x_tdata}}
{{.identifier_sm}}.done     <= {{.x_wrapname}}_done;
{{/.is_sm_input}}
