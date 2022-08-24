{{?.type.x_is_input}}
{{? .type.x_has_ivld}}
signal {{.x_wrapname}}{{.type.x_iprefix}}_ap_vld : std_logic;
{{/ .type.x_has_ivld}}
{{? .type.x_has_iack}}
signal {{.x_wrapname}}{{.type.x_iprefix}}_ap_ack : std_logic;
{{/ .type.x_has_iack}}
signal {{.x_wrapname}}{{.type.x_iprefix}}        : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_is_input}}
{{?.type.x_is_output}}
{{? .type.x_has_ovld}}
signal {{.x_wrapname}}{{.type.x_oprefix}}_ap_vld : std_logic;
{{/ .type.x_has_ovld}}
{{? .type.x_has_oack}}
signal {{.x_wrapname}}{{.type.x_oprefix}}_ap_ack : std_logic;
{{/ .type.x_has_oack}}
signal {{.x_wrapname}}{{.type.x_oprefix}}        : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{/.type.x_is_output}}
