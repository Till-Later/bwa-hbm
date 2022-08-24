signal {{.x_wrapname}}     : std_logic;
signal {{.x_wrapname}}_src : std_logic_vector({{.type.x_tsrc.x_width}}-1 downto 0);
signal {{.x_wrapname}}_ctx : std_logic_vector({{.type.x_tctx.x_width}}-1 downto 0);
signal {{.x_wrapname}}_ack : std_logic;
