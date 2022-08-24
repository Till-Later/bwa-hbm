library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util.all;
use work.AxiAddrMachine;

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

architecture AxiReader of {{identifier}} is

  -- Map internal signals on templated signals
  alias ai_sys is {{x_psys.identifier}};
  alias ai_start is {{x_pi_start.identifier}};
  alias ao_ready is {{x_po_ready.identifier}};

{{^ x_pm_axiRd.type.x_is_axi}}
  report "AxiRd is not an Axi type!"; severity failure;
{{/ x_pm_axiRd.type.x_is_axi}}
  alias am_axiRd_ms is {{x_pm_axiRd.identifier_ms}};
  alias am_axiRd_sm is {{x_pm_axiRd.identifier_sm}};

{{^ x_pm_axiStm.type.x_is_axi_stream}}
  report "AxiStm is not an Axi stream type!"; severity failure;
{{/ x_pm_axiStm.type.x_is_axi_stream}}
  alias am_axiStm_ms is {{x_pm_axiStm.identifier_ms}};
  alias am_axiStm_sm is {{x_pm_axiStm.identifier_sm}};

  -- Config port (4 registers):
  --  Reg0: Start address low word
  --  Reg1: Start address high word
  --  Reg2: Transfer count
  --  Reg3: Maximum Burst length
  alias as_regs_ms is {{x_ps_reg.identifier_ms}};
  alias as_regs_sm is {{x_ps_reg.identifier_sm}};

  alias ao_status is {{x_po_status.identifier}};

  signal ai_hold : std_logic;

  signal so_ready         : std_logic;
  signal s_addrStart      : std_logic;
  signal s_addrReady      : std_logic;

  -- Address State Machine
  signal s_address        : ocaccel.t_AxiHbmWordAddr;
  signal s_count          : regPort.t_RegData;
  signal s_maxLen         : ocaccel.t_AxiHbmLen;

  -- Burst Count Queue
  signal s_queueBurstCount: ocaccel.t_AxiHbmLen;
  signal s_queueBurstLast : std_logic;
  signal s_queueValid     : std_logic;
  signal s_queueReady     : std_logic;

  -- Data State Machine
  type t_State is (Idle, ThruConsume, Thru, ThruWait);
  signal s_state          : t_State;
  signal s_burstCount     : ocaccel.t_AxiHbmLen;
  signal s_burstLast      : std_logic;
  signal so_mem_ms_rready : std_logic;

  -- Control Registers
  signal so_regs_sm_ready : std_logic;
  signal s_regAdr         : unsigned(2*regPort.t_RegData'length-1 downto 0);
  alias  a_regALo is s_regAdr(regPort.t_RegData'length-1 downto 0);
  alias  a_regAHi is s_regAdr(2*regPort.t_RegData'length-1 downto regPort.t_RegData'length);
  signal s_regCnt         : regPort.t_RegData;
  signal s_regBst         : regPort.t_RegData;

  -- Status Output
  signal s_addrStatus     : unsigned (7 downto 0);
  signal s_stateEnc       : unsigned (2 downto 0);

begin
  -- Map internal signals on constants
  ai_hold <= '0';


  s_addrStart <= so_ready and ai_start;
  so_ready <= s_addrReady and f_logic(s_state = Idle);
  ao_ready <= so_ready;

  -----------------------------------------------------------------------------
  -- Address State Machine
  -----------------------------------------------------------------------------
  am_axiRd_ms.arsize <= "101"; -- AXI_xx_ARSIZE and AXI__xx_AWSIZE signals are always 3'b101 (32-byte aligned)
  am_axiRd_ms.arburst <= "01";

  s_address <= f_resizeLeft(s_regAdr, s_address'length);
  s_count   <= s_regCnt;
  s_maxLen  <= f_resize(s_regBst, s_maxLen'length);
  i_addrMachine : entity work.AxiAddrMachine
    generic map (
      g_FIFOLogDepth => g_FIFOLogDepth)
    port map (
      pi_clk             => ai_sys.clk,
      pi_rst_n           => ai_sys.rst_n,
      pi_start           => s_addrStart,
      po_ready           => s_addrReady,
      pi_hold            => ai_hold,
      pi_address         => s_address,
      pi_count           => s_count,
      pi_maxLen          => s_maxLen,
      po_axiAAddr        => am_axiRd_ms.araddr,
      po_axiALen         => am_axiRd_ms.arlen,
      po_axiAValid       => am_axiRd_ms.arvalid,
      pi_axiAReady       => am_axiRd_sm.arready,
      po_queueBurstCount => s_queueBurstCount,
      po_queueBurstLast  => s_queueBurstLast,
      po_queueValid      => s_queueValid,
      pi_queueReady      => s_queueReady,
      po_status          => s_addrStatus);

  -----------------------------------------------------------------------------
  -- Data State Machine
  -----------------------------------------------------------------------------

  am_axiStm_ms.tdata <= am_axiRd_sm.rdata;
  with s_state select am_axiStm_ms.tkeep <=
    (others => '1')     when Thru,
    (others => '1')     when ThruConsume,
    (others => '0')     when others;
  am_axiStm_ms.tlast <= f_logic(s_burstCount = to_unsigned(0, s_burstCount'length) and s_burstLast = '1');
  with s_state select am_axiStm_ms.tvalid <=
    am_axiRd_sm.rvalid    when Thru,
    am_axiRd_sm.rvalid    when ThruConsume,
    '0'                 when others;
  with s_state select so_mem_ms_rready <=
    am_axiStm_sm.tready when Thru,
    am_axiStm_sm.tready when ThruConsume,
    '0'                 when others;
  am_axiRd_ms.rready <= so_mem_ms_rready;
  -- TODO-lw: handle rresp /= OKAY

  with s_state select s_queueReady <=
    '1' when ThruConsume,
    '0' when others;

  process (ai_sys.clk)
    variable v_beat : boolean; -- Data Channel Handshake
    variable v_bend : boolean; -- Last Data Channel Handshake in Burst
    variable v_blst : boolean; -- Last Burst
    variable v_qval : boolean; -- Queue Valid
  begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      v_beat := am_axiRd_sm.rvalid = '1' and
                so_mem_ms_rready = '1';
      v_bend := (s_burstCount = to_unsigned(0, s_burstCount'length)) and
                am_axiRd_sm.rvalid = '1' and
                so_mem_ms_rready = '1';
      v_blst := s_burstLast = '1';
      v_qval := s_queueValid = '1';

      if ai_sys.rst_n = '0' then
        s_burstCount <= (others => '0');
        s_burstLast <= '0';
        s_state  <= Idle;
      else
        case s_state is

          when Idle =>
            if v_qval then
              s_burstCount <= s_queueBurstCount;
              s_burstLast <= s_queueBurstLast;
              s_state <= ThruConsume;
            end if;

          when ThruConsume =>
            if v_beat then
              s_burstCount <= s_burstCount - to_unsigned(1, s_burstCount'length);
            end if;
            if v_bend then
              if v_blst then
                s_state <= Idle;
              else
                s_state <= ThruWait;
              end if;
            else
                s_state <= Thru;
            end if;

          when Thru =>
            if v_beat then
              s_burstCount <= s_burstCount - to_unsigned(1, s_burstCount'length);
            end if;
            if v_bend then
              if v_blst then
                s_state <= Idle;
              elsif v_qval then
                s_burstCount <= s_queueBurstCount;
                s_burstLast <= s_queueBurstLast;
                s_state <= ThruConsume;
              else
                s_state <= ThruWait;
              end if;
            end if;

          when ThruWait =>
            if v_qval then
              s_burstCount <= s_queueBurstCount;
              s_burstLast <= s_queueBurstLast;
              s_state <= ThruConsume;
            end if;

        end case;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Register Access
  -----------------------------------------------------------------------------
  as_regs_sm.ready <= so_regs_sm_ready;
  process (ai_sys.clk)
    variable v_portAddr : integer range 0 to 2**as_regs_ms.addr'length-1;
  begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      v_portAddr := to_integer(as_regs_ms.addr);

      if ai_sys.rst_n = '0' then
        as_regs_sm.rddata <= (others => '0');
        so_regs_sm_ready <= '0';
        s_regAdr <= (others => '0');
        s_regCnt <= (others => '0');
        s_regBst <= (others => '0');
      else
        if as_regs_ms.valid = '1' and so_regs_sm_ready = '0' then
          so_regs_sm_ready <= '1';
          case v_portAddr is
            when 0 =>
              as_regs_sm.rddata <= a_regALo;
              if as_regs_ms.wrnotrd = '1' then
                a_regALo <= f_byteMux(as_regs_ms.wrstrb, a_regALo, as_regs_ms.wrdata);
              end if;
            when 1 =>
              as_regs_sm.rddata <= a_regAHi;
              if as_regs_ms.wrnotrd = '1' then
                a_regAHi <= f_byteMux(as_regs_ms.wrstrb, a_regAHi, as_regs_ms.wrdata);
              end if;
            when 2 =>
              as_regs_sm.rddata <= s_regCnt;
              if as_regs_ms.wrnotrd = '1' then
                s_regCnt <= f_byteMux(as_regs_ms.wrstrb, s_regCnt, as_regs_ms.wrdata);
              end if;
            when 3 =>
              as_regs_sm.rddata <= s_regBst;
              if as_regs_ms.wrnotrd = '1' then
                s_regBst <= f_byteMux(as_regs_ms.wrstrb, s_regBst, as_regs_ms.wrdata);
              end if;
            when others =>
              as_regs_sm.rddata <= (others => '0');
          end case;
        else
          so_regs_sm_ready <= '0';
        end if;
      end if;
    end if;
  end process;


  -----------------------------------------------------------------------------
  -- Status Output
  -----------------------------------------------------------------------------
  with s_state select s_stateEnc <=
    "000" when Idle,
    "001" when Thru,
    "011" when ThruConsume,
    "010" when ThruWait;
  ao_status <= s_burstLast & s_stateEnc & f_resize(s_burstCount, 8) & s_addrStatus;

end AxiReader;
