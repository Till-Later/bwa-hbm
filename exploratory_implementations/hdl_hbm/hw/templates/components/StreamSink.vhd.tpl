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

    pi_stm_ms  : in  {{x_type.identifier_ms}};
    po_stm_sm  : out {{x_type.identifier_sm}};

    -- Config register port (1 Register):
    --  Reg0: [RW] Transfer Count
    pi_regs_ms : in  t_RegPort_ms;
    po_regs_sm : out t_RegPort_sm);
end {{name}};

architecture {{name}} of {{name}} is

  signal s_init : std_logic;
  signal s_running : std_logic;
  signal s_beat : std_logic;
  signal s_last : std_logic;

  -- Transfer Counter
  constant c_CountZero : t_RegData := to_unsigned(0, t_RegData'length);
  constant c_CountOne : t_RegData := to_unsigned(1, t_RegData'length);
  signal s_countdown : t_RegData;

  -- Control Registers
  signal so_regs_sm_ready : std_logic;
  signal s_reg0           : t_RegData;

begin

  s_init <= not s_running and pi_start;
  s_running <= f_logic(s_countdown /= c_CountZero);
  s_beat <= s_running and pi_stm_ms.tvalid;
  s_last <= s_beat and pi_stm_ms.tlast;

  po_stm_sm.tready <= s_running;

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
        elsif s_last = '1' then
          s_countdown <= c_CountZero;
        elsif s_beat = '1' then
          s_countdown <= s_countdown - c_CountOne;
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
      else
        if pi_regs_ms.valid = '1' and so_regs_sm_ready = '0' then
          so_regs_sm_ready <= '1';
          case v_portAddr is
            when 0 =>
              po_regs_sm.rddata <= s_reg0;
              if pi_regs_ms.wrnotrd = '1' then
                s_reg0 <= f_byteMux(pi_regs_ms.wrstrb, s_reg0, pi_regs_ms.wrdata);
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
