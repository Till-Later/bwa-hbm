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

architecture MemoryReadBusArbiter of {{identifier}} is
    -- g_NumBusPorts
    -- g_MemoryLatency
    alias ai_sys is {{x_psys.identifier}};

    alias am_memRd_ms is {{x_pm_memRd.identifier_ms}};
    alias am_memRd_sm is {{x_pm_memRd.identifier_sm}};

    signal s_busPorts_pipelineStage_ms : {{x_ps_busPorts.type.qualified_v_ms}}(g_NumBusPorts-1 downto 0);
    signal s_busPorts_pipelineStage_sm : {{x_ps_busPorts.type.qualified_v_sm}}(g_NumBusPorts-1 downto 0);

    signal s_memRd_buffer_ms : {{x_pm_memRd.type.qualified_ms}};
    signal s_memRd_buffer_sm : {{x_pm_memRd.type.qualified_sm}};

    signal requestValidMask         : unsigned(g_NumBusPorts-1 downto 0);
    signal responseReadyMask        : unsigned(g_NumBusPorts-1 downto 0);
    signal responseStrobeMask       : unsigned(g_NumBusPorts-1 downto 0);
    signal requestGrantedMask       : unsigned(g_NumBusPorts-1 downto 0);
    signal grantedPort              : unsigned(f_clog2(g_NumBusPorts) - 1 downto 0);
    signal reqActive                : std_logic;
    signal respReady                : std_logic;

    type t_GrantedMaskBuffer is array (0 to (g_MemoryLatency - 1)) of unsigned(g_NumBusPorts - 1 downto 0);
    signal s_grantedMaskBuffer : t_GrantedMaskBuffer := (others=>(others=>'0'));
begin
    pipelineStages : for I in 0 to g_NumBusPorts-1 generate
        i_pipelineStageIn : entity work.PipelineStage
        generic map(g_DataWidth => {{x_ps_busPorts.type.x_taddr.x_width}})
        port map(
          pi_clk        => ai_sys.clk,
          pi_rst_n      => ai_sys.rst_n,
          pi_inData     => {{x_ps_busPorts.identifier_ms}}(I).req_addr,
          pi_inValid    => {{x_ps_busPorts.identifier_ms}}(I).req_strobe,
          po_inReady    => {{x_ps_busPorts.identifier_sm}}(I).req_ready,
          po_outData    => s_busPorts_pipelineStage_ms(I).req_addr,
          po_outValid   => s_busPorts_pipelineStage_ms(I).req_strobe,
          pi_outReady   => s_busPorts_pipelineStage_sm(I).req_ready);

        requestValidMask(I) <= s_busPorts_pipelineStage_ms(I).req_strobe;
        s_busPorts_pipelineStage_sm(I).req_ready <= requestGrantedMask(I) and respReady;

        s_busPorts_pipelineStage_sm(I).rsp_rdata  <= s_memRd_buffer_sm.rdata;
        s_busPorts_pipelineStage_sm(I).rsp_ready  <= responseReadyMask(I);
        responseStrobeMask(I) <= not responseReadyMask(I) or s_busPorts_pipelineStage_ms(I).rsp_strobe;

        i_pipelineStageOut : entity work.PipelineStage
        generic map(g_DataWidth => {{x_pm_memRd.type.x_tdata.x_width}})
        port map(
          pi_clk        => ai_sys.clk,
          pi_rst_n      => ai_sys.rst_n,
          pi_inData     => s_busPorts_pipelineStage_sm(I).rsp_rdata,
          pi_inValid    => s_busPorts_pipelineStage_sm(I).rsp_ready,
          po_inReady    => s_busPorts_pipelineStage_ms(I).rsp_strobe,
          po_outData    => {{x_ps_busPorts.identifier_sm}}(I).rsp_rdata,
          po_outValid   => {{x_ps_busPorts.identifier_sm}}(I).rsp_ready,
          pi_outReady   => {{x_ps_busPorts.identifier_ms}}(I).rsp_strobe);
    end generate pipelineStages;

    respReady <= f_and(responseStrobeMask);

    i_arbiter : entity work.UtilArbiter
    generic map (
      g_PortCount => g_NumBusPorts)
    port map (
      pi_clk        => ai_sys.clk,
      pi_rst_n      => ai_sys.rst_n,
      pi_request    => requestValidMask,
      po_grant      => requestGrantedMask,
      po_port       => grantedPort,
      po_active     => reqActive
    );

    s_memRd_buffer_ms.addr <= s_busPorts_pipelineStage_ms(to_integer(grantedPort)).req_addr({{x_pm_memRd.type.x_taddr.x_width}} - 1 downto 0);
    s_memRd_buffer_ms.strobe  <= reqActive and respReady;

    responseReadyMask <= s_grantedMaskBuffer(s_grantedMaskBuffer'high);
    process (ai_sys.clk)
    begin
        if ai_sys.clk'event and ai_sys.clk = '1' then
          if ai_sys.rst_n = '0' then
            s_grantedMaskBuffer <= (others=>(others=>'0'));
          else
            if respReady = '1' then
                for i in s_grantedMaskBuffer'high downto s_grantedMaskBuffer'low + 1 loop
                  s_grantedMaskBuffer(i) <= s_grantedMaskBuffer(i - 1);
                end loop;
                s_grantedMaskBuffer(s_grantedMaskBuffer'low) <= requestGrantedMask;
            end if;

            am_memRd_ms.addr        <= s_memRd_buffer_ms.addr;
            am_memRd_ms.strobe      <= s_memRd_buffer_ms.strobe;
            s_memRd_buffer_sm.rdata <= am_memRd_sm.rdata;
          end if;
        end if;
    end process;
end MemoryReadBusArbiter;