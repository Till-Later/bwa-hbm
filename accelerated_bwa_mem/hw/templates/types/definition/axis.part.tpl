type {{.identifier_ms}} is record
  tdata   : {{.x_tdata.qualified}};
  tkeep   : {{.x_tkeep.qualified}};
{{?.x_tid}}
  tid     : {{.x_tid.qualified}};
{{/.x_tid}}
{{?.x_tuser}}
  tuser   : {{.x_tuser.qualified}};
{{/.x_tuser}}
  tlast   : {{.x_tlogic.qualified}};
  tvalid  : {{.x_tlogic.qualified}};
end record;
type {{.identifier_sm}} is record
  tready  : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
