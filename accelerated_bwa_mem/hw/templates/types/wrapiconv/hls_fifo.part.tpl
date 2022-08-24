{{?.is_ms_input}}
{{? .type.x_is_sink}}
{{.x_wrapname}}_read    <= {{.identifier_ms}}.strobe <= {{.x_wrapname}}_read;
{{| .type.x_is_sink}}
{{?.type.x_tdata.x_width}}
{{?.type.x_has_id}}
{{.x_wrapname}}_din     <= std_logic_vector({{.identifier_ms}}.id & {{.identifier_ms}}.data);
{{|.type.x_has_id}}
{{.x_wrapname}}_din     <= std_logic_vector({{.identifier_ms}}.data);
{{/.type.x_has_id}}
{{|.type.x_tdata.x_width}}
{{.x_wrapname}}_din     <= std_logic({{.identifier_ms}}.data);
{{/.type.x_tdata.x_width}}
{{.x_wrapname}}_write   <= {{.identifier_ms}}.strobe <= {{.x_wrapname}}_write;
{{/ .type.x_is_sink}}
{{|.is_ms_input}}
{{? .type.x_is_sink}}
{{.identifier_ms}}.strobe <= {{.x_wrapname}}_read;
{{| .type.x_is_sink}}
{{?.type.x_has_id}}
{{.identifier_ms}}.data   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_din({{.type.x_tdata.x_width}} - 1 downto 0));
{{.identifier_ms}}.id     <= {{.type.x_tid.qualified}}({{.x_wrapname}}_din({{.x_wrapname}}_din'length - 1 downto {{.type.x_tdata.x_width}}));
{{|.type.x_has_id}}
{{.identifier_ms}}.data   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_din);
{{/.type.x_has_id}}
{{.identifier_ms}}.strobe <= {{.x_wrapname}}_write;
{{/ .type.x_is_sink}}
{{/.is_ms_input}}
{{?.is_sm_input}}
{{? .type.x_is_sink}}
{{?.type.x_tdata.x_width}}
{{?.type.x_has_id}}
{{.x_wrapname}}_dout    <= std_logic_vector({{.identifier_sm}}.id & {{.identifier_sm}}.data);
{{|.type.x_has_id}}
{{.x_wrapname}}_dout    <= std_logic_vector({{.identifier_sm}}.data);
{{/.type.x_has_id}}
{{|.type.x_tdata.x_width}}
{{.x_wrapname}}_dout    <= std_logic({{.identifier_sm}}.data);
{{/.type.x_tdata.x_width}}
{{.x_wrapname}}_empty_n <= {{.identifier_sm}}.ready;
{{| .type.x_is_sink}}
{{.x_wrapname}}_full_n  <= {{.identifier_sm}}.ready;
{{/ .type.x_is_sink}}
{{|.is_sm_input}}
{{? .type.x_is_sink}}
{{?.type.x_has_id}}
{{.identifier_sm}}.data   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_dout({{.type.x_tdata.x_width}} - 1 downto 0)));
{{.identifier_sm}}.id     <= {{.type.x_tid.qualified}}({{.x_wrapname}}_dout({{.x_wrapname}}_dout'length - 1 downto {{.type.x_tdata.x_width}}));
{{|.type.x_has_id}}
{{.identifier_sm}}.data   <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_dout);
{{/.type.x_has_id}}
{{.identifier_sm}}.ready  <= {{.x_wrapname}}_empty_n;
{{| .type.x_is_sink}}
{{.identifier_sm}}.ready  <= {{.x_wrapname}}_full_n;
{{/ .type.x_is_sink}}
{{/.is_sm_input}}
