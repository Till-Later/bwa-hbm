{{?.is_ms_input}}
{{.identifier_ms}}.addr <= {{.x_extname}}_addr;
{{.identifier_ms}}.wrdata <= {{.type.x_tsrc.qualified}}({{.x_extname}}_wrdata);
{{.identifier_ms}}.wrstrb <= {{.type.x_tsrc.qualified}}({{.x_extname}}_wrstrb);
{{.identifier_ms}}.wrnotrd <= {{.type.x_tsrc.qualified}}({{.x_extname}}_wrnotrd);
{{.identifier_ms}}.valid <= {{.type.x_tsrc.qualified}}({{.x_extname}}_valid);
{{|.is_ms_input}}
{{.x_extname}}_addr     <= {{.identifier_ms}}.addr;
{{.x_extname}}_wrdata <= std_logic_vector({{.identifier_ms}}.wrdata);
{{.x_extname}}_wrstrb <= std_logic_vector({{.identifier_ms}}.ctx);
{{.x_extname}}_wrnotrd <= std_logic_vector({{.identifier_ms}}.wrstrb);
{{.x_extname}}_valid <= std_logic_vector({{.identifier_ms}}.valid);
{{/.is_ms_input}}
{{?.is_sm_input}}
{{.identifier_sm}}.rddata <= {{.x_extname}}_rddata;
{{.identifier_sm}}.ready <= {{.x_extname}}_ready;
{{|.is_sm_input}}
{{.x_extname}}_rddata <= {{.identifier_sm}}.rddata;
{{.x_extname}}_ready <= {{.identifier_sm}}.ready;
{{/.is_sm_input}}
