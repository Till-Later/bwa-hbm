{{.x_wrapname}}_address0 : {{mode_ms}} std_logic_vector ({{.type.x_taddr.x_width}}-1 downto 0);
{{?.type.x_has_wr}}
{{.x_wrapname}}_we0      : {{mode_ms}} std_logic;
{{.x_wrapname}}_d0       : {{mode_ms}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_has_wr}}
{{?.type.x_has_rd}}
{{.x_wrapname}}_q0       : {{mode_sm}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_has_rd}}
{{.x_wrapname}}_ce0      : {{mode_ms}} std_logic
