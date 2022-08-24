library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.interface.all;
use work.util.all;


entity Sim_StreamSink is
  generic (
    g_TotalSize : natural := 0;
    g_Bandwidth : real := 1.0;
    g_Latency   : real := 0.0);
  port (
    pi_clk   : in  std_logic;
    pi_rst_n : in  std_logic;

    pi_last  : in  std_logic;
    pi_valid : in  std_logic;
    po_ready : out std_logic;

    po_done  : out std_logic);
end Sim_StreamSink;

architecture Sim_StreamSink of Sim_StreamSink is

  constant v_id : natural := x_stmSetup(g_TotalSize, 0, g_Bandwidth, g_Latency);

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
      v_last := f_bool(pi_last);
      v_valid := f_bool(pi_valid);

      x_stmTickSnk(v_Id, v_rst, v_last, v_valid, v_ready, v_done, v_state, v_delay, v_count, v_burst);

      po_ready <= f_logic(v_ready);
      po_done <= f_logic(v_done);
      s_state <= v_state;
      s_delay <= v_delay;
      s_count <= v_count;
      s_burst <= v_burst;
    end if;
  end process;

end Sim_StreamSink;
