library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;

entity PipelineStage is
  generic (
    g_DataWidth  : positive);
  port (
    pi_clk       : in  std_logic;
    pi_rst_n     : in  std_logic;

    pi_inData    : in  unsigned (g_DataWidth-1 downto 0);
    pi_inValid   : in  std_logic;
    po_inReady   : out std_logic;

    po_outData   : out unsigned (g_DataWidth-1 downto 0);
    po_outValid  : out std_logic;
    pi_outReady  : in  std_logic);
end PipelineStage;

architecture PipelineStage of PipelineStage is

  subtype t_Data is unsigned (g_DataWidth-1 downto 0);
  signal s_buffer : t_Data;

  type t_State is (Empty, Full, Overflow);
  signal s_state : t_State;

begin

  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_state <= Empty;
        s_buffer <= (others => '0');
        po_outData <= (others => '0');
      else
        case s_state is

          when Empty =>
            if pi_inValid = '1' then
              po_outData <= pi_inData;
              s_state <= Full;
            end if;

          when Full =>
            if pi_inValid = '1' and pi_outReady = '1' then
              po_outData <= pi_inData;
              s_state <= Full;
            elsif pi_inValid = '1' then
              s_buffer <= pi_inData;
              s_state <= Overflow;
            elsif pi_outReady = '1' then
              s_state <= Empty;
            end if;

          when Overflow =>
            if pi_outReady = '1' then
              po_outData <= s_buffer;
              s_state <= Full;
            end if;

        end case;
      end if;
    end if;
  end process;

  with s_state select po_inReady <=
    '1' when Empty,
    '1' when Full,
    '0' when Overflow;

  with s_state select po_outValid <=
    '0' when Empty,
    '1' when Full,
    '1' when Overflow;

end PipelineStage;
