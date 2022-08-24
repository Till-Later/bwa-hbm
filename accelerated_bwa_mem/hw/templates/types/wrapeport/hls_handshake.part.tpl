{{?.type.x_is_input}}
{{? .type.x_has_ivld}}
{{.x_wrapname}}{{.type.x_iprefix}}_ap_vld : {{.mode_sm}} std_logic;
{{/ .type.x_has_ivld}}
{{? .type.x_has_iack}}
{{.x_wrapname}}{{.type.x_iprefix}}_ap_ack : {{.mode_ms}} std_logic;
{{/ .type.x_has_iack}}
{{.x_wrapname}}{{.type.x_iprefix}}        : {{.mode_sm}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0){{?.type.x_is_output}};{{/.type.x_is_output}}
{{/.type.x_is_input}}
{{?.type.x_is_output}}
{{? .type.x_has_ovld}}
{{.x_wrapname}}{{.type.x_oprefix}}_ap_vld : {{.mode_ms}} std_logic;
{{/ .type.x_has_ovld}}
{{? .type.x_has_oack}}
{{.x_wrapname}}{{.type.x_oprefix}}_ap_ack : {{.mode_sm}} std_logic;
{{/ .type.x_has_oack}}
{{.x_wrapname}}{{.type.x_oprefix}}        : {{.mode_ms}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0)
{{/.type.x_is_output}}
