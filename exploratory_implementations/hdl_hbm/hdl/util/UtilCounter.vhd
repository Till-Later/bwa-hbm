library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;


entity UtilCounter is
  generic (
    g_CounterWidth : integer := 48;
    g_IncrementWidth : integer := 1);
  port (
    pi_clk         : in  std_logic;
    pi_rst_n       : in  std_logic;

    pi_reset       : in  std_logic;
    pi_enable      : in  std_logic;
    pi_increment   : in  unsigned(g_IncrementWidth-1 downto 0);

    po_count       : out unsigned(g_CounterWidth-1 downto 0));
end UtilCounter;

architecture UtilCounter of UtilCounter is

  subtype t_Counter is unsigned(g_CounterWidth-1 downto 0);
  signal s_count : t_Counter;

begin

  process(pi_clk)
    variable v_inc : t_Counter;
  begin
    if pi_clk'event and pi_clk = '1' then
      v_inc   := f_resize(pi_increment, t_Counter'length);
      if pi_rst_n = '0' or pi_reset = '1' then
        s_count <= (others => '0');
      elsif pi_enable = '1' then
        s_count <= s_count + f_resize(pi_increment, s_count'length);
      end if;
    end if;
  end process;

  po_count <= s_count;

end UtilCounter;
