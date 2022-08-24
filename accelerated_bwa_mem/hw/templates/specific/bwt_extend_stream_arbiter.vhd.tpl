library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util.all;

Library xpm;
use xpm.vcomponents.all;

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

architecture BwtExtendStreamArbiter of {{identifier}} is
    -- g_StreamCount
    -- g_LogRequestFifoDepth
    -- g_PipelineIndexWidth
    alias ai_sys is {{x_psys.identifier}};

    alias as_req_sources_ms is {{x_ps_req_sources.identifier_ms}};
    alias as_req_sources_sm is {{x_ps_req_sources.identifier_sm}};

    signal ss_req_sources_fifoOut_ms : {{x_ps_req_sources.type.qualified_v_ms}}(g_StreamCount-1 downto 0);
    signal ss_req_sources_fifoOut_sm : {{x_ps_req_sources.type.qualified_v_sm}}(g_StreamCount-1 downto 0);

    signal requestMask           : unsigned(g_StreamCount-1 downto 0);
    signal grantedMask           : unsigned(g_StreamCount-1 downto 0);
    signal processedMask         : unsigned(g_StreamCount-1 downto 0);

    signal grantedPort          : unsigned(f_clog2(g_StreamCount) - 1 downto 0);

    signal reqActive            : std_logic;

    alias as_req_sink_sm is {{x_ps_req_sink.identifier_sm}};
    alias as_req_sink_ms is {{x_ps_req_sink.identifier_ms}};

    alias as_ret_source_ms is {{x_ps_ret_source.identifier_ms}};
    alias as_ret_source_sm is {{x_ps_ret_source.identifier_sm}};

    signal ss_ret_source_pipelineStageOut_ms : {{x_ps_ret_source.type.qualified_ms}};
    signal ss_ret_source_pipelineStageOut_sm : {{x_ps_ret_source.type.qualified_sm}};

    signal ss_ret_source_fifoIn_ms : {{x_ps_ret_source.type.qualified_v_ms}}(g_StreamCount-1 downto 0);
    signal ss_ret_source_fifoIn_sm : {{x_ps_ret_source.type.qualified_v_sm}}(g_StreamCount-1 downto 0);

    alias as_ret_sinks_sm is {{x_ps_ret_sinks.identifier_sm}};
    alias as_ret_sinks_ms is {{x_ps_ret_sinks.identifier_ms}};

    type t_RequestSourceBuffer is array (0 to (2**g_PipelineIndexWidth - 1)) of unsigned(f_clog2(g_StreamCount) - 1 downto 0);
    signal requestSourceBuffer : t_RequestSourceBuffer;
    signal currentReturnStream : unsigned(f_clog2(g_StreamCount) - 1 downto 0);
begin
    req_fifo_buffers : for I in 0 to g_StreamCount-1 generate
    begin
        i_fifo : entity work.UtilFastFIFO
        generic map (
          g_DataWidth => {{x_ps_req_sources.type.x_tdata.x_width}},
          g_LogDepth  => g_LogRequestFifoDepth)
        port map (
          pi_clk      => ai_sys.clk,
          pi_rst_n    => ai_sys.rst_n,
          pi_inData   => as_req_sources_ms(I).data,
          pi_inValid  => as_req_sources_ms(I).strobe,
          po_inReady  => as_req_sources_sm(I).ready,
          po_outData  => ss_req_sources_fifoOut_ms(I).data,
          po_outValid => ss_req_sources_fifoOut_ms(I).strobe,
          pi_outReady => ss_req_sources_fifoOut_sm(I).ready);
        requestMask(I)                                  <= ss_req_sources_fifoOut_ms(I).strobe;
        ss_req_sources_fifoOut_sm(I).ready              <= grantedMask(I) and as_req_sink_ms.strobe;
    end generate req_fifo_buffers;

    i_arbiter : entity work.UtilArbiter
    generic map (
      g_PortCount => g_StreamCount)
    port map (
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_request    => requestMask,
      po_grant      => grantedMask,
      po_port       => grantedPort,
      po_active     => reqActive
    );

    as_req_sink_sm.data     <= ss_req_sources_fifoOut_ms(to_integer(grantedPort)).data;
    as_req_sink_sm.ready   <= ss_req_sources_fifoOut_ms(to_integer(grantedPort)).strobe;

    process (ai_sys.clk)
    begin
        if ai_sys.clk'event and ai_sys.clk = '1' then
            if ss_req_sources_fifoOut_ms(to_integer(grantedPort)).strobe = '1' and as_req_sink_ms.strobe = '1' then
                requestSourceBuffer(to_integer(unsigned(
                    ss_req_sources_fifoOut_ms(to_integer(grantedPort)).data(
                        as_req_sink_sm.data'length - 1 downto
                        as_req_sink_sm.data'length - g_PipelineIndexWidth
                    )
                ))) <= grantedPort;
            end if;
        end if;
    end process;

    i_retPipelineStageSource : entity work.PipelineStage
    generic map(
      g_DataWidth => {{x_ps_ret_source.type.x_tdata.x_width}}
    )
    port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_inData     => as_ret_source_ms.data,
      pi_inValid    => as_ret_source_ms.strobe,
      po_inReady    => as_ret_source_sm.ready,
      po_outData    => ss_ret_source_pipelineStageOut_ms.data,
      po_outValid   => ss_ret_source_pipelineStageOut_ms.strobe,
      pi_outReady   => ss_ret_source_pipelineStageOut_sm.ready);

    currentReturnStream <= requestSourceBuffer(to_integer(unsigned(
        ss_ret_source_pipelineStageOut_ms.data(
          ss_ret_source_pipelineStageOut_ms.data'length - 1 downto
          ss_ret_source_pipelineStageOut_ms.data'length - g_PipelineIndexWidth
        )
    )));
    processedMask <= to_unsigned(1, g_StreamCount) sll to_integer(currentReturnStream);

    ss_ret_source_pipelineStageOut_sm.ready  <= ss_ret_source_fifoIn_sm(to_integer(currentReturnStream)).ready;

    return_streams : for I in 0 to g_StreamCount-1 generate
    begin
      ss_ret_source_fifoIn_ms(I).data     <= ss_ret_source_pipelineStageOut_ms.data;
      ss_ret_source_fifoIn_ms(I).strobe   <= ss_ret_source_pipelineStageOut_ms.strobe and processedMask(I);
    end generate return_streams;

    ret_fifo_buffers : for I in 0 to g_StreamCount-1 generate
    begin
        i_fifo : entity work.UtilFastFIFO
        generic map (
          g_DataWidth => {{x_ps_ret_sinks.type.x_tdata.x_width}},
          g_LogDepth  => g_LogRequestFifoDepth)
        port map (
          pi_clk      => ai_sys.clk,
          pi_rst_n    => ai_sys.rst_n,
          pi_inData   => ss_ret_source_fifoIn_ms(I).data,
          pi_inValid  => ss_ret_source_fifoIn_ms(I).strobe,
          po_inReady  => ss_ret_source_fifoIn_sm(I).ready,
          po_outData  => as_ret_sinks_sm(I).data,
          po_outValid => as_ret_sinks_sm(I).ready,
          pi_outReady => as_ret_sinks_ms(I).strobe);
    end generate ret_fifo_buffers;

end BwtExtendStreamArbiter;