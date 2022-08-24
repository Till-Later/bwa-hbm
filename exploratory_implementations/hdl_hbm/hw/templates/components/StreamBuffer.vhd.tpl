library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_stream.all;
use work.fosi_user.all;
use work.fosi_util.all;

{{#x_type.x_stream}}
entity {{name}} is
  generic (
    g_LogDepth  : positive;
    g_InThreshold : natural := 0; -- Number of free entries required to enable input
    g_OutThreshold : natural := 0; -- Number of pending entries required to enable output
    g_OmitKeep : boolean := false);
  port (
    pi_clk       : in  std_logic;
    pi_rst_n     : in  std_logic;

    pi_stmIn_ms  : in  {{x_type.identifier_ms}};
    po_stmIn_sm  : out {{x_type.identifier_sm}};

    po_stmOut_ms : out {{x_type.identifier_ms}};
    pi_stmOut_sm : in  {{x_type.identifier_sm}};

    po_inEnable  : out std_logic;
    po_inHold    : out std_logic;
    po_outEnable  : out std_logic;
    po_outHold  : out std_logic);
end {{name}};

architecture {{name}} of {{name}} is

  -- Stream-to-unsigned Packing
  constant c_DataWidth : integer := {{x_type.x_datawidth}};
  constant c_KeepWidth : integer := c_DataWidth/8;

  function f_packedWidth(v_dataWidth : integer; v_keepWidth : integer; v_omitKeep : boolean) return integer is
  begin
    if v_omitKeep then
      return v_dataWidth + 1;
    else
      return v_dataWidth + v_keepWidth + 1;
    end if;
  end f_packedWidth;

  constant c_PackedWidth : integer := f_packedWidth(c_DataWidth, c_KeepWidth, g_OmitKeep);
  subtype t_Packed is unsigned (c_PackedWidth-1 downto 0);

  function f_pack(v_stm : {{x_type.identifier_ms}}) return t_Packed is
    variable v_packed : t_Packed;
  begin
    v_packed(c_DataWidth-1 downto 0) := v_stm.tdata;
    v_packed(c_DataWidth) := v_stm.tlast;
    if not g_OmitKeep then
      v_packed(c_DataWidth+c_KeepWidth downto c_DataWidth+1) := v_stm.tkeep;
    end if;
    return v_packed;
  end f_pack;

  function f_unpack(v_packed : t_Packed; v_valid : std_logic) return {{x_type.identifier_ms}} is
    variable v_stm : {{x_type.identifier_ms}};
  begin
    v_stm.tdata := v_packed(c_DataWidth-1 downto 0);
    v_stm.tlast := v_packed(c_DataWidth);
    if not g_OmitKeep then
      v_stm.tkeep := v_packed(c_DataWidth+c_KeepWidth downto c_DataWidth+1);
    else
      v_stm.tkeep := (others => '1');
    end if;
    v_stm.tvalid := v_valid;
    return v_stm;
  end f_unpack;

  -- Stream FIFO
  signal s_packedInStm   : t_Packed;
  signal s_inLast : std_logic;
  signal s_inValid : std_logic;
  signal s_inReady : std_logic;
  signal s_lastInc : std_logic;
  signal s_packedOutStm  : t_Packed;
  signal s_outLast : std_logic;
  signal s_outValid : std_logic;
  signal s_outReady : std_logic;
  signal s_lastDec : std_logic;

  -- Stream Enable Logic
  subtype t_Count is unsigned (g_LogDepth downto 0);
  constant c_CountZero : t_Count := to_unsigned(0, t_Count'length);
  constant c_CountOne : t_Count := to_unsigned(1, t_Count'length);
  constant c_InLimit : t_Count := to_unsigned(2**g_LogDepth - g_InThreshold, t_Count'length);
  constant c_OutLimit : t_Count := to_unsigned(g_OutThreshold, t_Count'length);
  signal s_count  : t_Count;
  signal s_lastCount : t_Count;
  signal s_inEnable : std_logic;
  signal s_outEnable : std_logic;

begin

  -- Stream FIFO
  s_packedInStm <= f_pack(pi_stmIn_ms);
  s_inLast <= pi_stmIn_ms.tlast;
  s_inValid <= pi_stmIn_ms.tvalid;
  po_stmIn_sm.tready <= s_inReady;
  i_fifo : entity work.UtilLargeFIFO
    generic map (
      g_LogDepth => g_LogDepth,
      g_DataWidth => c_PackedWidth)
    port map (
      pi_clk => pi_clk,
      pi_rst_n => pi_rst_n,
      pi_inData   => s_packedInStm,
      pi_inValid  => s_inValid,
      po_inReady  => s_inReady,
      po_outData  => s_packedOutStm,
      po_outValid => s_outValid,
      pi_outReady => s_outReady,
      po_count    => s_count);
  s_outLast <= f_unpack(s_packedOutStm, s_outValid).tlast;
  po_stmOut_ms <= f_unpack(s_packedOutStm, s_outValid);
  s_outReady <= pi_stmOut_sm.tready;

  -- Stream Enable Logic
  s_lastInc <= s_inLast  and s_inValid  and s_inReady;
  s_lastDec <= s_outLast and s_outValid and s_outReady;
  process (pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_lastCount <= c_CountZero;
      elsif s_lastInc = '1' and s_lastDec = '0' then
        s_lastCount <= s_lastCount + c_CountOne;
      elsif s_lastInc = '0' and s_lastDec = '1' then
        s_lastCount <= s_lastCount - c_CountOne;
      end if;
    end if;
  end process;

  s_inEnable   <= f_logic(s_count < c_InLimit or s_lastCount /= c_CountZero);
  s_outEnable  <= f_logic(s_count >= c_OutLimit or s_lastCount /= c_CountZero);

  po_inEnable  <=     s_inEnable;
  po_inHold    <= not s_inEnable;
  po_outEnable <=     s_outEnable;
  po_outHold   <= not s_outEnable;

end {{name}};
{{/x_type.x_stream}}
{{^x_type.x_stream}}
-- StreamBuffer requires type {{x_type.name}} to be an AxiStream
{{/x_type.x_stream}}
