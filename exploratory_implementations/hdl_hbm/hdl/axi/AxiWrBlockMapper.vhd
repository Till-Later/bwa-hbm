library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_axi.all;
use work.fosi_blockmap.all;
use work.fosi_util.all;


entity AxiWrBlockMapper is
  port (
    pi_clk       : in  std_logic;
    pi_rst_n     : in  std_logic;

    po_map_ms    : out t_BlkMap_ms;
    pi_map_sm    : in  t_BlkMap_sm;

    pi_axiLog_ms : in  t_NativeAxiWr_ms;
    po_axiLog_sm : out t_NativeAxiWr_sm;

    po_axiPhy_ms : out t_NativeAxiWr_ms;
    pi_axiPhy_sm : in  t_NativeAxiWr_sm);
end AxiWrBlockMapper;

architecture AxiWrBlockMapper of AxiWrBlockMapper is

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

  -- Splice A-Channel from AxiWr Bundle
  s_axiLogA_od <= f_nativeAxiWrSplitA_ms(pi_axiLog_ms);
  s_axiPhyA_do <= f_nativeAxiWrSplitA_sm(pi_axiPhy_sm);

  po_axiLog_sm  <= f_nativeAxiWrJoin_sm(
                      s_axiLogA_do,
                      f_nativeAxiWrSplitW_sm(pi_axiPhy_sm),
                      f_nativeAxiWrSplitB_sm(pi_axiPhy_sm));
  po_axiPhy_ms  <= f_nativeAxiWrJoin_ms(
                      s_axiPhyA_od,
                      f_nativeAxiWrSplitW_ms(pi_axiLog_ms),
                      f_nativeAxiWrSplitB_ms(pi_axiLog_ms));

end AxiWrBlockMapper;
