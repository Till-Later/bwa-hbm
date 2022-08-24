library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.numeric_types;

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

architecture HlsStreamMonitor of {{name}} is
    alias ai_sys is {{x_psys.identifier}};

    alias ai_reset_counters is {{x_pi_reset_counters.identifier}};

    alias am_streamMaster_ms is {{x_pm_streamMaster.identifier_ms}};
    alias am_streamMaster_sm is {{x_pm_streamMaster.identifier_sm}};

    alias as_streamSlave_sm is {{x_ps_streamSlave.identifier_sm}};
    alias as_streamSlave_ms is {{x_ps_streamSlave.identifier_ms}};

    alias as_memRd_ms is {{x_ps_memRd.identifier_ms}};
    alias as_memRd_sm is {{x_ps_memRd.identifier_sm}};

    signal s_memRd_buffer_ms : {{x_ps_memRd.type.qualified_ms}};
    signal s_memRd_buffer_sm : {{x_ps_memRd.type.qualified_sm}};
  
    signal s_activeCycle : std_logic;
    signal s_masterStallCycle : std_logic;
    signal s_idleOrSlaveStallCycle : std_logic;

    type t_memInterface is array (integer range <>) of unsigned(7 downto 0);
    signal memInterface : t_memInterface(17 downto 0) := (others => (others => '0'));
    signal s_freezeInterface : std_logic;

    signal s_activeCyclesCounter : numeric_types.t_u64;
    signal s_masterStallCyclesCounter : numeric_types.t_u64;
    signal s_idleOrSlaveStallCyclesCounter : numeric_types.t_u64;
  begin
    process (ai_sys.clk)
    begin
        if ai_sys.clk'event and ai_sys.clk = '1' then
            s_memRd_buffer_ms.addr <= as_memRd_ms.addr;
            s_memRd_buffer_ms.strobe <= as_memRd_ms.strobe;

            as_memRd_sm.rdata <= s_memRd_buffer_sm.rdata;
        end if;
    end process;


    process (ai_sys.clk)
    begin
      if ai_sys.clk'event and ai_sys.clk = '1' then
        if ai_sys.rst_n = '0' then
            s_freezeInterface <= '0';
        else
        s_memRd_buffer_sm.rdata <= memInterface(to_integer(s_memRd_buffer_ms.addr));

            if s_memRd_buffer_ms.strobe = '1' then
                if to_integer(s_memRd_buffer_ms.addr) = memInterface'high then
                    s_freezeInterface <= '0';
                end if;

                if to_integer(s_memRd_buffer_ms.addr) = memInterface'low then
                    s_freezeInterface <= '1';
                end if;
            end if;
            
            if s_freezeInterface = '0' then
                memInterface(0) <= unsigned(s_activeCyclesCounter(7 downto 0));
                memInterface(1) <= unsigned(s_activeCyclesCounter(15 downto 8));
                memInterface(2) <= unsigned(s_activeCyclesCounter(23 downto 16));
                memInterface(3) <= unsigned(s_activeCyclesCounter(31 downto 24));
                memInterface(4) <= unsigned(s_activeCyclesCounter(39 downto 32));
                memInterface(5) <= unsigned(s_activeCyclesCounter(47 downto 40));

                memInterface(6) <= unsigned(s_masterStallCyclesCounter(7 downto 0));
                memInterface(7) <= unsigned(s_masterStallCyclesCounter(15 downto 8));
                memInterface(8) <= unsigned(s_masterStallCyclesCounter(23 downto 16));
                memInterface(9) <= unsigned(s_masterStallCyclesCounter(31 downto 24));
                memInterface(10) <= unsigned(s_masterStallCyclesCounter(39 downto 32));
                memInterface(11) <= unsigned(s_masterStallCyclesCounter(47 downto 40));

                memInterface(12) <= unsigned(s_idleOrSlaveStallCyclesCounter(7 downto 0));
                memInterface(13) <= unsigned(s_idleOrSlaveStallCyclesCounter(15 downto 8));
                memInterface(14) <= unsigned(s_idleOrSlaveStallCyclesCounter(23 downto 16));
                memInterface(15) <= unsigned(s_idleOrSlaveStallCyclesCounter(31 downto 24));
                memInterface(16) <= unsigned(s_idleOrSlaveStallCyclesCounter(39 downto 32));
                memInterface(17) <= unsigned(s_idleOrSlaveStallCyclesCounter(47 downto 40));
            end if;
        end if;
      end if;
    end process;

{{?x_pm_streamMaster.type.x_is_sink}}
    am_streamMaster_ms.strobe <= as_streamSlave_ms.strobe;

    as_streamSlave_sm.data <= am_streamMaster_sm.data;
{{?x_pm_streamMaster.type.x_has_id}}    
    as_streamSlave_sm.id    <= am_streamMaster_sm.id;
{{/x_pm_streamMaster.type.x_has_id}}    
    as_streamSlave_sm.ready <= am_streamMaster_sm.ready;
{{|x_pm_streamMaster.type.x_is_sink}}
    am_streamMaster_ms.data <= as_streamSlave_ms.data;
{{?x_ps_streamSlave.type.x_has_id}}    
    am_streamMaster_ms.id    <= as_streamSlave_ms.id;
{{/x_ps_streamSlave.type.x_has_id}}    
    am_streamMaster_ms.strobe <= as_streamSlave_ms.strobe;

    as_streamSlave_sm.ready <= am_streamMaster_sm.ready;
{{/x_pm_streamMaster.type.x_is_sink}}

    s_activeCycle <= am_streamMaster_sm.ready and as_streamSlave_ms.strobe;
    s_masterStallCycle <= am_streamMaster_sm.ready and not as_streamSlave_ms.strobe;
    s_idleOrSlaveStallCycle <= not am_streamMaster_sm.ready;

    process (ai_sys.clk)
    begin
      if ai_sys.clk'event and ai_sys.clk = '1' then
        if ai_sys.rst_n = '0' then
            s_activeCyclesCounter <= to_unsigned(0, numeric_types.t_u64'length);
            s_masterStallCyclesCounter <= to_unsigned(0, numeric_types.t_u64'length);
            s_idleOrSlaveStallCyclesCounter <= to_unsigned(0, numeric_types.t_u64'length);
        else
            if ai_reset_counters = '1' then
                s_activeCyclesCounter <= to_unsigned(0, numeric_types.t_u64'length);
                s_masterStallCyclesCounter <= to_unsigned(0, numeric_types.t_u64'length);
                s_idleOrSlaveStallCyclesCounter <= to_unsigned(0, numeric_types.t_u64'length);
            else
                if s_activeCycle ='1' then
                    s_activeCyclesCounter <= s_activeCyclesCounter + to_unsigned(1, numeric_types.t_u64'length);
                end if;
                if s_masterStallCycle ='1' then
                    s_masterStallCyclesCounter <= s_masterStallCyclesCounter + to_unsigned(1, numeric_types.t_u64'length);
                end if;
                if s_idleOrSlaveStallCycle ='1' then
                    s_idleOrSlaveStallCyclesCounter <= s_idleOrSlaveStallCyclesCounter + to_unsigned(1, numeric_types.t_u64'length);
                end if;
            end if;
        end if;
      end if;
    end process;
end HlsStreamMonitor;