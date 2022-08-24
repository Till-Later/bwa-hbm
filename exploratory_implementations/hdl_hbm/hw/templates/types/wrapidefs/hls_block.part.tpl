signal {{.x_wrapname}}_idle      : std_logic;
signal {{.x_wrapname}}_start     : std_logic;
signal {{.x_wrapname}}_ready     : std_logic;
{{?.type.x_tdata}}
signal {{.x_wrapname}}_return    : std_logic_vector({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_tdata}}
signal {{.x_wrapname}}_done      : std_logic;
{{?.type.x_has_continue}}
signal {{.x_wrapname}}_continue  : std_logic;
{{/.type.x_has_continue}}
