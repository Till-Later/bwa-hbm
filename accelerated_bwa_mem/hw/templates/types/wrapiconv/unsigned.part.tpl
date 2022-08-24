{{?.is_input}}
{{.x_wrapname}} <= std_logic_vector({{.identifier}});
{{|.is_input}}
{{.identifier}} <= {{.type.qualified}}({{.x_wrapname}});
{{/.is_input}}
