library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_util.all;

entity UtilLargeFIFO is
  generic (
    g_DataWidth : natural;
    g_LogDepth  : positive);
  port (
    pi_clk      : in  std_logic;
    pi_rst_n    : in  std_logic;

    pi_inData   : in  unsigned(g_DataWidth-1 downto 0);
    pi_inValid  : in  std_logic;
    po_inReady  : out std_logic;

    po_outData  : out unsigned(g_DataWidth-1 downto 0);
    po_outValid : out std_logic;
    pi_outReady : in  std_logic;

    po_count  : out unsigned(g_LogDepth downto 0));
end UtilLargeFIFO;

architecture UtilLargeFIFO of UtilLargeFIFO is

  constant c_Depth : integer := 2**g_LogDepth;

  subtype t_Cnt is unsigned(g_LogDepth-1 downto 0);
  constant c_CntOne : t_Cnt := to_unsigned(1, g_LogDepth);
  constant c_CntZero : t_Cnt := to_unsigned(0, g_LogDepth);
  signal s_rdCnt : t_Cnt;
  signal s_wrCnt : t_Cnt;
  signal s_count : t_Cnt;
  signal s_inAddr_0 : t_Cnt;
  signal s_outAddr_0 : t_Cnt;

  signal s_full : std_logic;

  subtype t_Data is unsigned(g_DataWidth-1 downto 0);
  signal s_inData_0 : t_Data;
  signal s_outData_1 : t_Data;
  signal s_outData_2 : t_Data;

  signal s_inStrb_0 : std_logic;
  signal s_inReady_0 : std_logic;
  signal s_inValid_0 : std_logic;
  signal s_outStrb_0 : std_logic;
  signal s_outReady_0 : std_logic;
  signal s_outValid_0 : std_logic;
  signal s_outReady_1 : std_logic;
  signal s_outValid_1 : std_logic;
  signal s_outReady_2 : std_logic;
  signal s_outValid_2 : std_logic;

begin
  -----------------------------------------------------------------------------
  -- Stage 0:
  -----------------------------------------------------------------------------
  s_inData_0 <= pi_inData;
  s_inValid_0 <= pi_inValid;
  po_inReady <= s_inReady_0;

  s_inReady_0 <= not s_full;
  s_outValid_0 <= f_logic(s_rdCnt /= s_wrCnt) or s_full;

  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_rdCnt <= (others => '0');
        s_wrCnt <= (others => '0');
        s_full <= '0';
      else
        if s_inValid_0 = '1' and s_inReady_0 = '1' and
            s_outValid_0 = '1' and s_outReady_0 = '1' then
          s_wrCnt <= s_wrCnt + c_CntOne;
          s_rdCnt <= s_rdCnt + c_CntOne;
        elsif s_inValid_0 = '1' and s_inReady_0 = '1' then
          if s_wrCnt + c_CntOne = s_rdCnt then
            s_full <= '1';
          end if;
          s_wrCnt <= s_wrCnt + c_CntOne;
        elsif s_outValid_0 = '1' and s_outReady_0 = '1' then
          if s_rdCnt = s_wrCnt then
            s_full <= '0';
          end if;
          s_rdCnt <= s_rdCnt + c_CntOne;
        end if;
      end if;
    end if;
  end process;

  s_inAddr_0 <= s_wrCnt;
  s_inStrb_0 <= s_inValid_0 and s_inReady_0;
  s_outAddr_0 <= s_rdCnt;
  s_outStrb_0 <= s_outValid_0 and s_outReady_0;

  -----------------------------------------------------------------------------
  -- Stage 1:
  -----------------------------------------------------------------------------
  i_buffer : entity work.UtilBRAMSDP
    generic map (
      g_DataWidth => g_DataWidth,
      g_LogDepth => g_LogDepth)
    port map (
      pi_clk => pi_clk,
      pi_rst_n => pi_rst_n,
      pi_wraddr => s_inAddr_0,
      pi_wrdata => s_inData_0,
      pi_wrstrb => s_inStrb_0,
      pi_rdaddr => s_outAddr_0,
      pi_rdstrb => s_outStrb_0,
      po_rddata => s_outData_1);

  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_outValid_1 <= '0';
      else
        if s_outValid_1 = '0' or s_outReady_1 = '1' then
          if s_outValid_0 = '1' then
            s_outValid_1 <= '1';
          else
            s_outValid_1 <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  s_outReady_0 <= s_outReady_1 or not s_outValid_1;

  -----------------------------------------------------------------------------
  -- Stage 2:
  -----------------------------------------------------------------------------
  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_outData_2 <= (others => '0');
        s_outValid_2 <= '0';
      else
        if s_outValid_2 = '0' or s_outReady_2 = '1' then
          if s_outValid_1 = '1' then
            s_outData_2 <= s_outData_1;
            s_outValid_2 <= '1';
          else
            s_outData_2 <= (others => '0');
            s_outValid_2 <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  s_outReady_1 <= s_outReady_2 or not s_outValid_2;

  po_outData <= s_outData_2;
  po_outValid <= s_outValid_2;
  s_outReady_2 <= pi_outReady;


  -----------------------------------------------------------------------------
  -- Counter Logic:
  -----------------------------------------------------------------------------
  s_count <= s_wrCnt - s_rdCnt;
  po_count <= (s_full & s_count) +
              (c_CntZero & s_outValid_1) +
              (c_CntZero & s_outValid_2);

end UtilLargeFIFO;
