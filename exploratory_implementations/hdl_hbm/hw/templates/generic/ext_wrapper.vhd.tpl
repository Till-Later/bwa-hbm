library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}

entity {{identifier}} is
  port (
{{#ports}}
    -- {{name}}:
    {{*.type.x_wrapeport}}{{?._last}}){{/._last}};
{{/ports}}
end {{identifier}};

architecture ExternalWrapper of {{identifier}} is

-- Internal Ports

{{#ports}}
{{? .is_scalar}}
  -- {{name}}
{{?  .is_complex}}
  signal {{identifier_ms}} : {{type.qualified_ms}};
  signal {{identifier_sm}} : {{type.qualified_sm}};
{{|  .is_complex}}
  signal {{identifier}} : {{type.qualified}};
{{/  .is_complex}}
{{| .is_scalar}}
  report "ExternalWrapper can not wrap vector port {{name}}" severity failure;
{{/ .is_scalar}}
{{/ports}}

-- Signals

{{#signals}}
{{# is_complex}}
  signal {{identifier_ms}} : {{#is_vector}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{|is_vector}}{{type.qualified_ms}}{{/is_vector}};
  signal {{identifier_sm}} : {{#is_vector}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{|is_vector}}{{type.qualified_sm}}{{/is_vector}};
{{| is_complex}}
  signal {{identifier}} : {{#is_vector}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{|is_vector}}{{type.qualified}}{{/is_vector}};
{{/ is_complex}}
{{/signals}}

begin

  -- Instantiations

{{#instances}}
  {{identifier}} : entity work.{{base.identifier}}
{{? generics}}
    generic map (
{{#  generics}}
{{?   is_assigned}}
{{?    is_complex}}
{{#     assignments}}
      {{..identifier_ms}}({{._idx}}) => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_ms}}{{/value}}{{/type}}{{|is_literal}}{{qualified_ms}}{{/is_literal}},
      {{..identifier_sm}}({{._idx}}) => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_sm}}{{/value}}{{/type}}{{|is_literal}}{{qualified_sm}}{{/is_literal}}{{?.._last}}{{?._last}}){{|._last}},{{/._last}}{{|.._last}},{{/.._last}}
{{/     assignments}}
{{#     assignment}}
      {{..identifier_ms}} => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_ms}}{{/value}}{{/type}}{{|is_literal}}{{qualified_ms}}{{/is_literal}},
      {{..identifier_sm}} => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_sm}}{{/value}}{{/type}}{{|is_literal}}{{qualified_sm}}{{/is_literal}}{{?.._last}}){{|.._last}},{{/.._last}}
{{/     assignment}}
{{|    is_complex}}
{{#     assignments}}
      {{..identifier}}({{._idx}}) => {{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{?.._last}}{{?._last}}){{|._last}},{{/._last}}{{|.._last}},{{/.._last}}
{{/     assignments}}
{{#     assignment}}
      {{..identifier}} => {{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{?.._last}}){{|.._last}},{{/.._last}}
{{/     assignment}}
{{/    is_complex}}
{{|   is_assigned}}
{{?    is_complex}}
      {{identifier_ms}} => open,
      {{identifier_sm}} => open{{?._last}}){{|._last}},{{/._last}}
{{|    is_complex}}
      {{identifier}} => open{{?._last}}){{|._last}},{{/._last}}
{{/    is_complex}}
{{/   is_assigned}}
{{/  generics}}
{{/ generics}}
{{? ports}}
    port map (
{{#  ports}}
{{?   is_assigned}}
{{?    is_complex}}
{{#     assignments}}
      {{..identifier_ms}}({{._idx}}) => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_ms}}{{/value}}{{/type}}{{|is_literal}}{{qualified_ms}}{{/is_literal}},
      {{..identifier_sm}}({{._idx}}) => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_sm}}{{/value}}{{/type}}{{|is_literal}}{{qualified_sm}}{{/is_literal}}{{?.._last}}{{?._last}});{{|._last}},{{/._last}}{{|.._last}},{{/.._last}}
{{/     assignments}}
{{#     assignment}}
      {{..identifier_ms}} => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_ms}}{{/value}}{{/type}}{{|is_literal}}{{qualified_ms}}{{/is_literal}},
      {{..identifier_sm}} => {{?is_literal}}{{=type}}{{=value}}{{*..x_format_sm}}{{/value}}{{/type}}{{|is_literal}}{{qualified_sm}}{{/is_literal}}{{?.._last}});{{|.._last}},{{/.._last}}
{{/     assignment}}
{{|    is_complex}}
{{#     assignments}}
      {{..identifier}}({{._idx}}) => {{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{?.._last}}{{?._last}});{{|._last}},{{/._last}}{{|.._last}},{{/.._last}}
{{/     assignments}}
{{#     assignment}}
      {{..identifier}} => {{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{?.._last}});{{|.._last}},{{/.._last}}
{{/    assignment}}
{{/    is_complex}}
{{|   is_assigned}}
{{?    is_complex}}
      {{identifier_ms}} => open,
      {{identifier_sm}} => open{{?._last}});{{|._last}},{{/._last}}
{{|    is_complex}}
      {{identifier}} => open{{?._last}});{{|._last}},{{/._last}}
{{/    is_complex}}
{{/   is_assigned}}
{{/  ports}}
{{/ ports}}
{{/instances}}


  -- Port Mapping

{{#ports}}
  -- {{name}}
  {{*.type.x_wrapeconv}}
{{/ports}}

end ExternalWrapper;
