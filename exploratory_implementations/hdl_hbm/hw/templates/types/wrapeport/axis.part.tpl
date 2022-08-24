{{.x_wrapname}}_tdata   : {{.mode_ms}} std_logic_vector({{.type.x_tdata.x_width}}-1 downto 0);
{{?.type.x_tstrb}}
{{.x_wrapname}}_tstrb   : {{.mode_ms}} std_logic_vector({{.type.x_tstrb.x_width}}-1 downto 0);
{{/.type.x_tstrb}}
{{?.type.x_tkeep}}
{{.x_wrapname}}_tkeep   : {{.mode_ms}} std_logic_vector({{.type.x_tkeep.x_width}}-1 downto 0);
{{/.type.x_tkeep}}
{{?.type.x_tid}}
{{.x_wrapname}}_tid     : {{.mode_ms}} std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/.type.x_tid}}
{{?.type.x_tdest}}
{{.x_wrapname}}_tdest   : {{.mode_ms}} std_logic_vector({{.type.x_tdest.x_width}}-1 downto 0);
{{/.type.x_tdest}}
{{?.type.x_tuser}}
{{.x_wrapname}}_tuser   : {{.mode_ms}} std_logic_vector({{.type.x_tuser.x_width}}-1 downto 0);
{{/.type.x_tuser}}
{{?.type.x_has_last}}
{{.x_wrapname}}_tlast   : {{.mode_ms}} std_logic;
{{/.type.x_has_last}}
{{.x_wrapname}}_tvalid  : {{.mode_ms}} std_logic;
{{.x_wrapname}}_tready  : {{.mode_sm}} std_logic
