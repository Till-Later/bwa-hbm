type {{.identifier_ms}} is record
  ctx : {{.x_tctx.qualified}};
  src : {{.x_tsrc.qualified}};
  stb : {{.x_tlogic.qualified}};
end record;
type {{identifier_sm}} is record
  ack : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
