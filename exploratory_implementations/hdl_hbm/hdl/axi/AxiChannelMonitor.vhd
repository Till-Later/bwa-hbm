library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;


entity AxiChannelMonitor is
  generic (
    -- select master and slave handshake signals:
    --  false: pi_valid = s_mhs, pi_ready = s_shs (use for AR,AW,W,T)
    --  true: pi_vald = s_shs, pi_ready = s_mhs (use for R,B)
    g_InvertHandshake : boolean;
    -- disable latency counting by always assuming an active transaction (use for T)
    g_AlwaysActive : boolean := false;
    -- select handshake signal to delimit latency period
    --  false: s_shs (latency ends with slave activity)
    --  true: s_mhs (latency ends with master activity)
    g_InvertLatency : boolean := false);
  port (
    pi_clk         : in  std_logic;
    pi_rst_n       : in  std_logic;

    pi_start       : in  std_logic;

    -- last qualifier, assume '1' for AR,AW,B (only single cycle transactions)
    pi_last        : in  std_logic := '1';
    -- valid handshake signal
    pi_valid       : in  std_logic;
    -- ready handsake signal
    pi_ready       : in  std_logic;

    po_trnCycle    : out std_logic;
    po_latCycle    : out std_logic;
    po_actCycle    : out std_logic;
    po_mstCycle    : out std_logic;
    po_sstCycle    : out std_logic;
    po_idlCycle    : out std_logic);
end AxiChannelMonitor;

architecture AxiChannelMonitor of AxiChannelMonitor is

  signal s_mhs : std_logic; -- Master Handshake Signal
  signal s_shs : std_logic; -- Slave Handshake Signal
  signal s_tre : std_logic; -- Transaction Completes (dominant over s_trb)
  signal s_trb : std_logic; -- Transaction Begins

  signal s_tac : std_logic; -- Effective Transaction Active

  signal s_lat : std_logic; -- Latency Cycle
  signal s_act : std_logic; -- Active Cycle
  signal s_mst : std_logic; -- Master Stall Cycle
  signal s_sst : std_logic; -- Slave Stall Cycle
  signal s_idl : std_logic; -- Idle Cycle

  -- State
  signal s_tra : std_logic; -- Transaction Active

begin

  s_mhs <= pi_ready when g_InvertHandshake else pi_valid;
  s_shs <= pi_valid when g_InvertHandshake else pi_ready;
  s_trb <= s_mhs    when g_InvertLatency   else s_shs;
  s_tre <= s_shs and s_mhs and pi_last;
  s_tac <= '1' when g_AlwaysActive else s_tra or s_trb;

  -- State Decoding Logic:
  -- tac mhs shs | lat act mst sst idl
  --  0   0   0  |  1   0   0   0   0
  --  0   0   1  |  1   0   0   0   0  *may not occur if shs controls trb*
  --  0   1   0  |  1   0   0   0   0  *may not occur if mhs controls trb*
  --  0   1   1  |  1   0   0   0   0  *never occurs as mhs or shs controls trb*
  --  1   0   0  |  0   0   0   0   1
  --  1   0   1  |  0   0   1   0   0
  --  1   1   0  |  0   0   0   1   0
  --  1   1   1  |  0   1   0   0   0
  s_lat <= not s_tac;
  s_act <= s_tac and     s_mhs and     s_shs;
  s_mst <= s_tac and not s_mhs and     s_shs;
  s_sst <= s_tac and     s_mhs and not s_shs;
  s_idl <= s_tac and not s_mhs and not s_shs;

  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' or pi_start = '1' or s_tre = '1' then
        s_tra <= '0';
      elsif s_trb = '1' then
        s_tra <= '1';
      end if;
    end if;
  end process;

  po_trnCycle <= s_tre;
  po_latCycle <= s_lat;
  po_actCycle <= s_act;
  po_mstCycle <= s_mst;
  po_sstCycle <= s_sst;
  po_idlCycle <= s_idl;

end AxiChannelMonitor;
