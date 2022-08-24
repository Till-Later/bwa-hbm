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

architecture TdpBram of {{identifier}} is
    -- g_AddPipelineStages
    -- g_LatencyB

    alias ai_sys is {{x_psys.identifier}};
    alias as_memPortA_ms is {{x_ps_memPortA.identifier_ms}};
    alias as_memPortA_sm is {{x_ps_memPortA.identifier_sm}};
    alias as_memPortB_ms is {{x_ps_memPortB.identifier_ms}};
    alias as_memPortB_sm is {{x_ps_memPortB.identifier_sm}};

    signal dina : std_logic_vector({{x_ps_memPortA.type.x_tdata.x_width}} - 1 downto 0);
    signal dinb : std_logic_vector({{x_ps_memPortB.type.x_tdata.x_width}} - 1 downto 0);

    signal douta : std_logic_vector({{x_ps_memPortA.type.x_tdata.x_width}} - 1 downto 0);
    signal doutb : std_logic_vector({{x_ps_memPortB.type.x_tdata.x_width}} - 1 downto 0);

    signal addra : std_logic_vector({{x_ps_memPortA.type.x_taddr.x_width}} - 1 downto 0);
    signal addrb : std_logic_vector({{x_ps_memPortB.type.x_taddr.x_width}} - 1 downto 0);

    signal ena : std_logic;
    signal enb : std_logic;

    signal wea : std_logic_vector(0 downto 0);
    signal web : std_logic_vector(0 downto 0);
    
begin

    add_pipeline_stages: if g_AddPipelineStages = 1 generate
        process (ai_sys.clk)
        begin
            if ai_sys.clk'event and ai_sys.clk = '1' then
                addra <= std_logic_vector(as_memPortA_ms.addr);
                {{?x_ps_memPortA.type.x_has_rd}}
                    as_memPortA_sm.rdata <= unsigned(douta);
                {{/x_ps_memPortA.type.x_has_rd}}
                {{?x_ps_memPortA.type.x_has_wr}}
                    dina <= std_logic_vector(as_memPortA_ms.wdata);
                    wea(0) <= as_memPortA_ms.write;
                {{|x_ps_memPortA.type.x_has_wr}}
                    wea(0) <= '0';
                {{/x_ps_memPortA.type.x_has_wr}}    
                    ena <= as_memPortA_ms.strobe;
            
                addrb <= std_logic_vector(as_memPortB_ms.addr);
                {{?x_ps_memPortB.type.x_has_rd}}
                    as_memPortB_sm.rdata <= unsigned(doutb);
                {{/x_ps_memPortB.type.x_has_rd}}
                {{?x_ps_memPortB.type.x_has_wr}}
                    dinb <= std_logic_vector(as_memPortB_ms.wdata);
                    web(0) <= as_memPortB_ms.write;
                {{|x_ps_memPortB.type.x_has_wr}}
                    web(0) <= '0';
                {{/x_ps_memPortB.type.x_has_wr}}    
                    enb <= as_memPortB_ms.strobe;            
            end if;
        end process;          
    end generate add_pipeline_stages;

    no_pipeline_stages: if g_AddPipelineStages = 0 generate
        addra <= std_logic_vector(as_memPortA_ms.addr);
        {{?x_ps_memPortA.type.x_has_rd}}
            as_memPortA_sm.rdata <= unsigned(douta);
        {{/x_ps_memPortA.type.x_has_rd}}
        {{?x_ps_memPortA.type.x_has_wr}}
            dina <= std_logic_vector(as_memPortA_ms.wdata);
            wea(0) <= as_memPortA_ms.write;
        {{|x_ps_memPortA.type.x_has_wr}}
            wea(0) <= '0';
        {{/x_ps_memPortA.type.x_has_wr}}    
            ena <= as_memPortA_ms.strobe;

            addrb <= std_logic_vector(as_memPortB_ms.addr);
        {{?x_ps_memPortB.type.x_has_rd}}
            as_memPortB_sm.rdata <= unsigned(doutb);
        {{/x_ps_memPortB.type.x_has_rd}}
        {{?x_ps_memPortB.type.x_has_wr}}
            dinb <= std_logic_vector(as_memPortB_ms.wdata);
            web(0) <= as_memPortB_ms.write;
        {{|x_ps_memPortB.type.x_has_wr}}
            web(0) <= '0';
        {{/x_ps_memPortB.type.x_has_wr}}    
            enb <= as_memPortB_ms.strobe;
    end generate no_pipeline_stages;

  -- Xilinx Parameterized Macro, version 2018.1
  xpm_memory_tdpram_inst : xpm_memory_tdpram
  generic map (
      ADDR_WIDTH_A => {{x_ps_memPortA.type.x_taddr.x_width}},
      ADDR_WIDTH_B => {{x_ps_memPortB.type.x_taddr.x_width}},
      AUTO_SLEEP_TIME => 0,
      BYTE_WRITE_WIDTH_A => {{x_ps_memPortA.type.x_tdata.x_width}},
      BYTE_WRITE_WIDTH_B => {{x_ps_memPortB.type.x_tdata.x_width}},
      CLOCKING_MODE => "common_clock",
      ECC_MODE => "no_ecc",
      MEMORY_INIT_FILE => "none",
      MEMORY_INIT_PARAM => "0",
      MEMORY_OPTIMIZATION => "false",
      MEMORY_PRIMITIVE => "block",
      MEMORY_SIZE => (2 ** {{x_ps_memPortA.type.x_taddr.x_width}}) * {{x_ps_memPortA.type.x_tdata.x_width}},
      MESSAGE_CONTROL => 0,
      READ_DATA_WIDTH_A => {{x_ps_memPortA.type.x_tdata.x_width}},
      READ_DATA_WIDTH_B => {{x_ps_memPortB.type.x_tdata.x_width}},
      READ_LATENCY_A => 1,
      READ_LATENCY_B => g_LatencyB,
      READ_RESET_VALUE_A => "0",
      READ_RESET_VALUE_B => "0",
      USE_MEM_INIT => 0,
      WAKEUP_TIME => "disable_sleep",
      WRITE_DATA_WIDTH_A => {{x_ps_memPortA.type.x_tdata.x_width}},
      WRITE_DATA_WIDTH_B => {{x_ps_memPortB.type.x_tdata.x_width}},
      WRITE_MODE_A => "read_first",
      WRITE_MODE_B => "read_first"
  )
  port map (
      dbiterra => open,
      dbiterrb => open,
      douta => douta,
      doutb => doutb,
      sbiterra => open,
      sbiterrb => open,
      addra => addra,
      addrb => addrb,
      clka => ai_sys.clk,
      clkb => '0',
      dina => dina,
      dinb => dinb,
      ena => ena,
      enb => enb,
      injectdbiterra => '0',
      injectdbiterrb => '0',
      injectsbiterra => '0',
      injectsbiterrb => '0',
      regcea => '1',
      regceb => '1',
      rsta => '0',
      rstb => '0',
      sleep => '0',
      wea => wea,
      web => web
  );

end TdpBram;
