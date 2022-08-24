signal {{.x_wrapname}}_tdata   : std_logic_vector({{.type.x_tdata.x_width}}-1 downto 0);
{{?.type.x_tstrb}}
signal {{.x_wrapname}}_tstrb   : std_logic_vector({{.type.x_tstrb.x_width}}-1 downto 0);
{{/.type.x_tstrb}}
{{?.type.x_tkeep}}
signal {{.x_wrapname}}_tkeep   : std_logic_vector({{.type.x_tkeep.x_width}}-1 downto 0);
{{/.type.x_tkeep}}
{{?.type.x_tid}}
signal {{.x_wrapname}}_tid     : std_logic_vector({{.type.x_tid.x_width}}-1 downto 0);
{{/.type.x_tid}}
{{?.type.x_tdest}}
signal {{.x_wrapname}}_tdest   : std_logic_vector({{.type.x_tdest.x_width}}-1 downto 0);
{{/.type.x_tdest}}
{{?.type.x_tuser}}
signal {{.x_wrapname}}_tuser   : std_logic_vector({{.type.x_tuser.x_width}}-1 downto 0);
{{/.type.x_tuser}}
{{?.type.x_has_last}}
signal {{.x_wrapname}}_tlast   : std_logic;
{{/.type.x_has_last}}
signal {{.x_wrapname}}_tvalid  : std_logic;
signal {{.x_wrapname}}_tready  : std_logic;
