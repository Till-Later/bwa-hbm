{{.x_wrapname}}_idle      : {{.mode_sm}} std_logic;
{{.x_wrapname}}_start     : {{.mode_ms}} std_logic;
{{.x_wrapname}}_ready     : {{.mode_sm}} std_logic;
{{?.type.x_tdata}}
{{.x_wrapname}}_return    : {{.mode_sm}} std_logic_vector({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_tdata}}
{{.x_wrapname}}_done      : {{.mode_sm}} std_logic{{?.type.x_has_continue}};{{/.type.x_has_continue}}
{{?.type.x_has_continue}}
{{.x_wrapname}}_continue  : {{.mode_ms}} std_logic
{{/.type.x_has_continue}}
