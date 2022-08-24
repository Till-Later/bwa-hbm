library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util.all;


entity Sim_Sysenv is
  generic (
    g_ClockPeriod : time := 2 ns;
    g_ResetDelay  : time := 20 ns;
    g_StopDelay   : time := 100 ns);
  port (
    po_clk   : out std_logic;
    po_rst_n : out std_logic;
    pi_stop  : in  std_logic := '1');
end Sim_Sysenv;

architecture Sim_Sysenv of Sim_Sysenv is

  constant c_ClockDelay : time := g_ClockPeriod / 2;

  signal s_clk      : std_logic := '1';
  signal s_rst_n    : std_logic := '0';

begin

  s_clk <= not s_clk after c_ClockDelay;

  s_rst_n <= '1' after g_ResetDelay;

  process
  begin
    wait until pi_stop = '1';
    wait for g_StopDelay;
    report "End Simulation." severity failure;
  end process;

  po_clk <= s_clk;

  po_rst_n <= s_rst_n;

end Sim_Sysenv;
