library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;


entity UtilStableArbiter is
  generic (
    g_PortCount     : integer);
  port (
    pi_clk     : in  std_logic;
    pi_rst_n   : in  std_logic;

    pi_request : in  unsigned(g_PortCount-1 downto 0);

    po_grant   : out unsigned(g_PortCount-1 downto 0);
    po_port    : out unsigned(f_clog2(g_PortCount)-1 downto 0);
    po_valid   : out std_logic;
    pi_ready   : in  std_logic);
end UtilStableArbiter;

architecture UtilStableArbiter of UtilStableArbiter is

  constant c_PortAddrWidth : integer := f_clog2(g_PortCount);
  subtype t_PortAddr is unsigned (c_PortAddrWidth-1 downto 0);

  subtype t_PortVector is unsigned (g_PortCount-1 downto 0);
  constant c_PVZero : t_PortVector := to_unsigned(0, g_PortCount);
  constant c_PVOne : t_PortVector := to_unsigned(1, g_PortCount);

  signal s_plainReq : t_PortVector;
  signal s_maskedReq : t_PortVector;
  signal s_plainGnt : t_PortVector;
  signal s_maskedGnt : t_PortVector;
  signal s_nextGrant : t_PortVector;
  signal s_nextMask : t_PortVector;
  signal s_nextPort : t_PortAddr;
  signal s_nextActive : std_logic;

  signal s_mask : t_PortVector;
  signal s_grant : t_PortVector;
  signal s_valid : std_logic;

begin

  -- unmasked and masked request vector (mask is necessary for round robin behavior)
  -- also mask currently granted request line, to avoid unintentional re-granting if
  -- request line is released together with pi_ready
  s_plainReq <= pi_request and not s_grant;
  s_maskedReq <= pi_request and s_mask and not s_grant;
  -- produce grant vector: isolate the lowest set request bit (e.g. 110100 -> 000100)
  s_plainGnt <= s_plainReq and ((not s_plainReq) + c_PVOne);
  s_maskedGnt <= s_maskedReq and ((not s_maskedReq) + c_PVOne);
  -- select unmasked grant vector if no masked request bits remain to implement wrap
  s_nextGrant <= s_plainGnt when s_maskedReq = c_PVZero else s_maskedGnt;
  -- produce new mask: set all bits left of the granted bit (e.g. 000100 -> 111000)
  s_nextMask <= not ((s_nextGrant - c_PVOne) or s_nextGrant);

  s_nextPort <= to_unsigned(f_encode(s_nextGrant), c_PortAddrWidth);
  s_nextActive <= f_or(s_nextGrant);

  process (pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' or (s_nextActive = '0' and s_valid = '1' and pi_ready = '1') then
        s_valid <= '0';
        s_mask <= (others => '0');
        po_port <= (others => '0');
        s_grant <= (others => '0');
      elsif s_nextActive = '1' and (s_valid = '0' or pi_ready = '1') then
        s_mask <= s_nextMask;
        s_grant <= s_nextGrant;
        po_port <= s_nextPort;
        s_valid <= '1';
      end if;
    end if;
  end process;

  po_grant <= s_grant;
  po_valid <= s_valid;

end UtilStableArbiter;
