library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_axi.all;
use work.fosi_blockmap.all;
use work.fosi_util.all;


entity AxiRdBlockMapper is
  port (
    pi_clk       : in  std_logic;
    pi_rst_n     : in  std_logic;

    po_map_ms    : out t_BlkMap_ms;
    pi_map_sm    : in  t_BlkMap_sm;

    pi_axiLog_ms : in  t_NativeAxiRd_ms;
    po_axiLog_sm : out t_NativeAxiRd_sm;

    po_axiPhy_ms : out t_NativeAxiRd_ms;
    pi_axiPhy_sm : in  t_NativeAxiRd_sm);
end AxiRdBlockMapper;

architecture AxiRdBlockMapper of AxiRdBlockMapper is

  signal s_axiLogA_od : t_NativeAxiA_od;
  signal s_axiLogA_do : t_NativeAxiA_do;

  signal s_axiPhyA_od : t_NativeAxiA_od;
  signal s_axiPhyA_do : t_NativeAxiA_do;

begin

  -- Instantiate A-Channel Mapper
  i_mapper : entity work.AxiBlockMapper
    port map(
    pi_clk            => pi_clk,
    pi_rst_n          => pi_rst_n,
    pi_axiLog_od      => s_axiLogA_od,
    po_axiLog_do      => s_axiLogA_do,
    po_axiPhy_od      => s_axiPhyA_od,
    pi_axiPhy_do      => s_axiPhyA_do,
    po_store_ms       => po_map_ms,
    pi_store_sm       => pi_map_sm);

  -- Splice A-Channel from AxiRd Bundle
  s_axiLogA_od <= f_nativeAxiRdSplitA_ms(pi_axiLog_ms);
  s_axiPhyA_do <= f_nativeAxiRdSplitA_sm(pi_axiPhy_sm);

  po_axiLog_sm  <= f_nativeAxiRdJoin_sm(
                      s_axiLogA_do,
                      f_nativeAxiRdSplitR_sm(pi_axiPhy_sm));
  po_axiPhy_ms  <= f_nativeAxiRdJoin_ms(
                      s_axiPhyA_od,
                      f_nativeAxiRdSplitR_ms(pi_axiLog_ms));

end AxiRdBlockMapper;
