{{?.type.x_is_sink}}
signal {{.x_wrapname}}_dout    : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
signal {{.x_wrapname}}_empty_n : std_logic;
signal {{.x_wrapname}}_read    : std_logic;
{{|.type.x_is_sink}}
signal {{.x_wrapname}}_din     : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
signal {{.x_wrapname}}_full_n  : std_logic;
signal {{.x_wrapname}}_write   : std_logic;
{{/.type.x_is_sink}}
