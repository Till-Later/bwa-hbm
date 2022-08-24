{{?.type.x_tsdata}}
signal {{.x_wrapname}}_sdata : std_logic_vector({{.type.x_tsdata.x_width}}-1 downto 0);
{{/.type.x_tsdata}}
signal {{.x_wrapname}}_stb   : std_logic;
{{?.type.x_tadata}}
signal {{.x_wrapname}}_adata : std_logic_vector({{.type.x_tadata.x_width}}-1 downto 0);
{{/.type.x_tadata}}
signal {{.x_wrapname}}_ack   : std_logic;
