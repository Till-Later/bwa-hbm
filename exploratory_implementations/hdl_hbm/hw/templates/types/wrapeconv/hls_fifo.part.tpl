{{?.is_ms_input}}
{{? .type.x_is_sink}}
{{.identifier_ms}}.strobe <= {{.x_wrapname}}_read;
{{| .type.x_is_sink}}
{{.identifier_ms}}.data   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_din);
{{.identifier_ms}}.strobe <= {{.x_wrapname}}_write;
{{/ .type.x_is_sink}}
{{|.is_ms_input}}
{{? .type.x_is_sink}}
{{.x_wrapname}}_read    <= {{.identifier_ms}}.strobe <= {{.x_wrapname}}_read;
{{| .type.x_is_sink}}
{{.x_wrapname}}_din     <= std_logic_vector({{.identifier_ms}}.data);
{{.x_wrapname}}_write   <= {{.identifier_ms}}.strobe <= {{.x_wrapname}}_write;
{{/ .type.x_is_sink}}
{{/.is_ms_input}}
{{?.is_sm_input}}
{{? .type.x_is_sink}}
{{.identifier_sm}}.data   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_dout);
{{.identifier_sm}}.ready  <= {{.x_wrapname}}_empty_n;
{{| .type.x_is_sink}}
{{.identifier_sm}}.ready  <= {{.x_wrapname}}_full_n;
{{/ .type.x_is_sink}}
{{|.is_sm_input}}
{{? .type.x_is_sink}}
{{.x_wrapname}}_dout    <= std_logic_vector({{.identifier_sm}}.data);
{{.x_wrapname}}_empty_n <= {{.identifier_sm}}.ready;
{{| .type.x_is_sink}}
{{.x_wrapname}}_full_n  <= {{.identifier_sm}}.ready;
{{/ .type.x_is_sink}}
{{/.is_sm_input}}
