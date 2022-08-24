signal {{.x_wrapname}}_address     : std_logic_vector ({{.type.x_taddr.x_width}}-1 downto 0);
signal {{.x_wrapname}}_req_din     : std_logic;
signal {{.x_wrapname}}_size        : std_logic_vector ({{.type.x_tsize.x_width}}-1 downto 0);
signal {{.x_wrapname}}_dataout     : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
signal {{.x_wrapname}}_req_full_n  : std_logic;
signal {{.x_wrapname}}_req_write   : std_logic;
signal {{.x_wrapname}}_datain      : std_logic_vector ({{.type.x_tdata.x_width}}-1 downto 0);
signal {{.x_wrapname}}_rsp_empty_n : std_logic;
signal {{.x_wrapname}}_rsp_read    : std_logic;
