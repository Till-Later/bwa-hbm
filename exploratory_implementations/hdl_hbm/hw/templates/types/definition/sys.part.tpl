type {{.identifier}} is record
  clk   : {{.x_tlogic.qualified}};
  rst_n : {{.x_tlogic.qualified}};
end record;
type {{.identifier_v}} is array (integer range <>) of {{.qualified}};
