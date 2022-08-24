library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;

entity UtilBRAMSDP is
  generic (
    g_DataWidth : positive;
    g_LogDepth  : positive);
  port (
    pi_clk      : in  std_logic;
    pi_rst_n    : in  std_logic;

    pi_wraddr   : in  unsigned(g_LogDepth-1 downto 0);
    pi_wrdata   : in  unsigned(g_DataWidth-1 downto 0);
    pi_wrstrb   : in  std_logic;

    pi_rdaddr   : in  unsigned(g_LogDepth-1 downto 0);
    pi_rdstrb   : in  std_logic;
    po_rddata   : out unsigned(g_DataWidth-1 downto 0));
end UtilBRAMSDP;

architecture UtilBRAMSDP of UtilBRAMSDP is

  constant c_Depth : integer := 2**g_LogDepth;

  type t_Buffer is array(0 to c_Depth-1) of unsigned(g_DataWidth-1 downto 0);
  signal s_buffer : t_Buffer;

begin

  process(pi_clk)
    variable v_wraddr : integer range 0 to c_Depth-1;
  begin
    v_wraddr := to_integer(pi_wraddr);
    if pi_clk'event and pi_clk = '1' then
      if pi_wrstrb = '1' then
        s_buffer(v_wraddr) <= pi_wrdata;
      end if;
    end if;
  end process;

  process(pi_clk)
    variable v_rdaddr : integer range 0 to c_Depth-1;
  begin
    v_rdaddr := to_integer(pi_rdaddr);
    if pi_clk'event and pi_clk = '1' then
      if pi_rdstrb = '1' then
        po_rddata <= s_buffer(v_rdaddr);
      end if;
    end if;
  end process;

end UtilBRAMSDP;
