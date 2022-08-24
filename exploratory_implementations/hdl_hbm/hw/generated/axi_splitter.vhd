library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto;
use work.dfaccto_axi;
use work.ocaccel;
use work.util.all;

entity AxiSplitter is
  port (
    pi_sys : in dfaccto.t_Sys;
    po_axi_ms : out ocaccel.t_AxiHbm_ms;
    pi_axi_sm : in ocaccel.t_AxiHbm_sm;
    pi_axiRd_ms : in ocaccel.t_AxiHbmRd_ms;
    po_axiRd_sm : out ocaccel.t_AxiHbmRd_sm;
    pi_axiWr_ms : in ocaccel.t_AxiHbmWr_ms;
    po_axiWr_sm : out ocaccel.t_AxiHbmWr_sm);
end AxiSplitter;

architecture AxiSplitter of AxiSplitter is

  alias ai_sys is pi_sys;

  alias am_axi_ms is po_axi_ms;
  alias am_axi_sm is pi_axi_sm;

  alias as_axiRd_ms is pi_axiRd_ms;
  alias as_axiRd_sm is po_axiRd_sm;

  alias as_axiWr_ms is pi_axiWr_ms;
  alias as_axiWr_sm is po_axiWr_sm;


begin

  am_axi_ms <= f_nativeAxiJoinRdWr_ms(as_axiRd_ms, as_axiWr_ms);
  as_axiRd_sm <= f_nativeAxiSplitRd_sm(am_axi_sm);
  as_axiWr_sm <= f_nativeAxiSplitWr_sm(am_axi_sm);

end AxiSplitter;
