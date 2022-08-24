library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto;
use work.user;

entity HbmBenchmarkController is
  port (
    pi_sys : in dfaccto.t_Sys;
    po_axiStmWr_ms : out user.t_StmHbm_ms;
    pi_axiStmWr_sm : in user.t_StmHbm_sm;
    pi_axiStmRd_ms : in user.t_StmHbm_ms;
    po_axiStmRd_sm : out user.t_StmHbm_sm;
    po_regsRd_ms : out user.t_RegPort_ms;
    pi_regsRd_sm : in user.t_RegPort_sm;
    po_regsWr_ms : out user.t_RegPort_ms;
    pi_regsWr_sm : in user.t_RegPort_sm;
    po_startRd : out dfaccto.t_Logic;
    pi_readyRd : in dfaccto.t_Logic;
    po_startWr : out dfaccto.t_Logic;
    pi_readyWr : in dfaccto.t_Logic);
end HbmBenchmarkController;

architecture HbmBenchmarkController of HbmBenchmarkController is
  alias ai_sys is pi_sys;

  alias am_axiStmWr_ms is po_axiStmWr_ms;
  alias am_axiStmWr_sm is pi_axiStmWr_sm;

  alias as_axiStmRd_ms is pi_axiStmRd_ms;
  alias as_axiStmRd_sm is po_axiStmRd_sm;

  -- Config port (4 registers):
  --  Reg0: Start address low word
  --  Reg1: Start address high word
  --  Reg2: Transfer count
  --  Reg3: Maximum Burst length
  alias am_regsRd_ms is po_regsRd_ms;
  alias am_regsRd_sm is pi_regsRd_sm;
  alias am_regsWr_ms is po_regsWr_ms;
  alias am_regsWr_sm is pi_regsWr_sm;

  alias ao_startRd is po_startRd;
  alias ai_readyRd is pi_readyRd;

  alias ao_startWr is po_startWr;
  alias ai_readyWr is pi_readyWr;

  --type t_BenchmarkStage is (Idle, SeqRdRun, SeqWr, Done);
  type t_BenchmarkStage is (Idle, SeqRd, SeqWr, Done);
  signal s_benchmarkStage : t_BenchmarkStage;

  type t_seqStage is (Idle, Init0, Init1, Init2, Init3, Init4, Run, Done);
  signal s_seqRdStage : t_seqStage;
  signal s_seqWrStage : t_seqStage;
begin

  process (ai_sys.clk)
  begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      if ai_sys.rst_n = '0' then
        s_benchmarkStage <= SeqRd;
      else
        case s_benchmarkStage is
          when Idle =>
          when SeqRd =>
            if s_seqRdStage = Done then
              s_benchmarkStage <= SeqWr;
            end if;
          when SeqWr =>
            if s_seqWrStage = Done then
              s_benchmarkStage <= Done;
            end if;
          when Done =>
        end case;
      end if;
    end if;
  end process;

  with s_seqRdStage select am_regsRd_ms.wrnotrd <=
    '1' when Init0,
    '1' when Init1,
    '1' when Init2,
    '1' when Init3,
    '0' when others;

  with s_seqRdStage select am_regsRd_ms.valid <=
    '1' when Init0,
    '1' when Init1,
    '1' when Init2,
    '1' when Init3,
    '0' when others;

  am_regsRd_ms.wrstrb <= "1111";

  as_axiStmRd_sm.tready <= '1';

  with s_seqRdStage select ao_startRd <= '1' when Init4, '0' when others;

  process (ai_sys.clk)
  begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      if ai_sys.rst_n = '0' then
        s_seqRdStage <= Idle;
      else
        case s_seqRdStage is
          when Idle =>
            if s_benchmarkStage = SeqRd then
              s_seqRdStage <= Init0;
              am_regsRd_ms.addr <= to_unsigned(0, am_regsRd_ms.addr'length);
              am_regsRd_ms.wrdata <= to_unsigned(0, am_regsRd_ms.wrdata'length);
            end if;
          when Init0 =>
              if am_regsRd_sm.ready = '1' then
                am_regsRd_ms.addr <= to_unsigned(1, am_regsRd_ms.addr'length);
                am_regsRd_ms.wrdata <= to_unsigned(0, am_regsRd_ms.wrdata'length);
                s_seqRdStage <= Init1;
              end if;
          when Init1 =>
            if am_regsRd_sm.ready = '1' then
              s_seqRdStage <= Init2;
              am_regsRd_ms.addr <= to_unsigned(2, am_regsRd_ms.addr'length);
              am_regsRd_ms.wrdata <= to_unsigned(1024, am_regsRd_ms.wrdata'length);
            end if;
          when Init2 =>
            if am_regsRd_sm.ready = '1' then
              am_regsRd_ms.addr <= to_unsigned(3, am_regsRd_ms.addr'length);
              am_regsRd_ms.wrdata <= to_unsigned(8, am_regsRd_ms.wrdata'length);
              s_seqRdStage <= Init3;
            end if;
          when Init3 =>
            if am_regsRd_sm.ready = '1' then
              s_seqRdStage <= Init4;
            end if;
          when Init4 =>
            if ai_readyRd = '1' then
              s_seqRdStage <= Run;
            end if;
          when Run =>
            if as_axiStmRd_ms.tlast = '1' then
              s_seqRdStage <= Done;
            end if;
          when Done =>
            s_seqRdStage <= Done;
        end case;
      end if;
    end if;
  end process;
end HbmBenchmarkController;
