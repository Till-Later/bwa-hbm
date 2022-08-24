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

architecture SmemBuffer of {{identifier}} is
    -- g_NumStreamPorts

    alias ai_sys is {{x_psys.identifier}};

    alias as_memPort_ms is {{x_ps_memPort.identifier_ms}};
    alias as_memPort_sm is {{x_ps_memPort.identifier_sm}};
    
    signal s_memPort_buffer_ms : {{x_ps_memPort.type.qualified_ms}};
    signal s_memPort_buffer_sm : {{x_ps_memPort.type.qualified_sm}};    

    signal s_req_source_pipelineStage_ms : {{x_ps_req_source.type.qualified_v_ms}}(g_NumStreamPorts-1 downto 0);
    signal s_req_source_pipelineStage_sm : {{x_ps_req_source.type.qualified_v_sm}}(g_NumStreamPorts-1 downto 0);

    signal s_ret_sink_pipelineStage_ms : {{x_ps_resp_sink.type.qualified_v_ms}}(g_NumStreamPorts-1 downto 0);
    signal s_ret_sink_pipelineStage_sm : {{x_ps_resp_sink.type.qualified_v_sm}}(g_NumStreamPorts-1 downto 0);

    signal s_req_data_buffer       : unsigned({{x_ps_memPort.type.x_tdata.x_width}} - 1 downto 0);
    signal s_req_addr_buffer       : unsigned({{x_ps_memPort.type.x_taddr.x_width}} - 1 downto 0);
    signal s_req_write_buffer      : std_logic;
    signal s_req_write_ack_buffer  : std_logic;
    signal s_req_strobe_buffer     : std_logic;

    signal s_ret_data_buffer       : std_logic_vector({{x_ps_memPort.type.x_tdata.x_width}} - 1 downto 0);

    type t_GrantedMaskBuffer is array (0 to (2 - 1)) of unsigned(g_NumStreamPorts - 1 downto 0);
    signal s_grantedMaskBuffer : t_GrantedMaskBuffer := (others=>(others=>'0'));

    signal requestValidMask         : unsigned(g_NumStreamPorts-1 downto 0);
    signal responseReadyMask        : unsigned(g_NumStreamPorts-1 downto 0);
    signal responseStrobeMask       : unsigned(g_NumStreamPorts-1 downto 0);
    signal requestGrantedMask       : unsigned(g_NumStreamPorts-1 downto 0);
    signal grantedPort              : unsigned(f_clog2(g_NumStreamPorts) - 1 downto 0);
    signal reqActive                : std_logic;
    signal respHandshake            : std_logic;

    signal ena                      : std_logic;
    signal enb                      : std_logic;

    signal addra : STD_LOGIC_VECTOR ({{x_ps_memPort.type.x_taddr.x_width}} - 1 downto 0);
    signal addrb : STD_LOGIC_VECTOR ({{x_ps_memPort.type.x_taddr.x_width}} - 1 downto 0);

    signal douta : STD_LOGIC_VECTOR ({{x_ps_memPort.type.x_tdata.x_width}} - 1 downto 0);
    signal doutb : STD_LOGIC_VECTOR ({{x_ps_memPort.type.x_tdata.x_width}} - 1 downto 0);

    signal dina : STD_LOGIC_VECTOR ({{x_ps_memPort.type.x_tdata.x_width}} - 1 downto 0);
    signal dinb : STD_LOGIC_VECTOR ({{x_ps_memPort.type.x_tdata.x_width}} - 1 downto 0);

    signal wea : STD_LOGIC_VECTOR(0 downto 0);
    signal web : STD_LOGIC_VECTOR(0 downto 0);

begin

    pipelineStages : for I in 0 to g_NumStreamPorts-1 generate
    begin
        i_pipelineStageIn : entity work.PipelineStage
        generic map(g_DataWidth => {{x_ps_req_source.type.x_tdata.x_width}})
        port map(
          pi_clk        => ai_sys.clk,
          pi_rst_n      => ai_sys.rst_n,
          pi_inData     => "" & {{x_ps_req_source.identifier_ms}}(I).data,
          pi_inValid    => {{x_ps_req_source.identifier_ms}}(I).strobe,
          po_inReady    => {{x_ps_req_source.identifier_sm}}(I).ready,
          po_outData    => s_req_source_pipelineStage_ms(I).data,
          po_outValid   => s_req_source_pipelineStage_ms(I).strobe,
          pi_outReady   => s_req_source_pipelineStage_sm(I).ready);

        requestValidMask(I) <= s_req_source_pipelineStage_ms(I).strobe;
        s_req_source_pipelineStage_sm(I).ready <= requestGrantedMask(I) and respHandshake;

        s_ret_sink_pipelineStage_sm(I).data   <= unsigned(s_ret_data_buffer);
        s_ret_sink_pipelineStage_sm(I).ready  <= responseReadyMask(I);
        responseStrobeMask(I) <= not responseReadyMask(I) or s_ret_sink_pipelineStage_ms(I).strobe;

        i_pipelineStageOut : entity work.PipelineStage
        generic map(g_DataWidth => {{x_ps_memPort.type.x_tdata.x_width}})
        port map(
          pi_clk        => ai_sys.clk,
          pi_rst_n      => ai_sys.rst_n,
          pi_inData     => s_ret_sink_pipelineStage_sm(I).data,
          pi_inValid    => s_ret_sink_pipelineStage_sm(I).ready, 
          po_inReady    => s_ret_sink_pipelineStage_ms(I).strobe,
          po_outData    => {{x_ps_resp_sink.identifier_sm}}(I).data,
          po_outValid   => {{x_ps_resp_sink.identifier_sm}}(I).ready,
          pi_outReady   => {{x_ps_resp_sink.identifier_ms}}(I).strobe);
    end generate pipelineStages;

    respHandshake <= f_and(responseStrobeMask);

    i_arbiter : entity work.UtilArbiter
    generic map (
      g_PortCount => g_NumStreamPorts)
    port map (
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_request    => requestValidMask,
      po_grant      => requestGrantedMask,
      po_port       => grantedPort,
      po_active     => reqActive
    );

    s_req_write_buffer      <= s_req_source_pipelineStage_ms(to_integer(grantedPort)).data(0);
    s_req_write_ack_buffer  <= s_req_source_pipelineStage_ms(to_integer(grantedPort)).data(1);
    s_req_data_buffer       <= s_req_source_pipelineStage_ms(to_integer(grantedPort)).data({{x_ps_memPort.type.x_tdata.x_width}} + 2 - 1 downto 2);
    s_req_addr_buffer       <= s_req_source_pipelineStage_ms(to_integer(grantedPort)).data({{x_ps_memPort.type.x_taddr.x_width}} + {{x_ps_memPort.type.x_tdata.x_width}} + 2 - 1 downto {{x_ps_memPort.type.x_tdata.x_width}} + 2);
    s_req_strobe_buffer     <= reqActive and respHandshake;

    responseReadyMask <= s_grantedMaskBuffer(s_grantedMaskBuffer'high);

    process (ai_sys.clk)
    begin
        if ai_sys.clk'event and ai_sys.clk = '1' then
            if ai_sys.rst_n = '0' then
                s_grantedMaskBuffer <= (others=>(others=>'0'));
            else
                if respHandshake = '1' then
                    for i in s_grantedMaskBuffer'high downto s_grantedMaskBuffer'low + 1 loop
                        s_grantedMaskBuffer(i) <= s_grantedMaskBuffer(i - 1);
                    end loop;
                    if s_req_write_buffer = '1' and s_req_write_ack_buffer = '0' then
                        s_grantedMaskBuffer(s_grantedMaskBuffer'low) <= to_unsigned(0, g_NumStreamPorts);
                    else
                        s_grantedMaskBuffer(s_grantedMaskBuffer'low) <= requestGrantedMask;
                    end if;
                end if;
            end if;
        end if;
    end process;

    ena     <= s_req_strobe_buffer;
    addra   <= std_logic_vector(s_req_addr_buffer);
    dina    <= std_logic_vector(s_req_data_buffer);
    wea(0)  <= s_req_write_buffer;
    s_ret_data_buffer <= douta;

    enb <= s_memPort_buffer_ms.strobe;
    addrb <= std_logic_vector(s_memPort_buffer_ms.addr);
{{?x_ps_memPort.type.x_has_rd}}
    as_memPort_sm.rdata <= s_memPort_buffer_sm.rdata;
{{/x_ps_memPort.type.x_has_rd}}

{{?x_ps_memPort.type.x_has_wr}}
    dinb <= std_logic_vector(s_memPort_buffer_ms.wdata);
    web(0) <= s_memPort_buffer_ms.write;
{{|x_ps_memPort.type.x_has_wr}}
    web(0) <= '0';
{{/x_ps_memPort.type.x_has_wr}}

    process (ai_sys.clk)
    begin
        if ai_sys.clk'event and ai_sys.clk = '1' then
            s_memPort_buffer_ms.addr <= as_memPort_ms.addr;
            s_memPort_buffer_ms.strobe <= as_memPort_ms.strobe;
            {{?x_ps_memPort.type.x_has_rd}}
                s_memPort_buffer_sm.rdata <= unsigned(doutb);
            {{/x_ps_memPort.type.x_has_rd}}
            {{?x_ps_memPort.type.x_has_wr}}
                s_memPort_buffer_ms.wdata <= as_memPort_ms.wdata;
                s_memPort_buffer_ms.write <= as_memPort_ms.write;
            {{/x_ps_memPort.type.x_has_wr}}
        end if;
    end process;

  -- XPM_MEMORY_TDPRAM: True Dual Port RAM
  -- Xilinx Parameterized Macro, version 2018.1
  xpm_memory_tdpram_inst : xpm_memory_tdpram
  generic map (
      ADDR_WIDTH_A => {{x_ps_memPort.type.x_taddr.x_width}}, -- DECIMAL
      ADDR_WIDTH_B => {{x_ps_memPort.type.x_taddr.x_width}}, -- DECIMAL
      AUTO_SLEEP_TIME => 0, -- DECIMAL
      BYTE_WRITE_WIDTH_A => {{x_ps_memPort.type.x_tdata.x_width}}, -- integer; 8, 9, or WRITE_DATA_WIDTH_A value
      BYTE_WRITE_WIDTH_B => {{x_ps_memPort.type.x_tdata.x_width}}, -- integer; 8, 9, or WRITE_DATA_WIDTH_B value
      CLOCKING_MODE => "common_clock", -- String
      ECC_MODE => "no_ecc", -- String
      MEMORY_INIT_FILE => "none", -- String
      MEMORY_INIT_PARAM => "0", -- String
      MEMORY_OPTIMIZATION => "true", -- String
      MEMORY_PRIMITIVE => "ultra", -- String
      MEMORY_SIZE => (2 ** {{x_ps_memPort.type.x_taddr.x_width}}) * {{x_ps_memPort.type.x_tdata.x_width}}, -- DECIMAL (bwt_interval_vector_cacheline_t::width * 64 * 64)
      MESSAGE_CONTROL => 0, -- DECIMAL
      READ_DATA_WIDTH_A => {{x_ps_memPort.type.x_tdata.x_width}}, -- DECIMAL
      READ_DATA_WIDTH_B => {{x_ps_memPort.type.x_tdata.x_width}}, -- DECIMAL
      READ_LATENCY_A => 2, -- DECIMAL
      READ_LATENCY_B => 2, -- DECIMAL
      READ_RESET_VALUE_A => "0", -- String
      READ_RESET_VALUE_B => "0", -- String
      USE_MEM_INIT => 0, -- DECIMAL
      WAKEUP_TIME => "disable_sleep", -- String
      WRITE_DATA_WIDTH_A => {{x_ps_memPort.type.x_tdata.x_width}}, -- DECIMAL
      WRITE_DATA_WIDTH_B => {{x_ps_memPort.type.x_tdata.x_width}}, -- DECIMAL
      WRITE_MODE_A => "NO_CHANGE", -- String
      WRITE_MODE_B => "NO_CHANGE" -- String
  )
  port map (
      dbiterra => open, -- 1-bit output: Status signal to indicate double bit error occurrence on the data output
      dbiterrb => open,
      douta => douta, -- READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      doutb => doutb,
      sbiterra => open, -- 1-bit output: Status signal to indicate single bit error occurrence on the data output
      sbiterrb => open,
      addra => addra, -- ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      addrb => addrb,
      clka => ai_sys.clk, -- 1-bit input: Clock signal for port A.
      clkb => ai_sys.clk, -- 1-bit input: Clock signal for port B.
      dina => dina, -- WRITE_DATA_WIDTH_B-bit input: Data input for port A write operations.
      dinb => dinb,
      ena => ena, -- 1-bit input: Memory enable signal. Must be high on clock cycles when read
      -- or write operations are initiated. Pipelined internally.
      enb => enb,
      injectdbiterra => '0', -- 1-bit input: Controls double bit error injection on input data when
      -- ECC enabled (Error injection capability is not available in
      -- "decode_only" mode).
      injectdbiterrb => '0',
      injectsbiterra => '0', -- 1-bit input: Controls single bit error injection on input data when
      -- ECC enabled (Error injection capability is not available in
      -- "decode_only" mode).
      injectsbiterrb => '0',
      regcea => '1', -- 1-bit input: Clock Enable for the last register stage on the output
      -- data path.
      regceb => '1',
      rsta => '0', -- 1-bit input: Reset signal for the final port A output register
      -- stage. Synchronously resets output port douta to the value specified
      -- by parameter READ_RESET_VALUE_A.
      rstb => '0',
      sleep => '0', -- 1-bit input: sleep signal to enable the dynamic power saving feature.
      wea => wea, -- WRITE_DATA_WIDTH_A-bit input: Write enable vector for port A input
      -- data port dina. 1 bit wide when word-wide writes are used. In
      -- byte-wide write configurations, each bit controls the writing one
      -- byte of dina to address addra. For example, to synchronously write
      -- only bits [15-8] of dina when WRITE_DATA_WIDTH_A is 32, wea would be
      -- 4'b0010.
      web => web
);

end SmemBuffer;