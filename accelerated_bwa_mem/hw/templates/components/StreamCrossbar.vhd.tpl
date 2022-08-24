library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
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
  
architecture StreamCrossbar of {{identifier}} is
  -- g_NumInStreamPorts
  -- g_NumOutStreamPorts
  -- g_SelectorBitOffset
  -- g_SelectorBitWidth
  -- g_FIFOLogDepth
  -- g_ModifyId

    constant c_MasterDataWidth : integer := {{x_pm_streamMasters.type.x_tdata.x_width}}{{?x_pm_streamMasters.type.x_has_id}}+ {{x_pm_streamMasters.type.x_tid.x_width}}{{/x_pm_streamMasters.type.x_has_id}};
    constant c_SlaveDataWidth  : integer := {{x_ps_streamSlaves.type.x_tdata.x_width}}{{?x_ps_streamSlaves.type.x_has_id}}+ {{x_ps_streamSlaves.type.x_tid.x_width}}{{/x_ps_streamSlaves.type.x_has_id}};

    alias ai_sys is {{x_psys.identifier}};

    alias am_streamMasters_ms is {{x_pm_streamMasters.identifier_ms}};
    alias am_streamMasters_sm is {{x_pm_streamMasters.identifier_sm}};

    alias as_streamSlaves_sm is {{x_ps_streamSlaves.identifier_sm}};
    alias as_streamSlaves_ms is {{x_ps_streamSlaves.identifier_ms}};

    type t_UnroutedStreamSource_ms is record
{{?x_pm_streamMasters.type.x_is_sink}}     
      data   : unsigned(c_MasterDataWidth - 1 downto 0);
{{|x_pm_streamMasters.type.x_is_sink}}    
      data   : unsigned(c_SlaveDataWidth - 1 downto 0);
{{/x_pm_streamMasters.type.x_is_sink}}
      strobe : dfaccto.t_Logic;
    end record;
    type t_UnroutedStreamSource_sm is record
      ready  : dfaccto.t_Logic;
    end record;
    type t_UnroutedStreamSource_v_ms is array (integer range <>) of t_UnroutedStreamSource_ms;
    type t_UnroutedStreamSource_v_sm is array (integer range <>) of t_UnroutedStreamSource_sm;

    type t_RoutedStreamSource_ms is record
{{?x_pm_streamMasters.type.x_is_sink}}     
      data   : unsigned(c_SlaveDataWidth - 1 downto 0);
{{|x_pm_streamMasters.type.x_is_sink}}   
      data   : unsigned(c_MasterDataWidth - 1 downto 0);   
{{/x_pm_streamMasters.type.x_is_sink}}
      strobe : dfaccto.t_Logic;
    end record;
    type t_RoutedStreamSource_sm is record
      ready  : dfaccto.t_Logic;
    end record;
    type t_RoutedStreamSource_v_ms is array (integer range <>) of t_RoutedStreamSource_ms;
    type t_RoutedStreamSource_v_sm is array (integer range <>) of t_RoutedStreamSource_sm;

    signal s_inStageStreams_ms : t_UnroutedStreamSource_v_ms(0 to (g_NumInStreamPorts - 1));
    signal s_inStageStreams_sm : t_UnroutedStreamSource_v_sm(0 to (g_NumInStreamPorts - 1));

    signal s_outStageStreams_ms : t_RoutedStreamSource_v_ms(0 to (g_NumOutStreamPorts - 1));
    signal s_outStageStreams_sm : t_RoutedStreamSource_v_sm(0 to (g_NumOutStreamPorts - 1));

    type t_UnroutedStreamSources_ms is array (0 to (g_NumInStreamPorts - 1), 0 to (g_NumOutStreamPorts - 1)) of t_UnroutedStreamSource_ms;
    type t_UnroutedStreamSources_sm is array (0 to (g_NumInStreamPorts - 1), 0 to (g_NumOutStreamPorts - 1)) of t_UnroutedStreamSource_sm;

    type t_RoutedStreamSources_ms is array (0 to (g_NumInStreamPorts - 1), 0 to (g_NumOutStreamPorts - 1)) of t_RoutedStreamSource_ms;
    type t_RoutedStreamSources_sm is array (0 to (g_NumInStreamPorts - 1), 0 to (g_NumOutStreamPorts - 1)) of t_RoutedStreamSource_sm;

    signal s_unroutedFifoStreamSources_ms : t_UnroutedStreamSources_ms;
    signal s_unroutedFifoStreamSources_sm : t_UnroutedStreamSources_sm;

    signal s_routedFifoStreamSources_ms : t_RoutedStreamSources_ms;
    signal s_routedFifoStreamSources_sm : t_RoutedStreamSources_sm;
  begin
    in_streams : for InStreamIndex in 0 to (g_NumInStreamPorts - 1) generate      
    begin
      i_pipelineStageIn : entity work.PipelineStage
      generic map(s_inStageStreams_ms(InStreamIndex).data'length)
      port map(
          pi_clk        => ai_sys.clk,
          pi_rst_n      => ai_sys.rst_n,       
{{?x_pm_streamMasters.type.x_is_sink}}         
          pi_inData     => {{?x_pm_streamMasters.type.x_has_id}}am_streamMasters_sm(InStreamIndex).id & {{/x_pm_streamMasters.type.x_has_id}} am_streamMasters_sm(InStreamIndex).data, 
          pi_inValid    => am_streamMasters_sm(InStreamIndex).ready,
          po_inReady    => am_streamMasters_ms(InStreamIndex).strobe,
{{|x_pm_streamMasters.type.x_is_sink}}
          pi_inData     => {{?x_ps_streamSlaves.type.x_has_id}}as_streamSlaves_ms(InStreamIndex).id & {{/x_ps_streamSlaves.type.x_has_id}} as_streamSlaves_ms(InStreamIndex).data, 
          pi_inValid    => as_streamSlaves_ms(InStreamIndex).strobe,
          po_inReady    => as_streamSlaves_sm(InStreamIndex).ready,                    
{{/x_pm_streamMasters.type.x_is_sink}}
          po_outData    => s_inStageStreams_ms(InStreamIndex).data,
          po_outValid   => s_inStageStreams_ms(InStreamIndex).strobe,
          pi_outReady   => s_inStageStreams_sm(InStreamIndex).ready);

      s_inStageStreams_sm(InStreamIndex).ready <= s_unroutedFifoStreamSources_sm(
        InStreamIndex,
        to_integer(unsigned(s_inStageStreams_ms(InStreamIndex).data(g_SelectorBitOffset + g_SelectorBitWidth - 1 downto g_SelectorBitOffset)))
      ).ready;

      fifos : for OutStreamIndex in 0 to (g_NumOutStreamPorts - 1) generate
      begin
        s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe <= 
          s_inStageStreams_ms(InStreamIndex).strobe when s_inStageStreams_ms(InStreamIndex).data(g_SelectorBitOffset + g_SelectorBitWidth - 1 downto g_SelectorBitOffset) = to_unsigned(OutStreamIndex, f_clog2(g_NumOutStreamPorts)) else '0';

        idUnchanged : if g_ModifyId = 0 generate
          s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data <= s_inStageStreams_ms(InStreamIndex).data;
          i_fifo : entity work.UtilFastFIFO
            generic map (
              g_DataWidth => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data'length,
              g_LogDepth  => g_FIFOLogDepth)
            port map (
              pi_clk      => ai_sys.clk,
              pi_rst_n    => ai_sys.rst_n,
              pi_inData   => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data,
              pi_inValid  => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe,
              po_inReady  => s_unroutedFifoStreamSources_sm(InStreamIndex, OutStreamIndex).ready,
              po_outData  => s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data,
              po_outValid => s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe,
              pi_outReady => s_routedFifoStreamSources_sm(InStreamIndex, OutStreamIndex).ready);      
        end generate idUnchanged;

        removeSelector : if g_ModifyId = 1 generate
          s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data <= to_unsigned(0, g_SelectorBitWidth) &
            s_inStageStreams_ms(InStreamIndex).data(s_inStageStreams_ms(InStreamIndex).data'length - 1 downto g_SelectorBitOffset + g_SelectorBitWidth) 
            & s_inStageStreams_ms(InStreamIndex).data(g_SelectorBitOffset - 1 downto 0);
          i_fifo : entity work.UtilFastFIFO
            generic map (
              g_DataWidth => s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data'length,
              g_LogDepth  => g_FIFOLogDepth)
            port map (
              pi_clk      => ai_sys.clk,
              pi_rst_n    => ai_sys.rst_n,
              pi_inData   => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data(s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data'length - 1 downto 0),
              pi_inValid  => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe,
              po_inReady  => s_unroutedFifoStreamSources_sm(InStreamIndex, OutStreamIndex).ready,
              po_outData  => s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data,
              po_outValid => s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe,
              pi_outReady => s_routedFifoStreamSources_sm(InStreamIndex, OutStreamIndex).ready);     
        end generate removeSelector;              
          
        addSourceIndexToFront : if g_ModifyId = 2 generate   
          s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data <= s_inStageStreams_ms(InStreamIndex).data;   
          i_fifo : entity work.UtilFastFIFO
          generic map (
            g_DataWidth => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data'length,
            g_LogDepth  => g_FIFOLogDepth)
          port map (
            pi_clk      => ai_sys.clk,
            pi_rst_n    => ai_sys.rst_n,
            pi_inData   => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data,
            pi_inValid  => s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe,
            po_inReady  => s_unroutedFifoStreamSources_sm(InStreamIndex, OutStreamIndex).ready,
            po_outData  => s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data(s_unroutedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data'length - 1 downto 0),
            po_outValid => s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe,
            pi_outReady => s_routedFifoStreamSources_sm(InStreamIndex, OutStreamIndex).ready);     
          
          s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data(s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data'length - 1 downto s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).data'length - g_SelectorBitWidth) <= 
            to_unsigned(InStreamIndex, g_SelectorBitWidth);
        end generate addSourceIndexToFront;                                
      end generate fifos;
    end generate in_streams;
    
    out_streams : for OutStreamIndex in 0 to (g_NumOutStreamPorts - 1) generate
      signal requestValidMask         : unsigned((g_NumInStreamPorts - 1) downto 0);      
      signal requestGrantedMask       : unsigned((g_NumInStreamPorts - 1) downto 0);
      signal grantedPort              : unsigned(f_clog2(g_NumInStreamPorts) - 1 downto 0);
    begin 
      generate_requestValidMask : for InStreamIndex in 0 to (g_NumInStreamPorts - 1) generate
        requestValidMask(InStreamIndex) <= s_routedFifoStreamSources_ms(InStreamIndex, OutStreamIndex).strobe;
        s_routedFifoStreamSources_sm(InStreamIndex, OutStreamIndex).ready <= requestGrantedMask(InStreamIndex) and s_outStageStreams_sm(OutStreamIndex).ready;
      end generate generate_requestValidMask;      
      i_arbiter : entity work.UtilArbiter
      generic map (g_PortCount => g_NumInStreamPorts)
      port map (
        pi_clk        => ai_sys.clk,
        pi_rst_n      => ai_sys.rst_n,
        pi_request    => requestValidMask,
        po_grant      => requestGrantedMask,
        po_port       => grantedPort,
        po_active     => open,
        pi_next       => s_outStageStreams_sm(OutStreamIndex).ready
      );
      s_outStageStreams_ms(OutStreamIndex).data <= s_routedFifoStreamSources_ms(to_integer(grantedPort), OutStreamIndex).data;
      s_outStageStreams_ms(OutStreamIndex).strobe <= s_routedFifoStreamSources_ms(to_integer(grantedPort), OutStreamIndex).strobe and f_or(requestGrantedMask);    
    
      i_pipelineStageOut : entity work.PipelineStage
      generic map(
        s_outStageStreams_ms(OutStreamIndex).data'length
      )
      port map(
          pi_clk        => ai_sys.clk,
          pi_rst_n      => ai_sys.rst_n,       
          pi_inData     => s_outStageStreams_ms(OutStreamIndex).data, 
          pi_inValid    => s_outStageStreams_ms(OutStreamIndex).strobe,
          po_inReady    => s_outStageStreams_sm(OutStreamIndex).ready,
{{?x_pm_streamMasters.type.x_is_sink}}         
          po_outData({{x_ps_streamSlaves.type.x_tdata.x_width}} - 1 downto 0)     => as_streamSlaves_sm(OutStreamIndex).data, 
{{?x_ps_streamSlaves.type.x_has_id}}
          po_outData(c_SlaveDataWidth - 1 downto {{x_ps_streamSlaves.type.x_tdata.x_width}})    => as_streamSlaves_sm(OutStreamIndex).id,
{{/x_ps_streamSlaves.type.x_has_id}}          
          po_outValid    => as_streamSlaves_sm(OutStreamIndex).ready,
          pi_outReady    => as_streamSlaves_ms(OutStreamIndex).strobe
{{|x_pm_streamMasters.type.x_is_sink}}
          po_outData({{x_pm_streamMasters.type.x_tdata.x_width}} - 1 downto 0)     => am_streamMasters_ms(OutStreamIndex).data, 
{{?x_pm_streamMasters.type.x_has_id}}
          po_outData(c_MasterDataWidth - 1 downto {{x_pm_streamMasters.type.x_tdata.x_width}})    => am_streamMasters_ms(OutStreamIndex).id,
{{/x_pm_streamMasters.type.x_has_id}}              
          po_outValid    => am_streamMasters_ms(OutStreamIndex).strobe,
          pi_outReady    => am_streamMasters_sm(OutStreamIndex).ready
{{/x_pm_streamMasters.type.x_is_sink}});
    end generate out_streams;
  end StreamCrossbar;