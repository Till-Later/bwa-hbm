{{.x_extname}}_addr : std_logic_vector({{.type.x_tRegAddr.x_width}}-1 downto 0);
{{.x_extname}}_wrdata : {{.mode_ms}} std_logic_vector({{.type.x_tRegData.x_width}}-1 downto 0);
{{.x_extname}}_wrstrb : {{.mode_ms}} std_logic_vector({{.type.x_tRegStrb.x_width}}-1 downto 0);
{{.x_extname}}_wrnotrd : {{.mode_ms}} std_logic;
{{.x_extname}}_valid : {{.mode_ms}} std_logic;
{{.x_extname}}_ctx : {{.mode_sm}} std_logic_vector({{.type.x_tRegData.x_width}}-1 downto 0);
{{.x_extname}}_ready : {{.mode_sm}} std_logic;
