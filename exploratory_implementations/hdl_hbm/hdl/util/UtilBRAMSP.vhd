library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;

entity UtilBRAMSP is
  generic (
    g_DataWidth : positive;
    g_LogDepth  : positive;
    g_RegisterOutput : boolean := false;
    g_ReadFirst : boolean := false);
  port (
    pi_clk      : in  std_logic;
    pi_rst_n    : in  std_logic;

    pi_addr     : in  unsigned(g_LogDepth-1 downto 0);
    pi_wrdata   : in  unsigned(g_DataWidth-1 downto 0);
    pi_wrnotrd  : in  std_logic;
    pi_valid    : in  std_logic;
    po_rddata   : out unsigned(g_DataWidth-1 downto 0));
end UtilBRAMSP;

architecture UtilBRAMSP of UtilBRAMSP is

  constant c_Depth : integer := 2**g_LogDepth;
  subtype t_Addr is unsigned(g_LogDepth-1 downto 0);

  subtype t_Data is unsigned(g_DataWidth-1 downto 0);
  type t_Buffer is array(0 to c_Depth-1) of t_Data;

  signal s_buffer : t_Buffer;
  signal s_out    : t_Data;
  signal s_outReg : t_Data;

begin

  process(pi_clk)
    variable v_addr : integer range 0 to c_Depth-1;
  begin
    v_addr := to_integer(pi_addr);
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_outReg <= (others => '0');
      else
        s_outReg <= s_out;
        if pi_valid = '1' then
          if pi_wrnotrd = '1' and g_ReadFirst then
            s_out <= s_buffer(v_addr);
            s_buffer(v_addr) <= pi_wrdata;
          elsif pi_wrnotrd = '1' and not g_ReadFirst then
            s_out <= pi_wrdata;
            s_buffer(v_addr) <= pi_wrdata;
          else
            s_out <= s_buffer(v_addr);
          end if;
        end if;
      end if;
    end if;
  end process;

  po_rddata <= s_outReg when g_RegisterOutput else s_out;

end UtilBRAMSP;
