library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util.all;
use work.entry_compressor_unit;
use work.BufferController;
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

architecture BwtEntryCompressor of {{identifier}} is    
  constant c_numCounts : integer := 2;
  constant c_countWidth : integer := 8;
  constant c_retInDataWidth : integer := 512;
  constant c_retOutDataWidth : integer := 4 * (34 + c_numCounts * c_countWidth);
  constant c_IdWidth : integer := 
    {{?x_pm_reqStreamMaster.type.x_is_sink}}
      {{x_ps_reqStreamSlave.type.x_tid.x_width}}
    {{|x_pm_reqStreamMaster.type.x_is_sink}}
      {{x_pm_reqStreamMaster.type.x_tid.x_width}}
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

  signal dina : std_logic_vector(c_numCounts * c_countWidth - 1 downto 0);

  signal doutb : std_logic_vector(c_numCounts * c_countWidth - 1 downto 0);

  signal addra : std_logic_vector(c_IdWidth - 1 downto 0);
  signal addrb : std_logic_vector(c_IdWidth - 1 downto 0);

  signal ena : std_logic;
  signal enb : std_logic;

  signal retPipelineStageInDataOut  : unsigned(c_retInDataWidth - 1 downto 0);
  signal retPipelineStageInIdOut    : unsigned(c_IdWidth - 1 downto 0);
  signal retPipelineStageInOutValid : std_logic;
  signal retPipelineStageInOutReady : std_logic;

  signal retPipelineStageOutDataIn  : unsigned(c_IdWidth + c_retOutDataWidth - 1 downto 0);
  signal retPipelineStageOutInValid : std_logic;
  signal retPipelineStageOutInReady : std_logic;

  signal hbm_occ_row : unsigned(256 - 1 downto 0);
  signal reference_section : unsigned(256 - 1 downto 0);
  signal reference_section_reversed : unsigned(256 - 1 downto 0);
  signal buffered_reference_section_reversed : unsigned(256 - 1 downto 0);
  signal hls_occ_row : unsigned(136 - 1 downto 0); -- 4 * 34 bits

  subtype reference_section_counter_row_t is std_logic_vector (4 * c_countWidth - 1 downto 0);
  subtype reference_section_counter_row_row_t is std_logic_vector(c_numCounts * 4 * c_countWidth - 1 downto 0);

  signal reference_section_counter_row_row : reference_section_counter_row_row_t;

  signal compressorStageBufferData : unsigned(c_IdWidth + 136 - 1 downto 0);
  signal compressorStageValid : std_logic;
  signal compressorStageReady : std_logic;
begin
  {{?x_pm_reqStreamMaster.type.x_is_sink}}
  -- data goes from master to slave
  as_reqStreamSlave_sm.data     <= am_reqStreamMaster_sm.data(am_reqStreamMaster_sm.data'length - 1 downto c_numCounts * c_countWidth);
  as_reqStreamSlave_sm.id       <= am_reqStreamMaster_sm.id;
  
  {{|x_pm_reqStreamMaster.type.x_is_sink}}
  -- data goes from slave to master
  am_reqStreamMaster_ms.data    <= as_reqStreamSlave_ms.data(as_reqStreamSlave_ms.data'length - 1 downto c_numCounts * c_countWidth);
  am_reqStreamMaster_ms.id      <= as_reqStreamSlave_ms.id;
  {{/x_pm_reqStreamMaster.type.x_is_sink}}
  as_reqStreamSlave_sm.ready    <= am_reqStreamMaster_sm.ready;
  am_reqStreamMaster_ms.strobe  <= as_reqStreamSlave_ms.strobe;  

  {{?x_pm_reqStreamMaster.type.x_is_sink}}
  addra <= std_logic_vector(am_reqStreamMaster_sm.id);
  dina  <= std_logic_vector(am_reqStreamMaster_sm.data(c_numCounts * c_countWidth - 1 downto 0));
  {{|x_pm_reqStreamMaster.type.x_is_sink}}
  addra <= std_logic_vector(as_reqStreamSlave_ms.id);
  dina  <= std_logic_vector(as_reqStreamSlave_ms.data(c_numCounts * c_countWidth - 1 downto 0));
  {{/x_pm_reqStreamMaster.type.x_is_sink}}
  ena <= as_reqStreamSlave_ms.strobe;

  i_retPipelineStageIn : entity work.PipelineStage
  generic map(c_IdWidth + c_retInDataWidth) port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,       
  {{?x_pm_retStreamMaster.type.x_is_sink}}         
      pi_inData     => am_retStreamMaster_sm.id & am_retStreamMaster_sm.data, 
      pi_inValid    => am_retStreamMaster_sm.ready,
      po_inReady    => am_retStreamMaster_ms.strobe,
  {{|x_pm_retStreamMaster.type.x_is_sink}}
      pi_inData     => as_retStreamSlave_ms.id & as_retStreamSlave_ms.data, 
      pi_inValid    => as_retStreamSlave_ms.strobe,
      po_inReady    => as_retStreamSlave_sm.ready,                    
  {{/x_pm_retStreamMaster.type.x_is_sink}}
      po_outData(c_IdWidth + c_retInDataWidth - 1 downto c_retInDataWidth)    => retPipelineStageInIdOut,
      po_outData(c_retInDataWidth - 1 downto 0)    => retPipelineStageInDataOut,
      po_outValid   => retPipelineStageInOutValid,
      pi_outReady   => retPipelineStageInOutReady);


  addrb <=std_logic_vector(retPipelineStageInIdOut);
  enb   <=retPipelineStageInOutValid and retPipelineStageInOutReady;

  reference_section <= retPipelineStageInDataOut(511 downto 256);
  
  reverse_4B_blocks: for I in 0 to (8 - 1) generate
  signal reference_subsection : unsigned(32 - 1 downto 0);
  signal reference_subsection_reversed : unsigned(32 - 1 downto 0);
  begin
    reference_subsection <= reference_section((32 * I) + 31  downto (32 * I) + 0);
    reference_section_reversed((32 * I) + 31 downto (32 * I) + 0) <= reference_subsection_reversed;

    reverse_bases: for J in 0 to (16 - 1) generate
      reference_subsection_reversed((2 * J) + 1 downto (2 * J)) <= reference_subsection((2 * (15 - J)) + 1 downto (2 * (15 - J)));
    end generate reverse_bases;

  end generate reverse_4B_blocks;
  
  hbm_occ_row <= retPipelineStageInDataOut(255 downto 0);
  hls_occ_row <= hbm_occ_row(225 downto 192) & hbm_occ_row(161 downto 128) & hbm_occ_row(97 downto 64) & hbm_occ_row(33 downto 0);
  
  i_bufferControllerCounterFetch : entity work.BufferController
  generic map(c_IdWidth + hls_occ_row'length + reference_section_reversed'length) port map(
    pi_clk        => ai_sys.clk,
    pi_rst_n      => ai_sys.rst_n,       
    pi_inData     => retPipelineStageInIdOut & hls_occ_row & reference_section_reversed, 
    pi_inValid    => retPipelineStageInOutValid,
    po_inReady    => retPipelineStageInOutReady,
    po_outData(c_IdWidth + hls_occ_row'length + reference_section_reversed'length -  1 downto reference_section_reversed'length)    => compressorStageBufferData,
    po_outData(reference_section_reversed'length -  1 downto 0)    => buffered_reference_section_reversed,
    po_outValid   => compressorStageValid,
    pi_outReady   => compressorStageReady);

    entry_compressors : for I in 0 to (c_numCounts - 1) generate
    signal k : std_logic_vector(c_countWidth - 1 downto 0);
    signal reference_section_counter_row : reference_section_counter_row_t;
    begin
      k <= doutb((I + 1) * c_countWidth - 1 downto I * c_countWidth);
      reference_section_counter_row_row((I + 1) * reference_section_counter_row'length - 1 downto I * reference_section_counter_row'length) <= reference_section_counter_row;

      i_entryCompressorUnit : entity work.entry_compressor_unit
      port map(
        pi_clk => ai_sys.clk,
        pi_inValid => compressorStageValid and compressorStageReady,
        pi_k => k,
        pi_reference_section => buffered_reference_section_reversed,
        po_reference_section_counter_row => reference_section_counter_row);    
    end generate entry_compressors;
    
  i_bufferControllerEntryCompression : entity work.BufferController
  generic map(c_IdWidth + hls_occ_row'length) port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,       
      pi_inData     => compressorStageBufferData, 
      pi_inValid    => compressorStageValid,
      po_inReady    => compressorStageReady,
      po_outData    => retPipelineStageOutDataIn(retPipelineStageOutDataIn'length - 1 downto reference_section_counter_row_row'length),
      po_outValid   => retPipelineStageOutInValid,
      pi_outReady   => retPipelineStageOutInReady);      
    
  retPipelineStageOutDataIn(reference_section_counter_row_row'length - 1 downto 0) <= unsigned(reference_section_counter_row_row);

  i_retPipelineStageOut : entity work.PipelineStage
  generic map(c_IdWidth + c_retOutDataWidth)
  port map(
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,       
      pi_inData     => retPipelineStageOutDataIn, 
      pi_inValid    => retPipelineStageOutInValid,
      po_inReady    => retPipelineStageOutInReady,
{{?x_pm_retStreamMaster.type.x_is_sink}}         
      po_outData(c_IdWidth + c_retOutDataWidth - 1 downto c_retOutDataWidth)    => as_retStreamSlave_sm.id,
      po_outData(c_retOutDataWidth - 1 downto 0)     => as_retStreamSlave_sm.data, 
      po_outValid    => as_retStreamSlave_sm.ready,
      pi_outReady    => as_retStreamSlave_ms.strobe
{{|x_pm_retStreamMaster.type.x_is_sink}}
      po_outData(c_IdWidth + c_retOutDataWidth - 1 downto c_retOutDataWidth)    => am_retStreamMaster_ms.id,
      po_outData(c_retOutDataWidth - 1 downto 0)     => am_retStreamMaster_ms.data, 
      po_outValid    => am_retStreamMaster_ms.strobe,
      pi_outReady    => am_retStreamMaster_sm.ready
{{/x_pm_retStreamMaster.type.x_is_sink}});

    -- Xilinx Parameterized Macro, version 2018.1
  xpm_memory_tdpram_inst : xpm_memory_sdpram
  generic map (
      ADDR_WIDTH_A => c_IdWidth,
      ADDR_WIDTH_B => c_IdWidth,
      AUTO_SLEEP_TIME => 0,
      BYTE_WRITE_WIDTH_A => c_numCounts * c_countWidth,
      CLOCKING_MODE => "common_clock",
      ECC_MODE => "no_ecc",
      MEMORY_INIT_FILE => "none",
      MEMORY_INIT_PARAM => "0",
      MEMORY_OPTIMIZATION => "false",
      MEMORY_PRIMITIVE => "block",
      MEMORY_SIZE => (2 ** c_IdWidth) * c_numCounts * c_countWidth,
      MESSAGE_CONTROL => 0,
      READ_DATA_WIDTH_B => c_numCounts * c_countWidth,
      READ_LATENCY_B => 1,
      READ_RESET_VALUE_B => "0",
      USE_MEM_INIT => 0,
      WAKEUP_TIME => "disable_sleep",
      WRITE_DATA_WIDTH_A => c_numCounts * c_countWidth,
      WRITE_MODE_B => "read_first"
  )
  port map (
      dbiterrb => open,
      doutb => doutb,
      sbiterrb => open,
      addra => addra,
      addrb => addrb,
      clka => ai_sys.clk,
      clkb => '0',
      dina => dina,
      ena => ena,
      enb => enb,
      injectdbiterra => '0',
      injectsbiterra => '0',
      regceb => '1',
      rstb => '0',
      sleep => '0',
      wea => "1"
  );

end BwtEntryCompressor;
