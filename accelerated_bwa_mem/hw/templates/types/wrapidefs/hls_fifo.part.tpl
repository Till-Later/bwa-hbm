{{?.type.x_is_sink}}
{{?.type.x_has_id}}
signal {{.x_wrapname}}_dout    : std_logic_vector ({{.type.x_tdata.x_width}}  + {{.type.x_tid.x_width}} - 1 downto 0);
{{|.type.x_has_id}}
signal {{.x_wrapname}}_dout    : {{=.type.x_tdata.x_width}}std_logic_vector ({{.}}-1 downto 0){{|.type.x_tdata.x_width}}std_logic{{/.type.x_tdata.x_width}};
{{/.type.x_has_id}}
signal {{.x_wrapname}}_empty_n : std_logic;
signal {{.x_wrapname}}_read    : std_logic;
{{|.type.x_is_sink}}
{{?.type.x_has_id}}
signal {{.x_wrapname}}_din     : std_logic_vector ({{.type.x_tdata.x_width}} + {{.type.x_tid.x_width}} - 1 downto 0);
{{|.type.x_has_id}}
signal {{.x_wrapname}}_din     : {{=.type.x_tdata.x_width}}std_logic_vector ({{.}}-1 downto 0){{|.type.x_tdata.x_width}}std_logic{{/.type.x_tdata.x_width}};
{{/.type.x_has_id}}
signal {{.x_wrapname}}_full_n  : std_logic;
signal {{.x_wrapname}}_write   : std_logic;
{{/.type.x_is_sink}}
