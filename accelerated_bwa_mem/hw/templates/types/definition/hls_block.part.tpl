type {{.identifier_ms}} is record
  start : {{.x_tlogic.qualified}};
{{?.x_has_continue}}
  cont  : {{.x_tlogic.qualified}};
{{/.x_has_continue}}
end record;
type {{identifier_sm}} is record
  idle  : {{.x_tlogic.qualified}};
  ready : {{.x_tlogic.qualified}};
{{?.x_tdata}}
  data  : {{.x_tdata.qualified}};
{{/.x_tdata}}
  done  : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
