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
    g_SendData : boolean := true;
    g_AssertLast : boolean := false;
    g_Enabled : boolean := true);
  port (
    pi_clk     : in std_logic;
    pi_rst_n   : in std_logic;

    po_stm_ms  : out {{x_type.identifier_ms}};
    pi_stm_sm  : in  {{x_type.identifier_sm}});
end {{name}};

architecture {{name}} of {{name}} is

begin

  po_stm_ms.tdata <= (others => '1');
  po_stm_ms.tkeep <= (others => f_logic(g_SendData));
  po_stm_ms.tlast <= f_logic(g_AssertLast);
  po_stm_ms.tvalid <= f_logic(g_Enabled);

end {{name}};
{{/x_type.x_stream}}
{{^x_type.x_stream}}
-- {{x_type}} is not an AxiStream Type
{{/x_type.x_stream}}
