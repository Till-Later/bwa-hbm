library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util;

entity {{identifier}} is
  generic (
    g_NumInitSignals : integer;
    g_NumMainSignals : integer);
  port (
    pi_sys            : in dfaccto.t_Sys;
    pi_start          : in std_logic;
    po_ready          : out std_logic;
    po_reset_counters : out std_logic;

    pi_reg_ms       : in reg_port_types.t_RegPort_ms;
    po_reg_sm       : out reg_port_types.t_RegPort_sm;

    po_bwt_addr : out numeric_types.t_u64;
    po_runtime_status_control_addr : out numeric_types.t_u64;
    po_bwt_primary : out numeric_types.t_u64;
    po_bwt_L2 : out numeric_types.t_u320;
    po_bwt_size : out numeric_types.t_u32;
    po_split_width : out numeric_types.t_u32;
    po_split_len : out numeric_types.t_u32;
    po_min_seed_len : out numeric_types.t_u32;

    pi_ctrl_hs_init_sm        : in control_types.t_HlsBlockCtrlHs_v_sm(g_NumInitSignals - 1 downto 0);
    po_ctrl_hs_init_ms        : out control_types.t_HlsBlockCtrlHs_v_ms(g_NumInitSignals - 1 downto 0);
    pi_ctrl_hs_main_sm        : in control_types.t_HlsBlockCtrlHs_v_sm(g_NumMainSignals - 1 downto 0);
    po_ctrl_hs_main_ms        : out control_types.t_HlsBlockCtrlHs_v_ms(g_NumMainSignals - 1 downto 0)
);
end {{identifier}};

architecture AcceleratedBwaMemMainController of {{identifier}} is
  signal s_start_buffer           : std_logic;
  signal s_ready_buffer           : std_logic;
  signal s_reset_counters_buffer  : std_logic;

  signal s_bwt_addr_buffer : numeric_types.t_u64;
  signal s_runtime_status_control_addr_buffer : numeric_types.t_u64;
  signal s_bwt_primary_buffer : numeric_types.t_u64;
  signal s_bwt_L2_buffer : numeric_types.t_u320;
  signal s_bwt_size_buffer : numeric_types.t_u32;
  signal s_split_width_buffer : numeric_types.t_u32;
  signal s_split_len_buffer : numeric_types.t_u32;
  signal s_min_seed_len_buffer : numeric_types.t_u32;

  signal s_ctrl_hs_init_buffer_sm : control_types.t_HlsBlockCtrlHs_v_sm(g_NumInitSignals - 1 downto 0);
  signal s_ctrl_hs_init_buffer_ms : control_types.t_HlsBlockCtrlHs_v_ms(g_NumInitSignals - 1 downto 0);

  signal s_ctrl_hs_main_buffer_sm : control_types.t_HlsBlockCtrlHs_v_sm(g_NumMainSignals - 1 downto 0);
  signal s_ctrl_hs_main_buffer_ms : control_types.t_HlsBlockCtrlHs_v_ms(g_NumMainSignals - 1 downto 0);

  alias ai_sys is pi_sys;

  type t_regs_store_v is array (integer range <>) of numeric_types.t_u32;

  signal regs_store_in                           : t_regs_store_v(23 downto 0) := (others => (others => '0'));
  signal regs_store_out                          : t_regs_store_v(23 downto 0) := (others => (others => '0'));

  signal current_init_start_signals             : std_logic_vector(g_NumInitSignals - 1 downto 0);
  signal current_init_idle_signals              : std_logic_vector(g_NumInitSignals - 1 downto 0);
  signal current_init_done_signals              : std_logic_vector(g_NumInitSignals - 1 downto 0);

  signal stored_init_idle_signals               : std_logic_vector(g_NumInitSignals - 1 downto 0);
  signal stored_init_done_signals               : std_logic_vector(g_NumInitSignals - 1 downto 0);

  signal current_main_idle_signals              : std_logic_vector(g_NumMainSignals - 1 downto 0);
  signal current_main_done_signals              : std_logic_vector(g_NumMainSignals - 1 downto 0);
  signal current_main_start_signals             : std_logic_vector(g_NumMainSignals - 1 downto 0);

  signal stored_main_idle_signals               : std_logic_vector(g_NumMainSignals - 1 downto 0);
  signal stored_main_done_signals               : std_logic_vector(g_NumMainSignals - 1 downto 0);

  function f_byteMux(v_select : unsigned; v_data0 : unsigned; v_data1 : unsigned) return unsigned is
    variable v_result : unsigned (v_data0'length-1 downto 0);
  begin
    assert v_select'length * 8 = v_data0'length report "f_byteMux arg width mismatch" severity failure;
    assert v_select'length * 8 = v_data1'length report "f_byteMux arg width mismatch" severity failure;

    for v_index in v_select'low to v_select'high loop
      if v_select(v_index) = '1' then
        v_result(v_result'low+v_index*8+7 downto v_result'low+v_index*8) :=
          v_data1(v_data1'low+v_index*8+7 downto v_data1'low+v_index*8);
      else
        v_result(v_result'low+v_index*8+7 downto v_result'low+v_index*8) :=
          v_data0(v_data0'low+v_index*8+7 downto v_data0'low+v_index*8);
      end if;
    end loop;
    return v_result;
  end f_byteMux;

  type t_StartReadyControllerStage is (Idle, WaitInit, RunInit, WaitMain, RunMain);
  signal s_startReadyControllerStage :  t_StartReadyControllerStage;

begin

  process (ai_sys.clk)
  begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      s_start_buffer <= pi_start;
      po_ready <= s_ready_buffer;
      po_reset_counters <= s_reset_counters_buffer;

      po_bwt_addr <= s_bwt_addr_buffer;
      po_runtime_status_control_addr <= s_runtime_status_control_addr_buffer;
      po_bwt_primary <= s_bwt_primary_buffer;
      po_bwt_L2 <= s_bwt_L2_buffer;
      po_bwt_size <= s_bwt_size_buffer;
      po_split_width <= s_split_width_buffer;
      po_split_len <= s_split_len_buffer;
      po_min_seed_len <= s_min_seed_len_buffer;

      for I in 0 to g_NumInitSignals - 1 loop
        po_ctrl_hs_init_ms(I).start <= s_ctrl_hs_init_buffer_ms(I).start;
        s_ctrl_hs_init_buffer_sm(I).idle <= pi_ctrl_hs_init_sm(I).idle;
        s_ctrl_hs_init_buffer_sm(I).ready <= pi_ctrl_hs_init_sm(I).ready;
        s_ctrl_hs_init_buffer_sm(I).done <= pi_ctrl_hs_init_sm(I).done;
      end loop;

      for I in 0 to g_NumMainSignals - 1 loop
        po_ctrl_hs_main_ms(I).start <= s_ctrl_hs_main_buffer_ms(I).start;
        s_ctrl_hs_main_buffer_sm(I).idle <= pi_ctrl_hs_main_sm(I).idle;
        s_ctrl_hs_main_buffer_sm(I).ready <= pi_ctrl_hs_main_sm(I).ready;
        s_ctrl_hs_main_buffer_sm(I).done <= pi_ctrl_hs_main_sm(I).done;
      end loop;

    end if;
  end process;


    generate_idle_signals: for I in 0 to g_NumInitSignals - 1 generate
        s_ctrl_hs_init_buffer_ms(I).start <= current_init_start_signals(I);
        current_init_idle_signals(I) <= s_ctrl_hs_init_buffer_sm(I).idle;
        current_init_done_signals(I) <= s_ctrl_hs_init_buffer_sm(I).done;
    end generate generate_idle_signals;

    generate_main_signals: for I in 0 to g_NumMainSignals - 1 generate
        s_ctrl_hs_main_buffer_ms(I).start <= current_main_start_signals(I);
        current_main_idle_signals(I) <= s_ctrl_hs_main_buffer_sm(I).idle;
        current_main_done_signals(I) <= s_ctrl_hs_main_buffer_sm(I).done;
    end generate generate_main_signals;

    -- Control logic for start & ready signals
    with s_startReadyControllerStage select s_ready_buffer <= '1' when Idle, '0' when others;
    with s_startReadyControllerStage select current_init_start_signals <=
        (stored_init_idle_signals) when RunInit,
        (current_init_start_signals'range => '0')  when others;

    with s_startReadyControllerStage select current_main_start_signals <=
        (stored_main_idle_signals) when RunMain,
        (current_main_start_signals'range => '0')  when others;

    with s_startReadyControllerStage select s_reset_counters_buffer <= '0' when RunMain, '1' when others;

    process (ai_sys.clk)
    begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      if ai_sys.rst_n = '0' then
        s_startReadyControllerStage <= Idle;

        stored_main_idle_signals <= (others => '0');
        stored_main_done_signals <= (others => '0');
      else
        stored_init_done_signals <= stored_init_done_signals or current_init_done_signals;
        stored_main_done_signals <= stored_main_done_signals or current_main_done_signals;
        case s_startReadyControllerStage is
            when Idle =>
                stored_init_idle_signals <= (others => '0');
                stored_init_done_signals <= (others => '0');
                stored_main_idle_signals <= (others => '0');
                stored_main_done_signals <= (others => '0');
                if s_start_buffer = '1' then
                    s_startReadyControllerStage <= WaitInit;
                end if;
            when WaitInit =>
                stored_init_idle_signals <= stored_init_idle_signals or current_init_idle_signals;
                if stored_init_idle_signals = (stored_init_idle_signals'range => '1') then
                    s_startReadyControllerStage <= RunInit;
                end if;
            when RunInit =>
                stored_init_idle_signals <= stored_init_idle_signals and current_init_idle_signals;
                if stored_init_done_signals = (stored_init_done_signals'range => '1') then
                    s_startReadyControllerStage <= WaitMain;
                end if;
            when WaitMain =>
                stored_main_idle_signals <= stored_main_idle_signals or current_main_idle_signals;
                if stored_main_idle_signals = (stored_main_idle_signals'range => '1') then
                    s_startReadyControllerStage <= RunMain;
                end if;
            when RunMain =>
                stored_main_idle_signals <= stored_main_idle_signals and current_main_idle_signals;
                if stored_main_done_signals = (stored_main_done_signals'range => '1') then
                  s_startReadyControllerStage <= Idle;
                end if;
        end case;
      end if;
    end if;
    end process;

    -- Map Register values to variables
    s_bwt_addr_buffer(31 downto 0) <= regs_store_in(0);
    s_bwt_addr_buffer(63 downto 32) <= regs_store_in(1);

    s_runtime_status_control_addr_buffer(31 downto 0) <= regs_store_in(2);
    s_runtime_status_control_addr_buffer(63 downto 32) <= regs_store_in(3);

    s_bwt_primary_buffer(31 downto 0) <= regs_store_in(4);
    s_bwt_primary_buffer(63 downto 32) <= regs_store_in(5);

    s_bwt_L2_buffer(31 downto 0) <= regs_store_in(6);
    s_bwt_L2_buffer(63 downto 32) <= regs_store_in(7);
    s_bwt_L2_buffer(95 downto 64) <= regs_store_in(8);
    s_bwt_L2_buffer(127 downto 96) <= regs_store_in(9);
    s_bwt_L2_buffer(159 downto 128) <= regs_store_in(10);
    s_bwt_L2_buffer(191 downto 160) <= regs_store_in(11);
    s_bwt_L2_buffer(223 downto 192) <= regs_store_in(12);
    s_bwt_L2_buffer(255 downto 224) <= regs_store_in(13);
    s_bwt_L2_buffer(287 downto 256) <= regs_store_in(14);
    s_bwt_L2_buffer(319 downto 288) <= regs_store_in(15);

    s_bwt_size_buffer(31 downto 0) <= regs_store_in(16);

    s_split_width_buffer(31 downto 0) <= regs_store_in(17);
    s_split_len_buffer(31 downto 0) <= regs_store_in(18);
    s_min_seed_len_buffer(31 downto 0) <= regs_store_in(19);


    regs_store_out(0) <= to_unsigned(16#3c2d1e0f#, numeric_types.t_u32'length);
    regs_store_out(1) <= unsigned("00000"
      & current_init_start_signals(0 downto 0) 
      & current_init_idle_signals(0 downto 0) 
      & current_init_done_signals(0 downto 0) 
      & "000"
      & current_main_start_signals(4 downto 0)
      & "000"
      & current_main_idle_signals(4 downto 0)
      & "000"
      & current_main_done_signals(4 downto 0));


    process (ai_sys.clk)
    variable v_portAddr : integer range 0 to 2**pi_reg_ms.addr'length-1;
    begin
    if ai_sys.clk'event and ai_sys.clk = '1' then
      if ai_sys.rst_n = '0' then
        po_reg_sm.ready <= '0';
      else
        v_portAddr := to_integer(pi_reg_ms.addr);
        if pi_reg_ms.valid = '1' then
          po_reg_sm.ready <= '1';
          po_reg_sm.rddata <= regs_store_out(to_integer(pi_reg_ms.addr(pi_reg_ms.addr'length-1 downto 0)));
          if pi_reg_ms.wrnotrd = '1' then
            regs_store_in(to_integer(pi_reg_ms.addr(pi_reg_ms.addr'length-1 downto 0))) <= f_byteMux(
              pi_reg_ms.wrstrb,
              regs_store_in(to_integer(pi_reg_ms.addr(pi_reg_ms.addr'length-1 downto 0))),
              pi_reg_ms.wrdata);
          end if;
        else
          po_reg_sm.ready <= '0';
        end if;
      end if;
    end if;
    end process;
end AcceleratedBwaMemMainController;
