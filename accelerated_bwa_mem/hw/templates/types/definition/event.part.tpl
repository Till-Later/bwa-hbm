type {{.identifier_ms}} is record
{{?.x_tsdata}}
  sdata : {{.x_tsdata.qualified}};
{{/.x_tsdata}}
  stb   : {{.x_tlogic.qualified}};
end record;
type {{identifier_sm}} is record
{{?.x_tadata}}
  adata : {{.x_tadata.qualified}};
{{/.x_tadata}}
  ack   : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
