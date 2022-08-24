signal {{.x_wrapname}}_address0 : std_logic_vector ({{.type.x_taddr.x_width}}-1 downto 0);
{{?.type.x_has_wr}}
signal {{.x_wrapname}}_we0      : std_logic;
signal {{.x_wrapname}}_d0       : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_has_wr}}
{{?.type.x_has_rd}}
signal {{.x_wrapname}}_q0       : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_has_rd}}
signal {{.x_wrapname}}_ce0      : std_logic;
