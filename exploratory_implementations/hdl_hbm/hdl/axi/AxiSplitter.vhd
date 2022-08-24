library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_axi.all;
use work.fosi_util.all;


entity AxiSplitter is
  port (
    pi_clk     : in  std_logic;
    pi_rst_n   : in  std_logic;

    po_axi_ms  : out t_NativeAxi_ms;
    pi_axi_sm  : in  t_NativeAxi_sm;

    pi_axiRd_ms  : in  t_NativeAxiRd_ms;
    po_axiRd_sm  : out t_NativeAxiRd_sm;

    pi_axiWr_ms  : in  t_NativeAxiWr_ms;
    po_axiWr_sm  : out t_NativeAxiWr_sm);
end AxiSplitter;

architecture AxiSplitter of AxiSplitter is

begin

  po_axi_ms <= f_nativeAxiJoinRdWr_ms(pi_axiRd_ms, pi_axiWr_ms);
  po_axiRd_sm <= f_nativeAxiSplitRd_sm(pi_axi_sm);
  po_axiWr_sm <= f_nativeAxiSplitWr_sm(pi_axi_sm);

end AxiSplitter;
