{{?.type.x_is_sink}}
{{?.type.x_has_id}}
{{.x_wrapname}}_dout    : {{mode_ms}} std_logic_vector ({{.type.x_tdata.x_width}} + {{.type.x_tid.x_width}} - 1 downto 0);
{{|.type.x_has_id}}
{{.x_wrapname}}_dout    : {{mode_ms}} {{=.type.x_tdata.x_width}}std_logic_vector ({{.}}-1 downto 0){{|.type.x_tdata.x_width}}std_logic{{/.type.x_tdata.x_width}};
{{/.type.x_has_id}}
{{.x_wrapname}}_empty_n : {{mode_sm}} std_logic;
{{.x_wrapname}}_read    : {{mode_ms}} std_logic
{{|.type.x_is_sink}}
{{?.type.x_has_id}}
{{.x_wrapname}}_din     : {{mode_sm}} std_logic_vector ({{.type.x_tdata.x_width}} + {{.type.x_tid.x_width}} - 1 downto 0);
{{|.type.x_has_id}}
{{.x_wrapname}}_din     : {{mode_sm}} {{=.type.x_tdata.x_width}}std_logic_vector ({{.}}-1 downto 0){{|.type.x_tdata.x_width}}std_logic{{/.type.x_tdata.x_width}};
{{/.type.x_has_id}}
{{.x_wrapname}}_full_n  : {{mode_sm}} std_logic;
{{.x_wrapname}}_write   : {{mode_ms}} std_logic
{{/.type.x_is_sink}}
