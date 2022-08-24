library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

Library xpm;
use xpm.vcomponents.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}

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

architecture SequenceBufferURAM of {{identifier}} is
    alias ai_sys is {{x_psys.identifier}};
    alias as_sequenceRd_ms is {{x_ps_sequenceRd.identifier_ms}};
    alias as_sequenceRd_sm is {{x_ps_sequenceRd.identifier_sm}};
    alias as_sequenceWr_ms is {{x_ps_sequenceWr.identifier_ms}};
    alias as_sequenceWr_sm is {{x_ps_sequenceWr.identifier_sm}};

    signal dina : std_logic_vector({{x_ps_sequenceWr.type.x_tdata.x_width}} - 1 downto 0);
    signal doutb : std_logic_vector({{x_ps_sequenceRd.type.x_tdata.x_width}} - 1 downto 0);

    signal addra : std_logic_vector({{x_ps_sequenceWr.type.x_taddr.x_width}} - 1 downto 0);
    signal addrb : std_logic_vector({{x_ps_sequenceRd.type.x_taddr.x_width}} - 1 downto 0);


    signal ena : std_logic;
    signal enb : std_logic;

    signal wea : std_logic_vector(0 downto 0);
begin

  process (ai_sys.clk)
  begin
      if ai_sys.clk'event and ai_sys.clk = '1' then
          addra <= std_logic_vector(as_sequenceWr_ms.addr);
          dina <= std_logic_vector(as_sequenceWr_ms.wdata);
          ena <= as_sequenceWr_ms.strobe;
          wea <= (0 => as_sequenceWr_ms.write);
      end if;
  end process;

  as_sequenceRd_sm.rdata <= unsigned(doutb);
  addrb <= std_logic_vector(as_sequenceRd_ms.addr);
  enb <= as_sequenceRd_ms.strobe;

  -- Xilinx Parameterized Macro, version 2018.1
  xpm_memory_spram_inst : xpm_memory_sdpram
  generic map (
      ADDR_WIDTH_A => {{x_ps_sequenceWr.type.x_taddr.x_width}}, -- DECIMAL
      ADDR_WIDTH_B => {{x_ps_sequenceRd.type.x_taddr.x_width}}, -- DECIMAL
      AUTO_SLEEP_TIME => 0, -- DECIMAL
      BYTE_WRITE_WIDTH_A => {{x_ps_sequenceWr.type.x_tdata.x_width}}, --integer; 8, 9, or WRITE_DATA_WIDTH_A value
      CLOCKING_MODE => "common_clock", -- String
      ECC_MODE => "no_ecc", -- String
      MEMORY_INIT_FILE => "none", -- String
      MEMORY_INIT_PARAM => "0", -- String
      MEMORY_OPTIMIZATION => "false", -- String
      MEMORY_PRIMITIVE => "ultra", -- String
      MEMORY_SIZE => {{x_ps_sequenceWr.type.x_tdata.x_width}} * (2 ** {{x_ps_sequenceWr.type.x_taddr.x_width}}),
      MESSAGE_CONTROL => 0, -- DECIMAL
      READ_DATA_WIDTH_B => {{x_ps_sequenceRd.type.x_tdata.x_width}}, -- DECIMAL
      READ_LATENCY_B => 3, -- DECIMAL
      READ_RESET_VALUE_B => "0", -- String
      USE_MEM_INIT => 0, -- DECIMAL
      WAKEUP_TIME => "disable_sleep", -- String
      WRITE_DATA_WIDTH_A => {{x_ps_sequenceWr.type.x_tdata.x_width}}, -- DECIMAL
      WRITE_MODE_B => "read_first" -- String
  )
  port map (
      dbiterrb => open, -- 1-bit output: Status signal to indicate double bit error occurrence
      -- on the data output of port A.
      doutb => doutb, -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      sbiterrb => open, -- 1-bit output: Status signal to indicate single bit error occurrence
      -- on the data output of port A.
      addra => addra, -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      addrb => addrb,
      clka => ai_sys.clk,
      clkb => '0', -- 1-bit input: Clock signal for port A.
      dina => dina, -- WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      ena => ena, -- 1-bit input: Memory enable signal for port A. Must be high on clock
      enb => enb,
      -- cycles when read or write operations are initiated. Pipelined
      -- internally.
      injectdbiterra => '0', -- 1-bit input: Controls double bit error injection on input data when
      -- ECC enabled (Error injection capability is not available in
      -- "decode_only" mode).
      injectsbiterra => '0', -- 1-bit input: Controls single bit error injection on input data when
      -- ECC enabled (Error injection capability is not available in
      -- "decode_only" mode).
      regceb => '1', -- 1-bit input: Clock Enable for the last register stage on the output
      -- data path.
      rstb => '0', -- 1-bit input: Reset signal for the final port A output register
      -- stage. Synchronously resets output port douta to the value specified
      -- by parameter READ_RESET_VALUE_A.
      sleep => '0', -- 1-bit input: sleep signal to enable the dynamic power saving feature.
      wea => wea -- WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
      -- data port dina. 1 bit wide when word-wide writes are used. In
      -- byte-wide write configurations, each bit controls the writing one
      -- byte of dina to address addra. For example, to synchronously write
      -- only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
      -- 4'b0010.
);

end SequenceBufferURAM;
