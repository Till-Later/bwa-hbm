library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.interface.all;
use work.util.all;


entity Sim_StreamSource is
  generic (
    g_TotalSize : natural := 0;
    g_BurstSize : natural := 0;
    g_Bandwidth : real := 1.0;
    g_Latency   : real := 0.0);
  port (
    pi_clk   : in  std_logic;
    pi_rst_n : in  std_logic;

    po_last  : out std_logic;
    po_valid : out std_logic;
    pi_ready : in  std_logic;

    po_done  : out std_logic);
end Sim_StreamSource;

architecture Sim_StreamSource of Sim_StreamSource is

  constant v_id : natural := x_stmSetup(g_TotalSize, g_BurstSize, g_Bandwidth, g_Latency);

  signal s_state : integer;
  signal s_delay : integer;
  signal s_count : integer;
  signal s_burst : integer;

begin

  process(pi_clk)
    variable v_rst   : boolean;
    variable v_last  : boolean;
    variable v_valid : boolean;
    variable v_ready : boolean;
    variable v_done  : boolean;
    variable v_state : integer;
    variable v_delay : integer;
    variable v_count : integer;
    variable v_burst : integer;
  begin
    if pi_clk'event and pi_clk = '1' then
      v_rst := not f_bool(pi_rst_n);
      v_ready := f_bool(pi_ready);

      x_stmTickSrc(v_Id, v_rst, v_last, v_valid, v_ready, v_done, v_state, v_delay, v_count, v_burst);

      po_last <= f_logic(v_last);
      po_valid <= f_logic(v_valid);
      po_done <= f_logic(v_done);
      s_state <= v_state;
      s_delay <= v_delay;
      s_count <= v_count;
      s_burst <= v_burst;
    end if;
  end process;

end Sim_StreamSource;
