{{?.type.x_is_sink}}
{{.x_wrapname}}_dout    : {{mode_ms}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{.x_wrapname}}_empty_n : {{mode_sm}} std_logic;
{{.x_wrapname}}_read    : {{mode_ms}} std_logic
{{|.type.x_is_sink}}
{{.x_wrapname}}_din     : {{mode_sm}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{.x_wrapname}}_full_n  : {{mode_sm}} std_logic;
{{.x_wrapname}}_write   : {{mode_ms}} std_logic
{{/.type.x_is_sink}}
