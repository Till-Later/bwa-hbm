library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}

entity {{identifier}} is
{{?generics}}
  generic (
{{# generics}}
{{#  is_complex}}
    {{identifier_ms}} : {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
    {{identifier_sm}} : {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/  is_complex}}
{{/ generics}}
{{/generics}}
{{?ports}}
  port (
{{# ports}}
{{#  is_complex}}
    {{identifier_ms}} : {{mode_ms}} {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}};
    {{identifier_sm}} : {{mode_sm}} {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{|  is_complex}}
    {{identifier}} : {{mode}} {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
{{/  is_complex}}
{{/ ports}}
{{/ports}}
end {{identifier}};

architecture HbmBenchmarkController of {{identifier}} is
  alias ai_sys is {{x_psys.identifier}};

  alias am_axiStmWr_ms is {{x_pm_axiStmWr.identifier_ms}};
  alias am_axiStmWr_sm is {{x_pm_axiStmWr.identifier_sm}};

  alias as_axiStmRd_ms is {{x_ps_axiStmRd.identifier_ms}};
  alias as_axiStmRd_sm is {{x_ps_axiStmRd.identifier_sm}};

  -- Config port (4 registers):
  --  Reg0: Start address low word
  --  Reg1: Start address high word
  --  Reg2: Transfer count
  --  Reg3: Maximum Burst length
  alias am_regsRd_ms is {{x_pm_regsRd.identifier_ms}};
  alias am_regsRd_sm is {{x_pm_regsRd.identifier_sm}};
  alias am_regsWr_ms is {{x_pm_regsWr.identifier_ms}};
  alias am_regsWr_sm is {{x_pm_regsWr.identifier_sm}};

  alias ao_startRd is {{x_po_startRd.identifier}};
  alias ai_readyRd is {{x_pi_readyRd.identifier}};

  alias ao_startWr is {{x_po_startWr.identifier}};
  alias ai_readyWr is {{x_pi_readyWr.identifier}};

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
