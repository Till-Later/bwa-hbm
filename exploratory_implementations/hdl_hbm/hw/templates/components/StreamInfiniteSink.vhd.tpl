library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_ctrl.all;
use work.fosi_stream.all;
use work.fosi_user.all;
use work.fosi_util.all;


{{#x_type.x_stream}}
entity {{name}} is
  generic (
    g_Enabled : boolean := true);
  port (
    pi_clk     : in  std_logic;
    pi_rst_n   : in  std_logic;

    pi_stm_ms  : in  {{x_type.identifier_ms}};
    po_stm_sm  : out {{x_type.identifier_sm}});
end {{name}};

architecture {{name}} of {{name}} is

begin

  po_stm_sm.ready <= f_logic(g_Enabled);

end {{name}};
{{/x_type.x_stream}}
{{^x_type.x_stream}}
-- {{x_type}} is not an AxiStream Type
{{/x_type.x_stream}}
