{{?.type.x_tsdata}}
{{.x_wrapname}}_sdata : {{.mode_ms}} std_logic_vector({{.type.x_tsdata.x_width}}-1 downto 0);
{{/.type.x_tsdata}}
{{.x_wrapname}}_stb   : {{.mode_ms}} std_logic;
{{?.type.x_tadata}}
{{.x_wrapname}}_adata : {{.mode_sm}} std_logic_vector({{.type.x_tadata.x_width}}-1 downto 0);
{{/.type.x_tadata}}
{{.x_wrapname}}_ack   : {{.mode_sm}} std_logic
