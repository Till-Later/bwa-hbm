{{.x_wrapname}}_address     : {{mode_ms}} std_logic_vector ({{.type.x_taddr.x_width}}-1 downto 0);
{{.x_wrapname}}_req_din     : {{mode_ms}} std_logic;
{{.x_wrapname}}_size        : {{mode_ms}} std_logic_vector ({{.type.x_tsize.x_width}}-1 downto 0);
{{.x_wrapname}}_dataout     : {{mode_ms}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{.x_wrapname}}_req_full_n  : {{mode_sm}} std_logic;
{{.x_wrapname}}_req_write   : {{mode_ms}} std_logic;
{{.x_wrapname}}_datain      : {{mode_sm}} std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
{{.x_wrapname}}_rsp_empty_n : {{mode_sm}} std_logic;
{{.x_wrapname}}_rsp_read    : {{mode_ms}} std_logic
