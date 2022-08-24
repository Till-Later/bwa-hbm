library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_axi.all;
use work.fosi_util.all;


entity AxiWrMultiplexer is
  generic (
    g_PortCount    : positive;
    g_FIFOLogDepth : natural);
  port (
    pi_clk       : in  std_logic;
    pi_rst_n     : in  std_logic;

    po_axiWr_ms  : out t_NativeAxiWr_ms;
    pi_axiWr_sm  : in  t_NativeAxiWr_sm;

    pi_axiWrs_ms : in  t_NativeAxiWr_v_ms(g_PortCount-1 downto 0);
    po_axiWrs_sm : out t_NativeAxiWr_v_sm(g_PortCount-1 downto 0));
end AxiWrMultiplexer;

architecture AxiWrMultiplexer of AxiWrMultiplexer is

  subtype t_PortVector is unsigned (g_PortCount-1 downto 0);
  constant c_PortNumberWidth : natural := f_clog2(g_PortCount);
  subtype t_PortNumber is unsigned (c_PortNumberWidth-1 downto 0);

  -- Separate Address, Write and Response Channels:
  signal so_masterA_od   : t_NativeAxiA_od;
  signal si_masterA_do   : t_NativeAxiA_do;
  signal so_masterW_od   : t_NativeAxiW_od;
  signal si_masterW_do   : t_NativeAxiW_do;
  signal so_masterB_do   : t_NativeAxiB_do;
  signal si_masterB_od   : t_NativeAxiB_od;

  signal si_slavesA_od   : t_NativeAxiA_v_od(g_PortCount-1 downto 0);
  signal so_slavesA_do   : t_NativeAxiA_v_do(g_PortCount-1 downto 0);
  signal si_slavesW_od   : t_NativeAxiW_v_od(g_PortCount-1 downto 0);
  signal so_slavesW_do   : t_NativeAxiW_v_do(g_PortCount-1 downto 0);
  signal si_slavesB_do   : t_NativeAxiB_v_do(g_PortCount-1 downto 0);
  signal so_slavesB_od   : t_NativeAxiB_v_od(g_PortCount-1 downto 0);

  -- Address/Write Channel Arbiter and Switches:
  signal s_arbitRequest  : t_PortVector;
  signal s_arbitPort     : t_PortNumber;
  signal s_arbitValid   : std_logic;
  signal s_arbitReady     : std_logic;

  signal s_barDone       : unsigned(2 downto 0);
  alias a_barDoneA is s_barDone(0);
  alias a_barDoneW is s_barDone(1);
  alias a_barDoneB is s_barDone(2);
  signal s_barMask       : unsigned(2 downto 0);
  alias a_barMaskA is s_barMask(0);
  alias a_barMaskW is s_barMask(1);
  alias a_barMaskB is s_barMask(2);
  signal s_barContinue   : std_logic;

  signal s_switchAEnable : std_logic;
  signal s_switchASelect : t_PortNumber;
  signal s_slavesAValid  : t_PortVector;

  -- Write Channel FIFO and Switch:
  signal s_fifoWInReady  : std_logic;
  signal s_fifoWInValid  : std_logic;

  signal s_fifoWOutPort  : t_PortNumber;
  signal s_fifoWOutReady : std_logic;
  signal s_fifoWOutValid : std_logic;

  signal s_switchWEnable : std_logic;
  signal s_switchWSelect : t_PortNumber;

  -- Response Channel FIFO and Switch:
  signal s_fifoBInValid  : std_logic;
  signal s_fifoBInReady  : std_logic;

  signal s_fifoBOutPort  : t_PortNumber;
  signal s_fifoBOutValid : std_logic;
  signal s_fifoBOutReady : std_logic;

  signal s_switchBEnable : std_logic;
  signal s_switchBSelect : t_PortNumber;

begin

  -- Separate Address, Write and Response Channels:
  process (pi_axiWr_sm, so_masterA_od, so_masterW_od, so_masterB_do,
           pi_axiWrs_ms, so_slavesA_do, so_slavesW_do, so_slavesB_od)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    po_axiWr_ms <= f_nativeAxiWrJoin_ms(so_masterA_od, so_masterW_od, so_masterB_do);
    si_masterA_do <= f_nativeAxiWrSplitA_sm(pi_axiWr_sm);
    si_masterW_do <= f_nativeAxiWrSplitW_sm(pi_axiWr_sm);
    si_masterB_od <= f_nativeAxiWrSplitB_sm(pi_axiWr_sm);
    for v_idx in 0 to g_PortCount-1 loop
      po_axiWrs_sm(v_idx) <= f_nativeAxiWrJoin_sm(so_slavesA_do(v_idx), so_slavesW_do(v_idx), so_slavesB_od(v_idx));
      si_slavesA_od(v_idx) <= f_nativeAxiWrSplitA_ms(pi_axiWrs_ms(v_idx));
      si_slavesW_od(v_idx) <= f_nativeAxiWrSplitW_ms(pi_axiWrs_ms(v_idx));
      si_slavesB_do(v_idx) <= f_nativeAxiWrSplitB_ms(pi_axiWrs_ms(v_idx));
    end loop;
  end process;

  -- Address Channel Arbiter:
  s_arbitRequest <= s_slavesAValid;
  s_arbitReady <= s_barContinue;
  i_arbiter : entity work.UtilStableArbiter
    generic map (
      g_PortCount => g_PortCount)
    port map (
      pi_clk      => pi_clk,
      pi_rst_n    => pi_rst_n,
      pi_request  => s_arbitRequest,
      po_port     => s_arbitPort,
      po_valid    => s_arbitValid,
      pi_ready    => s_arbitReady);

  i_barrier : entity work.UtilBarrier
    generic map (
      g_Count => 3)
    port map (
      pi_clk => pi_clk,
      pi_rst_n => pi_rst_n,
      pi_signal => s_barDone,
      po_mask => s_barMask,
      po_continue => s_barContinue);

  -- Address Channel Switch
  s_switchAEnable <= s_arbitValid and not a_barMaskA;
  s_switchASelect <= s_arbitPort;
  a_barDoneA <= so_masterA_od.valid and si_masterA_do.ready;
  process (s_switchAEnable, s_switchASelect, si_slavesA_od, si_masterA_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterA_od <= c_NativeAxiANull_od;
    for v_idx in 0 to g_PortCount-1 loop
      s_slavesAValid(v_idx) <= si_slavesA_od(v_idx).valid;
      so_slavesA_do(v_idx) <= c_NativeAxiANull_do;
      if s_switchAEnable = '1' and
          v_idx = to_integer(s_switchASelect) then
        so_masterA_od <= si_slavesA_od(v_idx);
        so_slavesA_do(v_idx) <= si_masterA_do;
      end if;
    end loop;
  end process;

  -- Write Channel FIFO:
  s_fifoWInValid <= s_arbitValid and not a_barMaskW;
  a_barDoneW <= s_fifoWInValid and s_fifoWInReady;
  i_fifoW : entity work.UtilFastFIFO
    generic map (
      g_DataWidth => c_PortNumberWidth,
      g_LogDepth  => g_FIFOLogDepth)
    port map (
      pi_clk      => pi_clk,
      pi_rst_n    => pi_rst_n,
      pi_inData   => s_arbitPort,
      pi_inValid  => s_fifoWInValid,
      po_inReady  => s_fifoWInReady,
      po_outData  => s_fifoWOutPort,
      po_outValid => s_fifoWOutValid,
      pi_outReady => s_fifoWOutReady);

  -- Write Channel Switch
  s_switchWEnable <= s_fifoWOutValid;
  s_switchWSelect <= s_fifoWOutPort;
  s_fifoWOutReady <= so_masterW_od.valid and so_masterW_od.last and si_masterW_do.ready;
  process (s_switchWEnable, s_switchWSelect, si_slavesW_od, si_masterW_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterW_od <= c_NativeAxiWNull_od;
    for v_idx in 0 to g_PortCount-1 loop
      so_slavesW_do(v_idx) <= c_NativeAxiWNull_do;
      if s_switchWEnable = '1' and
          v_idx = to_integer(s_switchWSelect) then
        so_masterW_od <= si_slavesW_od(v_idx);
        so_slavesW_do(v_idx) <= si_masterW_do;
      end if;
    end loop;
  end process;

  -- Response Channel FIFO:
  s_fifoBInValid <= s_arbitValid and not a_barMaskB;
  a_barDoneB <= s_fifoBInValid and s_fifoBInReady;
  i_fifoB : entity work.UtilFastFIFO
    generic map (
      g_DataWidth => c_PortNumberWidth,
      g_LogDepth  => g_FIFOLogDepth)
    port map (
      pi_clk      => pi_clk,
      pi_rst_n    => pi_rst_n,
      pi_inData   => s_arbitPort,
      pi_inValid  => s_fifoBInValid,
      po_inReady  => s_fifoBInReady,
      po_outData  => s_fifoBOutPort,
      po_outValid => s_fifoBOutValid,
      pi_outReady => s_fifoBOutReady);

  -- Response Channel Switch
  s_switchBEnable <= s_fifoBOutValid;
  s_switchBSelect <= s_fifoBOutPort;
  s_fifoBOutReady <= si_masterB_od.valid and so_masterB_do.ready;
  process (s_switchBEnable, s_switchBSelect, si_masterB_od, si_slavesB_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterB_do <= c_NativeAxiBNull_do;
    for v_idx in 0 to g_PortCount-1 loop
      so_slavesB_od(v_idx) <= c_NativeAxiBNull_od;
      if s_switchBEnable = '1' and
          v_idx = to_integer(s_switchBSelect) then
        so_masterB_do <= si_slavesB_do(v_idx);
        so_slavesB_od(v_idx) <= si_masterB_od;
      end if;
    end loop;
  end process;

end AxiWrMultiplexer;
