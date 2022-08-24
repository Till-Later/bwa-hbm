type {{.identifier_ms}} is record
  addr   : {{.x_taddr.qualified}};
{{?.x_has_wr}}
  wdata  : {{.x_tdata.qualified}};
  write  : {{.x_tlogic.qualified}};
{{/.x_has_wr}}
  strobe : {{.x_tlogic.qualified}};
end record;
type {{identifier_sm}} is record
{{?.x_has_rd}}
  rdata  : {{.x_tdata.qualified}};
{{|.x_has_rd}}
  dummy  : std_logic;
{{/.x_has_rd}}
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
