library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_stream.all;
use work.fosi_user.all;
use work.fosi_util.all;


{{#x_type.x_stream}}
entity {{name}} is
  generic (
    g_PortCount     : positive);
  port (
    pi_clk         : in std_logic;
    pi_rst_n       : in std_logic;

    pi_stm_ms  : in  {{x_type.identifier_ms}};
    po_stm_sm  : out {{x_type.identifier_sm}};

    po_stms_ms : out {{x_type.identifier_v_ms}}(g_PortCount-1 downto 0);
    pi_stms_sm : in  {{x_type.identifier_v_sm}}(g_PortCount-1 downto 0));
end {{name}};

architecture {{name}} of {{name}} is

  signal s_validLines     : unsigned(g_PortCount-1 downto 0);
  signal s_readyLines     : unsigned(g_PortCount-1 downto 0);
  signal s_readyMask : unsigned (g_PortCount-1 downto 0);

begin

  -----------------------------------------------------------------------------
  -- Stream Multiplier
  -----------------------------------------------------------------------------
  i_multipliers:
  for v_idx in 0 to g_PortCount-1 generate
  begin
    po_stms_ms(v_idx).tdata <= pi_stm_ms.tdata;
    po_stms_ms(v_idx).tkeep <= pi_stm_ms.tkeep;
    po_stms_ms(v_idx).tlast <= pi_stm_ms.tlast;
    po_stms_ms(v_idx).tvalid <= s_validLines(v_idx);
    s_readyLines(v_idx) <= pi_stms_sm(v_idx).tready;

    i_barrier : entity work.UtilBarrier
      generic map (
        g_Count => g_PortCount)
      port map (
        pi_clk      => pi_clk,
        pi_rst_n    => pi_rst_n,
        pi_signal   => s_readyLines,
        po_mask     => s_readyMask,
        po_continue => po_stm_sm.tready);

     s_validLines <= (others => pi_stm_ms.tvalid) and not s_readyMask;
  end generate i_multipliers;

end {{name}};
{{/x_type.x_stream}}
{{^x_type.x_stream}}
-- {{x_type}} is not an AxiStream Type
{{/x_type.x_stream}}
