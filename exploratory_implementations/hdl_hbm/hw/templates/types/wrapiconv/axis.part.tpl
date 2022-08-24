{{?.is_ms_input}}
{{.x_wrapname}}_tdata   <= std_logic_vector({{.identifier_ms}}.tdata);
{{? .type.x_tstrb}}
{{.x_wrapname}}_tstrb   <= std_logic_vector({{.identifier_ms}}.tstrb);
{{/ .type.x_tstrb}}
{{? .type.x_tkeep}}
{{.x_wrapname}}_tkeep   <= std_logic_vector({{.identifier_ms}}.tkeep);
{{/ .type.x_tkeep}}
{{? .type.x_tid}}
{{.x_wrapname}}_tid     <= std_logic_vector({{.identifier_ms}}.tid);
{{/ .type.x_tid}}
{{? .type.x_tdest}}
{{.x_wrapname}}_tdest   <= std_logic_vector({{.identifier_ms}}.tdest);
{{/ .type.x_tdest}}
{{? .type.x_tuser}}
{{.x_wrapname}}_tuser   <= std_logic_vector({{.identifier_ms}}.tuser);
{{/ .type.x_tuser}}
{{? .type.x_has_last}}
{{.x_wrapname}}_tlast   <= {{.identifier_ms}}.tlast;
{{/ .type.x_has_last}}
{{.x_wrapname}}_tvalid  <= {{.identifier_ms}}.tvalid;
{{|.is_ms_input}}
{{.identifier_ms}}.tdata  <= {{.type.x_tdata.qualified}}({{.x_wrapname}}_tdata);
{{? .type.x_tstrb}}
{{.identifier_ms}}.tstrb  <= {{.type.x_tstrb.qualified}}({{.x_wrapname}}_tstrb);
{{/ .type.x_tstrb}}
{{? .type.x_tkeep}}
{{.identifier_ms}}.tkeep  <= {{.type.x_tkeep.qualified}}({{.x_wrapname}}_tkeep);
{{/ .type.x_tkeep}}
{{? .type.x_tid}}
{{.identifier_ms}}.tid    <= {{.type.x_tid.qualified}}({{.x_wrapname}}_tid);
{{/ .type.x_tid}}
{{? .type.x_tdest}}
{{.identifier_ms}}.tdest  <= {{.type.x_tdest.qualified}}({{.x_wrapname}}_tdest);
{{/ .type.x_tdest}}
{{? .type.x_tuser}}
{{.identifier_ms}}.tuser  <= {{.type.x_tuser.qualified}}({{.x_wrapname}}_tuser);
{{/ .type.x_tuser}}
{{? .type.x_has_last}}
{{.identifier_ms}}.tlast  <= {{.x_wrapname}}_tlast;
{{/ .type.x_has_last}}
{{.identifier_ms}}.tvalid <= {{.x_wrapname}}_tvalid;
{{/.is_ms_input}}
{{?.is_sm_input}}
{{.x_wrapname}}_tready  <= {{.identifier_sm}}.tready;
{{|.is_sm_input}}
{{.identifier_sm}}.tready <= {{.x_wrapname}}_tready;
{{/.is_sm_input}}
