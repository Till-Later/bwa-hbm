{{.x_wrapname}}     : {{.mode_ms}} std_logic;
{{.x_wrapname}}_src : {{.mode_ms}} std_logic_vector({{.type.x_tsrc.x_width}}-1 downto 0);
{{.x_wrapname}}_ctx : {{.mode_ms}} std_logic_vector({{.type.x_tctx.x_width}}-1 downto 0);
{{.x_wrapname}}_ack : {{.mode_sm}} std_logic
