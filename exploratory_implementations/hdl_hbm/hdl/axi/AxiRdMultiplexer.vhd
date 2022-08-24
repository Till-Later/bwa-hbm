library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

  use work.fosi_axi.all;
  use work.fosi_util.all;


entity AxiRdMultiplexer is
  generic (
    g_PortCount    : positive;
    g_FIFOLogDepth : natural);
  port (
    pi_clk       : in  std_logic;
    pi_rst_n     : in  std_logic;

    po_axiRd_ms  : out t_NativeAxiRd_ms;
    pi_axiRd_sm  : in  t_NativeAxiRd_sm;

    pi_axiRds_ms : in  t_NativeAxiRd_v_ms(g_PortCount-1 downto 0);
    po_axiRds_sm : out t_NativeAxiRd_v_sm(g_PortCount-1 downto 0));
end AxiRdMultiplexer;

architecture AxiRdMultiplexer of AxiRdMultiplexer is

  subtype t_PortVector is unsigned (g_PortCount-1 downto 0);
  constant c_PortNumberWidth : natural := f_clog2(g_PortCount);
  subtype t_PortNumber is unsigned (c_PortNumberWidth-1 downto 0);

  -- Separate Address and Read Channels:
  signal so_masterA_od   : t_NativeAxiA_od;
  signal si_masterA_do   : t_NativeAxiA_do;
  signal so_masterR_do   : t_NativeAxiR_do;
  signal si_masterR_od   : t_NativeAxiR_od;

  signal si_slavesA_od   : t_NativeAxiA_v_od(g_PortCount-1 downto 0);
  signal so_slavesA_do   : t_NativeAxiA_v_do(g_PortCount-1 downto 0);
  signal si_slavesR_do   : t_NativeAxiR_v_do(g_PortCount-1 downto 0);
  signal so_slavesR_od   : t_NativeAxiR_v_od(g_PortCount-1 downto 0);

  -- Address Channel Arbiter and Switch:
  signal s_arbitRequest  : t_PortVector;
  signal s_arbitPort     : t_PortNumber;
  signal s_arbitValid   : std_logic;
  signal s_arbitReady     : std_logic;

  signal s_barDone       : unsigned(1 downto 0);
  alias a_barDoneA is s_barDone(0);
  alias a_barDoneR is s_barDone(1);
  signal s_barMask       : unsigned(1 downto 0);
  alias a_barMaskA is s_barMask(0);
  alias a_barMaskR is s_barMask(1);
  signal s_barContinue   : std_logic;

  signal s_switchAEnable : std_logic;
  signal s_switchASelect : t_PortNumber;
  signal s_slavesAValid  : t_PortVector;

  -- Read Channel FIFO and Switch:
  signal s_fifoRInReady  : std_logic;
  signal s_fifoRInValid  : std_logic;

  signal s_fifoROutPort  : t_PortNumber;
  signal s_fifoROutReady : std_logic;
  signal s_fifoROutValid : std_logic;

  signal s_switchREnable : std_logic;
  signal s_switchRSelect : t_PortNumber;

begin

  -- Separate NativeAxiRd Address and Read Channels:
  process (pi_axiRd_sm, so_masterA_od, so_masterR_do,
           pi_axiRds_ms, so_slavesA_do, so_slavesR_od)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    po_axiRd_ms <= f_nativeAxiRdJoin_ms(so_masterA_od, so_masterR_do);
    si_masterA_do <= f_nativeAxiRdSplitA_sm(pi_axiRd_sm);
    si_masterR_od <= f_nativeAxiRdSplitR_sm(pi_axiRd_sm);
    for v_idx in 0 to g_PortCount-1 loop
      po_axiRds_sm(v_idx) <= f_nativeAxiRdJoin_sm(so_slavesA_do(v_idx), so_slavesR_od(v_idx));
      si_slavesA_od(v_idx) <= f_nativeAxiRdSplitA_ms(pi_axiRds_ms(v_idx));
      si_slavesR_do(v_idx) <= f_nativeAxiRdSplitR_ms(pi_axiRds_ms(v_idx));
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
      g_Count => 2)
    port map (
      pi_clk => pi_clk,
      pi_rst_n => pi_rst_n,
      pi_signal => s_barDone,
      po_mask => s_barMask,
      po_continue => s_barContinue);


  -- Address Channel Switch:
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

  -- Read Channel FIFO:
  s_fifoRInValid <= s_arbitValid and not a_barMaskR;
  a_barDoneR <= s_fifoRInValid and s_fifoRInReady;
  i_fifoR : entity work.UtilFastFIFO
    generic map (
      g_DataWidth => c_PortNumberWidth,
      g_LogDepth  => g_FIFOLogDepth)
    port map (
      pi_clk      => pi_clk,
      pi_rst_n    => pi_rst_n,
      pi_inData   => s_arbitPort,
      pi_inValid  => s_fifoRInValid,
      po_inReady  => s_fifoRInReady,
      po_outData  => s_fifoROutPort,
      po_outValid => s_fifoROutValid,
      pi_outReady => s_fifoROutReady);

  -- Read Channel Switch:
  s_switchREnable <= s_fifoROutValid;
  s_switchRSelect <= s_fifoROutPort;
  s_fifoROutReady <= si_masterR_od.valid and si_masterR_od.last and so_masterR_do.ready;
  process (s_switchREnable, s_switchRSelect, si_masterR_od, si_slavesR_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterR_do <= c_NativeAxiRNull_do;
    for v_idx in 0 to g_PortCount-1 loop
      so_slavesR_od(v_idx) <= c_NativeAxiRNull_od;
      if s_switchREnable = '1' and
          v_idx = to_integer(s_switchRSelect) then
        so_masterR_do <= si_slavesR_do(v_idx);
        so_slavesR_od(v_idx) <= si_masterR_od;
      end if;
    end loop;
  end process;

end AxiRdMultiplexer;
