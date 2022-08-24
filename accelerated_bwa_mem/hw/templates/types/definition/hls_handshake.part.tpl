type {{.identifier_ms}} is record
{{?.x_is_output}}
  odata : {{.x_tdata.qualified}};
{{? .x_has_ovld}}
  ovld  : {{.x_tlogic.qualified}};
{{/ .x_has_ovld}}
{{|.x_is_output}}
{{^ .x_has_iack}}
  dummy : std_logic;
{{/ .x_has_iack}}
{{/.x_is_output}}
{{?.x_has_iack}}
  iack  : {{.x_tlogic.qualified}};
{{/.x_has_iack}}
end record;
type {{identifier_sm}} is record
{{?.x_is_input}}
  idata : {{.x_tdata.qualified}};
{{? .x_has_ivld}}
  ivld  : {{.x_tlogic.qualified}};
{{/ .x_has_ivld}}
{{|.x_is_input}}
{{^.x_has_oack}}
  dummy : std_logic;
{{/.x_has_oack}}
{{/.x_is_input}}
{{?.x_has_oack}}
  oack  : {{.x_tlogic.qualified}};
{{/.x_has_oack}}
end record;
type {{.identifier_v_ms}} is array (integer range <>) of {{.qualified_ms}};
type {{.identifier_v_sm}} is array (integer range <>) of {{.qualified_sm}};
