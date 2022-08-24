library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;

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

architecture StreamIdBuffer of {{identifier}} is
  constant c_PassedIdWidth : integer := 
    {{?x_pm_reqStreamMaster.type.x_is_sink}}
      {{?x_ps_reqStreamSlave.type.x_has_id}}{{x_ps_reqStreamSlave.type.x_tid.x_width}}{{|x_ps_reqStreamSlave.type.x_has_id}}0{{/x_ps_reqStreamSlave.type.x_has_id}}
    {{|x_pm_reqStreamMaster.type.x_is_sink}}
      {{?x_pm_reqStreamMaster.type.x_has_id}}{{x_pm_reqStreamMaster.type.x_tid.x_width}}{{|x_pm_reqStreamMaster.type.x_has_id}}0{{/x_pm_reqStreamMaster.type.x_has_id}}
    {{/x_pm_reqStreamMaster.type.x_is_sink}};

  constant c_BufferedIdWidth : integer := 
    {{?x_pm_reqStreamMaster.type.x_is_sink}}
      {{x_pm_reqStreamMaster.type.x_tid.x_width}} - c_PassedIdWidth
    {{|x_pm_reqStreamMaster.type.x_is_sink}}
      {{x_ps_reqStreamSlave.type.x_tid.x_width}} - c_PassedIdWidth
    {{/x_pm_reqStreamMaster.type.x_is_sink}};


  alias ai_sys is {{x_psys.identifier}};

  alias am_reqStreamMaster_ms is {{x_pm_reqStreamMaster.identifier_ms}};
  alias am_reqStreamMaster_sm is {{x_pm_reqStreamMaster.identifier_sm}};

  alias as_reqStreamSlave_ms is {{x_ps_reqStreamSlave.identifier_ms}};
  alias as_reqStreamSlave_sm is {{x_ps_reqStreamSlave.identifier_sm}};

  alias am_retStreamMaster_ms is {{x_pm_retStreamMaster.identifier_ms}};
  alias am_retStreamMaster_sm is {{x_pm_retStreamMaster.identifier_sm}};

  alias as_retStreamSlave_ms is {{x_ps_retStreamSlave.identifier_ms}};
  alias as_retStreamSlave_sm is {{x_ps_retStreamSlave.identifier_sm}};

  signal bufferedIdIn : unsigned(c_BufferedIdWidth - 1 downto 0);

  type bufferedIdOut_t is array((2 ** c_PassedIdWidth) - 1 downto 0) of unsigned(c_BufferedIdWidth - 1 downto 0);
  signal bufferedIdOut : bufferedIdOut_t;

  signal bufferedIdInReadyMask : std_logic_vector((2 ** c_PassedIdWidth) - 1 downto 0);
  signal bufferedIdOutValidMask : std_logic_vector((2 ** c_PassedIdWidth) - 1 downto 0);

  signal inHandshake : std_logic;
  signal outHandshake : std_logic;
begin
  buffer_ids : if c_BufferedIdWidth > 0 generate
    {{?x_pm_reqStreamMaster.type.x_is_sink}}
    -- data goes from master to slave
    as_reqStreamSlave_sm.data     <= am_reqStreamMaster_sm.data;
    
    bufferedIdIn                  <= am_reqStreamMaster_sm.id(am_reqStreamMaster_sm.id'length - 1 downto c_PassedIdWidth);
      {{?x_ps_reqStreamSlave.type.x_has_id}}
        as_reqStreamSlave_sm.id       <= am_reqStreamMaster_sm.id(c_PassedIdWidth - 1 downto 0);
        as_reqStreamSlave_sm.ready    <= am_reqStreamMaster_sm.ready and bufferedIdInReadyMask(to_integer(as_reqStreamSlave_sm.id));
      {{|x_ps_reqStreamSlave.type.x_has_id}}
        as_reqStreamSlave_sm.ready    <= am_reqStreamMaster_sm.ready and bufferedIdInReadyMask(0);
      {{/x_ps_reqStreamSlave.type.x_has_id}}
      
    inHandshake <= am_reqStreamMaster_sm.ready and as_reqStreamSlave_ms.strobe;
    
    {{|x_pm_reqStreamMaster.type.x_is_sink}}
    -- data goes from slave to master
    am_reqStreamMaster_ms.data    <= as_reqStreamSlave_ms.data;
    
    bufferedIdIn                  <= as_reqStreamSlave_ms.id(as_reqStreamSlave_ms.id'length - 1 downto c_PassedIdWidth);
      {{?x_pm_reqStreamMaster.type.x_has_id}}
        am_reqStreamMaster_ms.id      <= as_reqStreamSlave_ms.id(c_PassedIdWidth - 1 downto 0);
        as_reqStreamSlave_sm.ready    <= am_reqStreamMaster_sm.ready and bufferedIdInReadyMask(to_integer(am_reqStreamMaster_ms.id));
      {{|x_pm_reqStreamMaster.type.x_has_id}}
        as_reqStreamSlave_sm.ready    <= am_reqStreamMaster_sm.ready and bufferedIdInReadyMask(0);
      {{/x_pm_reqStreamMaster.type.x_has_id}}

    inHandshake <= am_reqStreamMaster_sm.ready and as_reqStreamSlave_ms.strobe;
    {{/x_pm_reqStreamMaster.type.x_is_sink}}
    am_reqStreamMaster_ms.strobe  <= as_reqStreamSlave_ms.strobe;  



    {{?x_pm_retStreamMaster.type.x_is_sink}}
    -- data goes from master to slave
    as_retStreamSlave_sm.data     <= am_retStreamMaster_sm.data;
      
      {{?x_pm_retStreamMaster.type.x_has_id}}
        as_retStreamSlave_sm.id(as_retStreamSlave_sm.id'length - 1 downto c_PassedIdWidth) <= bufferedIdOut(to_integer(am_retStreamMaster_sm.id));
        as_retStreamSlave_sm.id(c_PassedIdWidth - 1 downto 0)       <= am_retStreamMaster_sm.id;
        as_retStreamSlave_sm.ready    <= am_retStreamMaster_sm.ready and bufferedIdOutValidMask(to_integer(am_retStreamMaster_sm.id));
      {{|x_pm_retStreamMaster.type.x_has_id}}
        as_retStreamSlave_sm.id(as_retStreamSlave_sm.id'length - 1 downto c_PassedIdWidth) <= bufferedIdOut(0);
        as_retStreamSlave_sm.ready    <= am_retStreamMaster_sm.ready and bufferedIdOutValidMask(0);
      {{/x_pm_retStreamMaster.type.x_has_id}}


    outHandshake <= am_retStreamMaster_sm.ready and as_retStreamSlave_ms.strobe;
    {{|x_pm_retStreamMaster.type.x_is_sink}}
    -- data goes from slave to master
    am_retStreamMaster_ms.data    <= as_retStreamSlave_ms.data;
    
      {{?x_ps_retStreamSlave.type.x_has_id}}
        am_retStreamMaster_ms.id(am_retStreamMaster_ms.id'length - 1 downto c_PassedIdWidth) <= bufferedIdOut(to_integer(as_retStreamSlave_ms.id));
        am_retStreamMaster_ms.id(c_PassedIdWidth - 1 downto 0)       <= as_retStreamSlave_ms.id;
        as_retStreamSlave_sm.ready    <= am_retStreamMaster_sm.ready and bufferedIdOutValidMask(to_integer(as_retStreamSlave_ms.id));
      {{|x_ps_retStreamSlave.type.x_has_id}}
        am_retStreamMaster_ms.id(am_retStreamMaster_ms.id'length - 1 downto c_PassedIdWidth) <= bufferedIdOut(0);
        as_retStreamSlave_sm.ready    <= am_retStreamMaster_sm.ready and bufferedIdOutValidMask(0);
      {{/x_ps_retStreamSlave.type.x_has_id}}

    outHandshake <= am_retStreamMaster_sm.ready and as_retStreamSlave_ms.strobe;
    {{/x_pm_retStreamMaster.type.x_is_sink}}
    
    am_retStreamMaster_ms.strobe  <= as_retStreamSlave_ms.strobe;
    
    buffered_id_fifos: for ID in 0 to ((2 ** c_PassedIdWidth) - 1) generate
      signal inValid : std_logic;
      signal outReady : std_logic;
    begin
      {{?x_pm_reqStreamMaster.type.x_is_sink}}
      inValid   <= inHandshake {{?x_ps_reqStreamSlave.type.x_has_id}}when (as_reqStreamSlave_sm.id = to_unsigned(ID, c_PassedIdWidth)) else '0'{{/x_ps_reqStreamSlave.type.x_has_id}};
      {{|x_pm_reqStreamMaster.type.x_is_sink}}
      inValid   <= inHandshake {{?x_pm_reqStreamMaster.type.x_has_id}}when (am_reqStreamMaster_ms.id = to_unsigned(ID, c_PassedIdWidth)) else '0'{{/x_pm_reqStreamMaster.type.x_has_id}};            
      {{/x_pm_reqStreamMaster.type.x_is_sink}}

      {{?x_pm_retStreamMaster.type.x_is_sink}}
      outReady  <= outHandshake {{?x_pm_retStreamMaster.type.x_has_id}}when (am_retStreamMaster_sm.id = to_unsigned(ID, c_PassedIdWidth)) else '0'{{/x_pm_retStreamMaster.type.x_has_id}};
      {{|x_pm_retStreamMaster.type.x_is_sink}}
      outReady  <= outHandshake {{?x_ps_retStreamSlave.type.x_has_id}}when (as_retStreamSlave_ms.id = to_unsigned(ID, c_PassedIdWidth)) else '0'{{/x_ps_retStreamSlave.type.x_has_id}};
      {{/x_pm_retStreamMaster.type.x_is_sink}}

      i_id_fifo : entity work.UtilFastFIFO
      generic map (
        g_DataWidth => c_BufferedIdWidth,
        g_LogDepth  => c_BufferedIdWidth)
      port map (
        pi_clk      => ai_sys.clk,
        pi_rst_n    => ai_sys.rst_n,
        pi_inData   => bufferedIdIn,
        pi_inValid  => inValid,
        po_inReady  => bufferedIdInReadyMask(ID),
        po_outData  => bufferedIdOut(ID),
        po_outValid => bufferedIdOutValidMask(ID),
        pi_outReady => outReady);
    end generate buffered_id_fifos;

  end generate buffer_ids;

  resize_and_pass_ids : if c_BufferedIdWidth <= 0 generate
    {{?x_pm_reqStreamMaster.type.x_is_sink}}
    -- data goes from master to slave
    as_reqStreamSlave_sm.data     <= am_reqStreamMaster_sm.data;
    {{?x_ps_reqStreamSlave.type.x_has_id}}
    as_reqStreamSlave_sm.id       <= f_resize(am_reqStreamMaster_sm.id, as_reqStreamSlave_sm.id'length);
    {{/x_ps_reqStreamSlave.type.x_has_id}}
    {{|x_pm_reqStreamMaster.type.x_is_sink}}
    -- data goes from slave to master
    am_reqStreamMaster_ms.data    <= as_reqStreamSlave_ms.data;
    {{?x_pm_reqStreamMaster.type.x_has_id}}
    am_reqStreamMaster_ms.id      <= f_resize(as_reqStreamSlave_ms.id, am_reqStreamMaster_ms.id'length);
    {{/x_pm_reqStreamMaster.type.x_has_id}}
    {{/x_pm_reqStreamMaster.type.x_is_sink}}
    as_reqStreamSlave_sm.ready    <= am_reqStreamMaster_sm.ready;
    am_reqStreamMaster_ms.strobe  <= as_reqStreamSlave_ms.strobe;  

    {{?x_pm_retStreamMaster.type.x_is_sink}}
    -- data goes from master to slave
    as_retStreamSlave_sm.data     <= am_retStreamMaster_sm.data;
    {{?x_pm_retStreamMaster.type.x_has_id}}
    as_retStreamSlave_sm.id       <= am_retStreamMaster_sm.id(as_retStreamSlave_sm.id'length - 1 downto 0);
    {{/x_pm_retStreamMaster.type.x_has_id}}
    {{|x_pm_retStreamMaster.type.x_is_sink}}
    -- data goes from slave to master
    am_retStreamMaster_ms.data    <= as_retStreamSlave_ms.data;
    {{?x_ps_retStreamSlave.type.x_has_id}}
    am_retStreamMaster_ms.id      <= as_retStreamSlave_ms.id(am_retStreamMaster_ms.id'length - 1 downto 0);  
    {{/x_ps_retStreamSlave.type.x_has_id}}
    {{/x_pm_retStreamMaster.type.x_is_sink}}
    as_retStreamSlave_sm.ready    <= am_retStreamMaster_sm.ready;
    am_retStreamMaster_ms.strobe  <= as_retStreamSlave_ms.strobe;
  end generate resize_and_pass_ids;

end StreamIdBuffer;
