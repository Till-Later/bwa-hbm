type {{.identifier_ms}} is record
  addr : {{.x_tRegAddr.qualified}};
  wrdata : {{.x_tRegData.qualified}};
  wrstrb : {{.x_tRegStrb.qualified}};
  wrnotrd : {{.x_tlogic.qualified}};
  valid : {{.x_tlogic.qualified}};
end record;
type {{identifier_sm}} is record
  rddata : {{.x_tRegData.qualified}};
  ready : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
