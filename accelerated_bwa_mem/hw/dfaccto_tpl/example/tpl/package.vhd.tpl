library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}


package {{identifier}} is

-- second constant: {{constants.1}}
-- type named "Logic": {{types.Logic}}
-- Type List:
{{#types}}
--   {{_idx}} - {{.}}
{{/types}}

{{#declarations}}
{{# is_a_type}}
  {{*x_definition}}
{{/ is_a_type}}
{{# is_a_constant}}
{{?  is_assigned}}
{{#  is_complex}}
  constant {{identifier_ms}} : {{type.qualified_ms}} := {{=assignment}}{{?is_literal}}{{=value}}{{*type.x_format_ms}}{{/value}}{{|is_literal}}{{qualified_ms}}{{/is_literal}};{{/assignment}}
{{?   assignments}}
    ({{#assignments}}{{?is_literal}}{{=value}}{{*type.x_format_ms}}{{/value}}{{|is_literal}}{{qualified_ms}}{{/is_literal}}{{^_last}}, {{/_last}}{{/assignments}});
{{/   assignments}}
  constant {{identifier_sm}} : {{type.qualified_sm}} := {{=assignment}}{{?is_literal}}{{=value}}{{*type.x_format_sm}}{{/value}}{{|is_literal}}{{qualified_sm}}{{/is_literal}};{{/assignment}}
{{?   assignments}}
    ({{#assignments}}{{?is_literal}}{{=value}}{{*type.x_format_sm}}{{/value}}{{|is_literal}}{{qualified_sm}}{{/is_literal}}{{^_last}}, {{/_last}}{{/assignments}});
{{/   assignments}}
{{|  is_complex}}
  constant {{identifier}} : {{type.qualified}} := {{=assignment}}{{?is_literal}}{{=value}}{{*type.x_format}}{{/value}}{{|is_literal}}{{qualified}}{{/is_literal}};{{/assignment}}
{{?   assignments}}
    ({{#assignments}}{{?is_literal}}{{=value}}{{*type.x_format}}{{/value}}{{|is_literal}}{{qualified}}{{/is_literal}}{{^_last}}, {{/_last}}{{/assignments}});
{{/   assignments}}
{{/  is_complex}}
{{|  is_assigned}}
{{#  is_complex}}
  -- constant {{identifier_ms}} : {{type.qualified_ms}} := <undefined>;
  -- constant {{identifier_sm}} : {{type.qualified_sm}} := <undefined>;
{{|  is_complex}}
  -- constant {{identifier}} : {{type.qualified}} := <undefined>;
{{/  is_complex}}
{{/  is_assigned}}
{{/ is_a_constant}}

{{/declarations}}
end {{identifier}};
