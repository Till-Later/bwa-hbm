type {{.identifier_ms}} is record
{{^.x_is_sink}}
  data   : {{.x_tdata.qualified}};
{{/.x_is_sink}}
  strobe : {{.x_tlogic.qualified}};
end record;
type {{identifier_sm}} is record
{{?.x_is_sink}}
  data   : {{.x_tdata.qualified}};
{{/.x_is_sink}}
  ready  : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
