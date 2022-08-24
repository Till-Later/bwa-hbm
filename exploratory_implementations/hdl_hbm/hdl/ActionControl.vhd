library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.fosi_ctrl.all;
use work.fosi_util.all;


entity ActionControl is
  generic (
    g_ReadyCount    : integer;
    g_ActionType    : integer;
    g_ActionRev     : integer);
  port (
    pi_clk          : in  std_logic;
    pi_rst_n        : in  std_logic;

    po_intReq       : out std_logic;
    po_intSrc       : out t_InterruptSrc;
    pi_intAck       : in  std_logic;
    pi_regs_ms      : in  t_RegPort_ms;
    po_regs_sm      : out t_RegPort_sm;

    po_context      : out t_Context;
    po_start        : out std_logic;
    pi_ready        : in  unsigned(g_ReadyCount-1 downto 0);

    pi_irq1         : in  std_logic := '0';
    po_iack1        : out std_logic;
    pi_irq2         : in  std_logic := '0';
    po_iack2        : out std_logic;
    pi_irq3         : in  std_logic := '0';
    po_iack3        : out std_logic);
end ActionControl;

architecture ActionControl of ActionControl is

  -- Action Logic
  signal s_type          : t_RegData;
  signal s_version       : t_RegData;
  signal s_ready         : std_logic;
  signal s_readyEvent    : std_logic;
  signal s_readyLast     : std_logic;
  signal s_startBit      : std_logic;
  signal s_doneBit       : std_logic;
  signal s_irqDone       : std_logic;

  constant c_CounterWidth : integer   := 48;
  subtype  t_Counter is unsigned(c_CounterWidth-1 downto 0);
  constant c_CounterOne   : t_Counter := to_unsigned(1, c_CounterWidth);
  constant c_CounterZero  : t_Counter := to_unsigned(0, c_CounterWidth);
  signal   s_cycleCounter : t_Counter;

  -- Interrupt Logic
  signal s_irqActive     : std_logic;
  signal s_irq0          : std_logic;
  signal s_irqState      : unsigned(3 downto 0);
  signal s_irqEvent      : unsigned(3 downto 0);
  signal s_irqLatch      : unsigned(3 downto 0);
  signal s_irqLast       : unsigned(3 downto 0);
  signal s_intReq        : std_logic;
  signal s_intSrc        : t_InterruptSrc;
  signal s_iackEvent     : unsigned(3 downto 0);

  -- Control Registers
  signal so_regs_sm_ready     : std_logic;
  signal s_reg8          : t_RegData;
  signal s_intEn         : unsigned(3 downto 0);
  signal s_intDoneEn     : std_logic;
  signal s_reg0ReadEvent : std_logic;
  signal s_startSetEvent : std_logic;
  signal s_irqDoneTEvent : std_logic;

begin

  s_ready <= f_and(pi_ready);
  s_type <= to_unsigned(g_ActionType, s_type'length);
  s_version <= to_unsigned(g_ActionRev, s_version'length);

  po_context <= s_reg8(po_context'range);

  -- Action Handshake Logic
  s_irq0 <= s_irqDone;
  process(pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      po_start <= '0';
      if pi_rst_n = '0' then
        s_readyEvent <= '0';
        s_readyLast <= '1';
        s_cycleCounter <= c_CounterZero;
        s_startBit <= '0';
        s_doneBit  <= '0';
        s_irqDone <= '0';
      else
        s_readyEvent <= s_ready and not s_readyLast;
        s_readyLast <= s_ready;

        if s_startSetEvent = '1' then
          s_startBit <= '1';
        elsif s_startBit = '1' and s_ready = '1' then
          s_startBit <= '0';
          po_start <= '1';
          s_cycleCounter <= c_CounterZero;
        elsif s_ready = '0' then
          s_cycleCounter <= s_cycleCounter + c_CounterOne;
        end if;

        if s_readyEvent = '1' then
          s_doneBit <= '1';
        elsif s_reg0ReadEvent = '1' then
          s_doneBit <= '0';
        end if;

        if s_readyEvent = '1' and s_intDoneEn = '1' then
          s_irqDone <= '1';
        elsif s_irqDoneTEvent = '1' then
          s_irqDone <= not s_irqDone;
        end if;
      end if;
    end if;
  end process;

  -- Interrupt Logic
  s_irqState <= (pi_irq3 and s_intEn(3)) &
                (pi_irq2 and s_intEn(2)) &
                (pi_irq1 and s_intEn(1)) &
                ( s_irq0 and s_intEn(0));
  po_iack1   <= s_iackEvent(1);
  po_iack2   <= s_iackEvent(2);
  po_iack3   <= s_iackEvent(3);
  po_intReq  <= s_intReq;
  po_intSrc  <= s_intSrc;
  process (pi_clk)
  begin
    if pi_clk'event and pi_clk = '1' then
      if pi_rst_n = '0' then
        s_irqActive <= '0';
        s_irqEvent  <= (others => '0');
        s_irqLatch  <= (others => '0');
        s_irqLast   <= (others => '0');
        s_iackEvent <= (others => '0');
        s_intReq    <= '0';
        s_intSrc    <= to_unsigned(0, s_intSrc'length);
      else
        s_irqEvent  <= s_irqState and not s_irqLast;
        s_irqLatch  <= s_irqLatch or s_irqEvent;
        s_irqLast   <= s_irqState;
        s_iackEvent <= (others => '0');
        s_intReq    <= '0';
        if s_irqActive = '0' then
          if s_irqLatch(0) = '1' then
            s_irqActive <= '1';
            s_irqLatch(0) <= '0';
            s_intReq <= '1';
            s_intSrc <= to_unsigned(0, s_intSrc'length);
          elsif s_irqLatch(1) = '1' then
            s_irqActive <= '1';
            s_irqLatch(1) <= '0';
            s_intReq <= '1';
            s_intSrc <= to_unsigned(1, s_intSrc'length);
          elsif s_irqLatch(2) = '1' then
            s_irqActive <= '1';
            s_irqLatch(2) <= '0';
            s_intReq <= '1';
            s_intSrc <= to_unsigned(2, s_intSrc'length);
          elsif s_irqLatch(3) = '1' then
            s_irqActive <= '1';
            s_irqLatch(3) <= '0';
            s_intReq <= '1';
            s_intSrc <= to_unsigned(3, s_intSrc'length);
          end if;
        elsif pi_intAck = '1' then
          s_irqActive <= '0';
          s_iackEvent(to_integer(s_intSrc)) <= '1';
        end if;
      end if;
    end if;
  end process;

  -- Control Register Access Logic
  process (pi_clk)
    variable v_addr : integer range 0 to 2**c_RegAddrWidth := 0;
  begin
    if pi_clk'event and pi_clk = '1' then
      v_addr := to_integer(pi_regs_ms.addr);

      if pi_rst_n = '0' then
        po_regs_sm.rddata <= (others => '0');
        so_regs_sm_ready <= '0';
        s_reg8 <= (others => '0');
        s_intEn <= (others => '0');
        s_intDoneEn <= '0';
        s_reg0ReadEvent <= '0';
        s_irqDoneTEvent <= '0';
        s_startSetEvent <= '0';
      else
        s_reg0ReadEvent <= '0';
        s_irqDoneTEvent <= '0';
        s_startSetEvent <= '0';
        if pi_regs_ms.valid = '1' and so_regs_sm_ready = '0' then
          so_regs_sm_ready <= '1';
          case v_addr is
            when 0 =>
              po_regs_sm.rddata <= to_unsigned(0, po_regs_sm.rddata'length-4) &
                                s_doneBit & s_ready & s_doneBit & s_startBit;
              s_reg0ReadEvent <= not pi_regs_ms.wrnotrd;
              if pi_regs_ms.wrnotrd = '1' then
                s_startSetEvent <= pi_regs_ms.wrstrb(0) and pi_regs_ms.wrdata(0);
              end if;
            when 1 =>
              po_regs_sm.rddata <= to_unsigned(0, po_regs_sm.rddata'length-4) &
                                s_intEn;
              if pi_regs_ms.wrnotrd = '1' and pi_regs_ms.wrstrb(0) = '1' then
                s_intEn <= pi_regs_ms.wrdata(3 downto 0);
              end if;
            when 2 =>
              po_regs_sm.rddata <= to_unsigned(0, po_regs_sm.rddata'length-1) &
                                s_intDoneEn;
              if pi_regs_ms.wrnotrd = '1' and pi_regs_ms.wrstrb(0) = '1' then
                s_intDoneEn <= pi_regs_ms.wrdata(0);
              end if;
            when 3 =>
              po_regs_sm.rddata <= to_unsigned(0, po_regs_sm.rddata'length-1) &
                                s_irqDone;
              s_irqDoneTEvent <= pi_regs_ms.wrnotrd and pi_regs_ms.wrstrb(0) and pi_regs_ms.wrdata(0);
            when 4 =>
              po_regs_sm.rddata <= s_type;
            when 5 =>
              po_regs_sm.rddata <= s_version;
            when 6 =>
              po_regs_sm.rddata <= f_resize(s_cycleCounter, po_regs_sm.rddata'length, 0);
            when 7 =>
              po_regs_sm.rddata <= f_resize(s_cycleCounter, po_regs_sm.rddata'length, po_regs_sm.rddata'length);
            when 8 =>
              po_regs_sm.rddata <= s_reg8;
              if pi_regs_ms.wrnotrd = '1' then
                s_reg8 <= f_byteMux(pi_regs_ms.wrstrb, s_reg8, pi_regs_ms.wrdata);
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
  po_regs_sm.ready <= so_regs_sm_ready;

end ActionControl;
