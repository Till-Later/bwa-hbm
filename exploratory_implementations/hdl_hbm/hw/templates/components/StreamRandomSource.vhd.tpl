library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_ctrl.all;
use work.fosi_stream.all;
use work.fosi_user.all;
use work.fosi_util.all;


{{#x_type.x_stream}}
entity {{name}} is
  port (
    pi_clk     : in std_logic;
    pi_rst_n   : in std_logic;

    pi_start   : in  std_logic;
    po_ready   : out std_logic;

    po_stm_ms  : out {{x_type.identifier_ms}};
    pi_stm_sm  : in  {{x_type.identifier_sm}};

    -- Config register port (2 Registers):
    --  Reg0: [RW] Transfer Count
    --  Reg1: [RW] Random Seed
    pi_regs_ms : in  t_RegPort_ms;
    po_regs_sm : out t_RegPort_sm);
end {{name}};

architecture {{name}} of {{name}} is

  signal s_running : std_logic;
  signal s_last : std_logic;
  signal s_beat : std_logic;
  signal s_init : std_logic;

  -- Random Number Generator
  constant c_BlockSize : natural := 32;
  type t_RngBlock is unsigned(c_BlockSize-1 downto 0);
  constant c_BlockCount : natural := f_cdiv({{x_type.x_datawidth}}, c_BockSize);
  type t_RngState is unsigned(c_BlockCount*c_BlockSize-1 downto 0);
  signal s_rngSeed : t_RngState;
  signal s_rngState : t_RngState;

  function f_xorshift32(v_state : t_RngBlock) return t_RngBlock is
    variable v_newState : t_RngBlock;
  begin
    v_newState := v_state;
    v_newState := v_newState xor (v_newState sll 13);
    v_newState := v_newState xor (v_newState srl 17);
    v_newState := v_newState xor (v_newState sll 5);
    return v_newState;
  end f_xorshift32;

  -- Transfer Counter
  constant c_CountZero : t_RegData := to_unsigned(0, t_RegData'length);
  constant c_CountOne : t_RegData := to_unsigned(1, t_RegData'length);
  signal s_countdown : t_RegData;

  -- Control Registers
  signal so_regs_sm_ready : std_logic;
  signal s_reg0           : t_RegData;
  signal s_reg1           : t_RegData;

begin

  s_running <= f_logic(s_countdown /= c_CountZero);
  s_last <= f_logic(s_countdown = c_CountOne);
  s_init <= not s_running and pi_start;
  s_beat <= s_running and pi_stm_sm.tready;

  po_stm_ms.tdata <= f_resize(s_rngState, po_stm_ms.tdata'length);
  po_stm_ms.tkeep <= (others => '1');
  po_stm_ms.tlast <= s_last;
  po_stm_ms.tvalid <= s_running;

  po_ready <= not s_running;

  -----------------------------------------------------------------------------
  -- Transfer Counter:
  -----------------------------------------------------------------------------
  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_countdown <= c_CountZero;
      else
        if s_init = '1' then
          s_countdown <= s_reg0;
        elsif s_beat = '1' then
          s_countdown <= s_countdown - c_CountOne;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Random Number Generator
  -----------------------------------------------------------------------------
  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_rngState <= (others => '0');
      else
        if s_init = '1' then
          for v_idx in 0 to c_BlockCount-1 loop
            s_rngState(g_BlockSize*v_idx+g_BlockSize-1 downto g_BlockSize*v_idx) <= s_reg1 rol v_idx;
          end loop;
        elsif s_beat = '1'
          for v_idx in 0 to c_BlockCount-1 loop
            s_rngState(g_BlockSize*v_idx+g_BlockSize-1 downto g_BlockSize*v_idx) <=
              f_xorshift32(s_rngState(g_BlockSize*v_idx+g_BlockSize-1 downto g_BlockSize*v_idx)))
          end loop;
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Register Access
  -----------------------------------------------------------------------------
  po_regs_sm.ready <= so_regs_sm_ready;
  process (pi_clk)
    variable v_portAddr : integer range 0 to 2**pi_regs_ms.addr'length-1;
  begin
    if pi_clk'event and pi_clk = '1' then
      v_portAddr := to_integer(pi_regs_ms.addr);
      if pi_rst_n = '0' then
        po_regs_sm.rddata <= (others => '0');
        so_regs_sm_ready <= '0';
        s_reg0 <= (others => '0');
        s_reg1 <= (others => '0');
      else
        if pi_regs_ms.valid = '1' and so_regs_sm_ready = '0' then
          so_regs_sm_ready <= '1';
          case v_portAddr is
            when 0 =>
              po_regs_sm.rddata <= s_reg0;
              if pi_regs_ms.wrnotrd = '1' then
                s_reg0 <= f_byteMux(pi_regs_ms.wrstrb, s_reg0, pi_regs_ms.wrdata);
              end if;
            when 1 =>
              po_regs_sm.rddata <= s_reg1;
              if pi_regs_ms.wrnotrd = '1' then
                s_reg1 <= f_byteMux(pi_regs_ms.wrstrb, s_reg1, pi_regs_ms.wrdata);
              end if;
            when others =>
              po_regs_sm.rddata <= (others => '0');
          end case;
        else
          so_regs_sm_ready <= '0';
        end if;
      end if;
    end if;
  end process;

end {{name}};
{{/x_type.x_stream}}
{{^x_type.x_stream}}
-- {{x_type}} is not an AxiStream Type
{{/x_type.x_stream}}
