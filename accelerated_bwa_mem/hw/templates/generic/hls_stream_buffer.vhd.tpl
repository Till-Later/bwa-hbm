library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util;
use work.UtilFastFIFO;

entity {{identifier}} is
{{?generics}}
  generic (
{{# generics}}
{{#  is_complex}}
    {{identifier_ms}} : {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
    {{identifier_sm}} : {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/  is_complex}}
{{/ generics}}
{{/generics}}
{{?ports}}
  port (
{{# ports}}
{{#  is_complex}}
    {{identifier_ms}} : {{mode_ms}} {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}};
    {{identifier_sm}} : {{mode_sm}} {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{mode}} {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/  is_complex}}
{{/ ports}}
{{/ports}}
end {{identifier}};

architecture HlsStreamBuffer of {{identifier}} is
    constant c_DataWidth : integer := 
      {{?x_ps_source.type.x_tdata.x_width}}
        {{x_ps_source.type.x_tdata.x_width}}        
      {{|x_ps_source.type.x_tdata.x_width}}
        1
      {{/x_ps_source.type.x_tdata.x_width}}
      {{?x_ps_source.type.x_has_id}}
        + {{x_ps_source.type.x_tid.x_width}}
      {{/x_ps_source.type.x_has_id}};

    alias ai_sys is {{x_psys.identifier}};

    alias as_source_ms is {{x_ps_source.identifier_ms}};
    alias as_source_sm is {{x_ps_source.identifier_sm}};

    alias as_sink_sm is {{x_ps_sink.identifier_sm}};
    alias as_sink_ms is {{x_ps_sink.identifier_ms}};

    signal as_source_intermediate_ms : {{x_ps_source.type.qualified_ms}};
    signal as_source_intermediate_sm : {{x_ps_source.type.qualified_sm}};

    signal as_sink_intermediate_ms : {{x_ps_sink.type.qualified_ms}};
    signal as_sink_intermediate_sm : {{x_ps_sink.type.qualified_sm}};

    signal rst_n_buffer : std_logic;

begin
    process (ai_sys.clk)
    begin
        if ai_sys.clk'event and ai_sys.clk = '1' then
          rst_n_buffer <= ai_sys.rst_n;
        end if;
    end process;

    i_pipelineStageIn : entity work.PipelineStage
    generic map(
      g_DataWidth => c_DataWidth
    )
    port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => rst_n_buffer,
      pi_inData     => "" & {{?x_ps_source.type.x_has_id}}as_source_ms.id & {{/x_ps_source.type.x_has_id}} as_source_ms.data,
      pi_inValid    => as_source_ms.strobe,
      po_inReady    => as_source_sm.ready,
      {{?x_ps_source.type.x_tdata.x_width}}
      po_outData({{x_ps_source.type.x_tdata.x_width}} - 1 downto 0)    => as_source_intermediate_ms.data,
      {{?x_ps_source.type.x_has_id}}
      po_outData(c_DataWidth - 1 downto {{x_ps_source.type.x_tdata.x_width}})    => as_source_intermediate_ms.id,
      {{/x_ps_source.type.x_has_id}}
      {{|x_ps_source.type.x_tdata.x_width}}
      po_outData(0)  => as_source_intermediate_ms.data,
      {{/x_ps_source.type.x_tdata.x_width}}
      po_outValid   => as_source_intermediate_ms.strobe,
      pi_outReady   => as_source_intermediate_sm.ready);

    i_fifo : entity work.UtilFastFIFO
    generic map (
      g_DataWidth => c_DataWidth,
      g_LogDepth  => g_FIFOLogDepth)
    port map (
      pi_clk      => ai_sys.clk,
      pi_rst_n    => rst_n_buffer,
      pi_inData   => "" & {{?x_ps_source.type.x_has_id}}as_source_intermediate_ms.id & {{/x_ps_source.type.x_has_id}} as_source_intermediate_ms.data,
      pi_inValid  => as_source_intermediate_ms.strobe,
      po_inReady  => as_source_intermediate_sm.ready,
      {{?x_ps_source.type.x_tdata.x_width}}
      po_outData({{x_ps_source.type.x_tdata.x_width}} - 1 downto 0)    => as_sink_intermediate_sm.data,
      {{?x_ps_source.type.x_has_id}}
      po_outData(c_DataWidth - 1 downto {{x_ps_source.type.x_tdata.x_width}})    => as_sink_intermediate_sm.id,
      {{/x_ps_source.type.x_has_id}}
      {{|x_ps_source.type.x_tdata.x_width}}
      po_outData(0)  => as_sink_intermediate_sm.data,
      {{/x_ps_source.type.x_tdata.x_width}}
      po_outValid => as_sink_intermediate_sm.ready,
      pi_outReady => as_sink_intermediate_ms.strobe);

     i_pipelineStageOut : entity work.PipelineStage
     generic map(
       g_DataWidth => c_DataWidth
     )
     port map(
       pi_clk        => ai_sys.clk,
       pi_rst_n      => rst_n_buffer,
       pi_inData     => "" & {{?x_ps_source.type.x_has_id}}as_sink_intermediate_sm.id & {{/x_ps_source.type.x_has_id}} as_sink_intermediate_sm.data,
       pi_inValid    => as_sink_intermediate_sm.ready,
       po_inReady    => as_sink_intermediate_ms.strobe,
       {{?x_ps_source.type.x_tdata.x_width}}
       po_outData({{x_ps_source.type.x_tdata.x_width}} - 1 downto 0)    => as_sink_sm.data,
       {{?x_ps_source.type.x_has_id}}
       po_outData(c_DataWidth - 1 downto {{x_ps_source.type.x_tdata.x_width}})    => as_sink_sm.id,
       {{/x_ps_source.type.x_has_id}}
       {{|x_ps_source.type.x_tdata.x_width}}
       po_outData(0)  => as_sink_sm.data,
       {{/x_ps_source.type.x_tdata.x_width}}
       po_outValid   => as_sink_sm.ready,
       pi_outReady   => as_sink_ms.strobe);


end HlsStreamBuffer;