library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.bwt_types;
use work.util.all;

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

architecture BwtRequestController of {{identifier}} is
  -- g_StreamCount 
  -- g_HbmPortCount 
  -- g_HbmCacheLinesPerBwtEntry 
  -- g_RequestAddrWidth

  alias am_req_bwt_position_id_streams_ms is {{x_pm_req_bwt_position_id_streams.identifier_ms}};
  alias am_req_bwt_position_id_streams_sm is {{x_pm_req_bwt_position_id_streams.identifier_sm}};

  alias am_ret_bwt_entry_id_streams_ms is {{x_pm_ret_bwt_entry_id_streams.identifier_ms}};
  alias am_ret_bwt_entry_id_streams_sm is {{x_pm_ret_bwt_entry_id_streams.identifier_sm}};
begin
    hbm_interface : for I in 0 to g_StreamCount - 1 generate
        signal req_bwt_position_id_stream_ms : bwt_types.t_HlsIdStream_sink_26_ms;
        signal req_bwt_position_id_stream_sm : bwt_types.t_HlsIdStream_sink_26_sm;
        signal ret_bwt_entry_id_stream_ms : bwt_types.t_HlsIdStream_source_512_ms;
        signal ret_bwt_entry_id_stream_sm : bwt_types.t_HlsIdStream_source_512_sm;        
    begin
        req_bwt_position_id_stream_sm.data          <= f_resize(am_req_bwt_position_id_streams_sm(I).data(g_RequestAddrWidth - 1 downto 0), bwt_types.t_HlsIdStream_sink_26Data'length);
        req_bwt_position_id_stream_sm.ready         <= am_req_bwt_position_id_streams_sm(I).ready;
        {{?x_pm_req_bwt_position_id_streams.type.x_has_id}}
        req_bwt_position_id_stream_sm.id            <= f_resize(am_req_bwt_position_id_streams_sm(I).id, 6);
        {{|x_pm_req_bwt_position_id_streams.type.x_has_id}}
        req_bwt_position_id_stream_sm.id            <= to_unsigned(0, 6);
        {{/x_pm_req_bwt_position_id_streams.type.x_has_id}}
        am_req_bwt_position_id_streams_ms(I).strobe <= req_bwt_position_id_stream_ms.strobe;

        am_ret_bwt_entry_id_streams_ms(I).data      <= ret_bwt_entry_id_stream_ms.data;
        {{?x_pm_ret_bwt_entry_id_streams.type.x_has_id}}
        am_ret_bwt_entry_id_streams_ms(I).id        <= f_resize(ret_bwt_entry_id_stream_ms.id, {{x_pm_ret_bwt_entry_id_streams.type.x_tid.x_width}});
        {{/x_pm_ret_bwt_entry_id_streams.type.x_has_id}}
        am_ret_bwt_entry_id_streams_ms(I).strobe    <= ret_bwt_entry_id_stream_ms.strobe;
        ret_bwt_entry_id_stream_sm.ready            <= am_ret_bwt_entry_id_streams_sm(I).ready;      

        i_dispatcher : entity work.BwtRequestDispatcher
        generic map (
          g_HbmCacheLinesPerBwtEntry => g_HbmCacheLinesPerBwtEntry)
        port map (
          pi_sys                                    => pi_sys,
          po_req_bwt_position_stream_ms             => req_bwt_position_id_stream_ms,
          pi_req_bwt_position_stream_sm             => req_bwt_position_id_stream_sm,
          po_araddr                                 => po_hbm_ms(I).araddr,
          po_arlen                                  => po_hbm_ms(I).arlen,
          po_arsize                                 => po_hbm_ms(I).arsize,
          po_arburst                                => po_hbm_ms(I).arburst,
          po_arlock                                 => po_hbm_ms(I).arlock,
          po_arcache                                => po_hbm_ms(I).arcache,
          po_arprot                                 => po_hbm_ms(I).arprot,
          po_arqos                                  => po_hbm_ms(I).arqos,
          po_arregion                               => po_hbm_ms(I).arregion,
          po_arid                                   => po_hbm_ms(I).arid,
          po_aruser                                 => po_hbm_ms(I).aruser,
          po_arvalid                                => po_hbm_ms(I).arvalid,
          pi_arready                                => pi_hbm_sm(I).arready);

        i_receiver : entity work.BwtRequestReceiver
        port map (
          pi_sys                                    => pi_sys,
          po_ret_bwt_entry_stream_ms                => ret_bwt_entry_id_stream_ms,
          pi_ret_bwt_entry_stream_sm                => ret_bwt_entry_id_stream_sm,
          po_rready                                 => po_hbm_ms(I).rready,
          pi_rdata                                  => pi_hbm_sm(I).rdata,
          pi_rresp                                  => pi_hbm_sm(I).rresp,
          pi_rlast                                  => pi_hbm_sm(I).rlast,
          pi_rid                                    => pi_hbm_sm(I).rid,
          pi_ruser                                  => pi_hbm_sm(I).ruser,
          pi_rvalid                                 => pi_hbm_sm(I).rvalid);
    end generate hbm_interface;
end BwtRequestController;