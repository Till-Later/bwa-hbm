{{?.is_ms_input}}
{{.x_wrapname}}_address     <= std_logic_vector({{.identifier_ms}}.req_addr);
{{.x_wrapname}}_req_din     <= {{.identifier_ms}}.req_write;
{{.x_wrapname}}_size        <= std_logic_vector({{.identifier_ms}}.req_size);
{{.x_wrapname}}_dataout     <= std_logic_vector({{.identifier_ms}}.req_wdata);
{{.x_wrapname}}_req_write   <= {{.identifier_ms}}.req_strobe;
{{.x_wrapname}}_rsp_read    <= {{.identifier_ms}}.rsp_strobe;
{{|.is_ms_input}}
{{.identifier_ms}}.req_addr   <= {{.type.x_taddr.qualified}}({{.x_wrapname}}_address);
{{.identifier_ms}}.req_write  <= {{.x_wrapname}}_req_din;
{{.identifier_ms}}.req_size   <= {{.type.x_tsize.qualified}}({{.x_wrapname}}_size);
{{.identifier_ms}}.req_wdata  <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_dataout);
{{.identifier_ms}}.req_strobe <= {{.x_wrapname}}_req_write;
{{.identifier_ms}}.rsp_strobe <= {{.x_wrapname}}_rsp_read;
{{/.is_ms_input}}
{{?.is_sm_input}}
{{.x_wrapname}}_req_full_n  <= {{.identifier_sm}}.req_ready;
{{.x_wrapname}}_datain      <= std_logic_vector({{.identifier_sm}}.rsp_rdata);
{{.x_wrapname}}_rsp_empty_n <= {{.identifier_sm}}.rsp_ready;
{{|.is_sm_input}}
{{.identifier_sm}}.req_ready  <= {{.x_wrapname}}_req_full_n;
{{.identifier_sm}}.rsp_rdata  <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_datain);
{{.identifier_sm}}.rsp_ready  <= {{.x_wrapname}}_rsp_empty_n;
{{/.is_sm_input}}
