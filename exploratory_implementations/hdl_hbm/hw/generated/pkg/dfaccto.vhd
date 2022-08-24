library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;



package dfaccto is

  subtype t_Bool is boolean;
  type t_Bool_v is array (integer range <>) of dfaccto.t_Bool;

  constant c_BoolNull : dfaccto.t_Bool
            := false;

  subtype t_String is string;
  -- type t_String_v is array (integer range <>) of dfaccto.t_String; -- Not allowed until VHDL 2008

  constant c_StringNull : dfaccto.t_String
            := "";

  subtype t_Time is time;
  type t_Time_v is array (integer range <>) of dfaccto.t_Time;

  constant c_TimeNull : dfaccto.t_Time
            := 0 ns;

  subtype t_Integer is integer range integer'low to integer'high;
  type t_Integer_v is array (integer range <>) of dfaccto.t_Integer;

  constant c_IntegerNull : dfaccto.t_Integer
            := 0;

  subtype t_Size is integer range integer'low to integer'high;
  type t_Size_v is array (integer range <>) of dfaccto.t_Size;

  constant c_SizeNull : dfaccto.t_Size
            := 0;

  subtype t_Logic is std_logic;
  subtype t_Logic_v is unsigned;

  constant c_LogicNull : dfaccto.t_Logic
            := '0';

  type t_Sys is record
    clk   : dfaccto.t_Logic;
    rst_n : dfaccto.t_Logic;
  end record;
  type t_Sys_v is array (integer range <>) of dfaccto.t_Sys;

  constant c_SysNull : dfaccto.t_Sys
            := (clk   => '0',
                rst_n => '0');

end dfaccto;
