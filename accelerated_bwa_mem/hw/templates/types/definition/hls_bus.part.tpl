type {{.identifier_ms}} is record
  req_addr   : {{.x_taddr.qualified}};
  req_write  : {{.x_tlogic.qualified}};
  req_size   : {{.x_tsize.qualified}};
  req_wdata  : {{.x_tdata.qualified}};
  req_strobe : {{.x_tlogic.qualified}};
  rsp_strobe : {{.x_tlogic.qualified}};
end record;
type {{identifier_sm}} is record
  req_ready  : {{.x_tlogic.qualified}};
  rsp_rdata  : {{.x_tdata.qualified}};
  rsp_ready  : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
