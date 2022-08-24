library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package interface is

  function x_stmSetup(totalSize : natural;
                      burstSize : natural;
                      bandwidth : real;
                      latency : real) return natural;
  attribute foreign of x_stmSetup : function is "VHPIDIRECT x_stmSetup";

  procedure x_stmTickSrc(v_id    : in  natural;
                         v_rst   : in  boolean;
                         v_last  : out boolean;
                         v_valid : out boolean;
                         v_ready : in  boolean;
                         v_done  : out boolean;
                         v_state : out integer;
                         v_delay : out integer;
                         v_count : out integer;
                         v_burst : out integer);
  attribute foreign of x_stmTickSrc : procedure is "VHPIDIRECT x_stmTickSrc";

  procedure x_stmTickSnk(v_id    : in  natural;
                         v_rst   : in  boolean;
                         v_last  : in  boolean;
                         v_valid : in  boolean;
                         v_ready : out boolean;
                         v_done  : out boolean;
                         v_state : out integer;
                         v_delay : out integer;
                         v_count : out integer;
                         v_burst : out integer);
  attribute foreign of x_stmTickSnk : procedure is "VHPIDIRECT x_stmTickSnk";

end interface;


package body interface is

  function x_stmSetup(totalSize : natural;
                      burstSize : natural;
                      bandwidth : real;
                      latency : real) return natural is
  begin
    report "VHPIDIRECT x_stmSetup" severity failure;
  end;

  procedure x_stmTickSrc(v_id    : in  natural;
                         v_rst   : in  boolean;
                         v_last  : out boolean;
                         v_valid : out boolean;
                         v_ready : in  boolean;
                         v_done  : out boolean;
                         v_state : out integer;
                         v_delay : out integer;
                         v_count : out integer;
                         v_burst : out integer) is
  begin
    report "VHPIDIRECT x_stmTickSrc" severity failure;
  end;

  procedure x_stmTickSnk(v_id    : in  natural;
                         v_rst   : in  boolean;
                         v_last  : in  boolean;
                         v_valid : in  boolean;
                         v_ready : out boolean;
                         v_done  : out boolean;
                         v_state : out integer;
                         v_delay : out integer;
                         v_count : out integer;
                         v_burst : out integer) is
  begin
    report "VHPIDIRECT x_stmTickSnk" severity failure;
  end;

end interface;
