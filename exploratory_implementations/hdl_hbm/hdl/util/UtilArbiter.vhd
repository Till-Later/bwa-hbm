library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;


entity UtilArbiter is
  generic (
    g_PortCount     : integer);
  port (
    pi_clk      : in  std_logic;
    pi_rst_n    : in  std_logic;

    pi_request  : in  unsigned(g_PortCount-1 downto 0);
    po_grant    : out unsigned(g_PortCount-1 downto 0);

    po_port     : out unsigned(f_clog2(g_PortCount)-1 downto 0);
    po_active   : out std_logic;
    pi_next     : in  std_logic := '1');
end UtilArbiter;

architecture UtilArbiter of UtilArbiter is

  constant c_PortAddrWidth : integer := f_clog2(g_PortCount);
  subtype t_PortAddr is unsigned (c_PortAddrWidth-1 downto 0);

  subtype t_PortVector is unsigned (g_PortCount-1 downto 0);
  constant c_PVZero : t_PortVector := to_unsigned(0, g_PortCount);
  constant c_PVOne : t_PortVector := to_unsigned(1, g_PortCount);

  signal s_plainReq : t_PortVector;
  signal s_maskedReq : t_PortVector;
  signal s_plainGnt : t_PortVector;
  signal s_maskedGnt : t_PortVector;
  signal s_grant : t_PortVector;

  signal s_mask : t_PortVector;

begin

  -- unmasked and masked request vector (mask is necessary for round robin behavior)
  s_plainReq <= pi_request;
  s_maskedReq <= pi_request and s_mask;
  -- produce grant vector: isolate the lowest set request bit (e.g. 110100 -> 000100)
  s_plainGnt <= s_plainReq and ((not s_plainReq) + c_PVOne);
  s_maskedGnt <= s_maskedReq and ((not s_maskedReq) + c_PVOne);
  -- select unmasked grant vector if no masked request bits remain to implement wrap
  s_grant <= s_plainGnt when s_maskedReq = c_PVZero else s_maskedGnt;

  process (pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_mask <= (others => '0');
      elsif pi_next = '1' then
        -- produce new mask: set all bits left of the granted bit (e.g. 000100 -> 111000)
        s_mask <= not ((s_grant - c_PVOne) or s_grant);
      end if;
    end if;
  end process;

  -- Outputs
  po_grant  <= s_grant;
  po_active <= f_or(s_grant);
  po_port   <= to_unsigned(f_encode(s_grant), c_PortAddrWidth);

end UtilArbiter;
