library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

{{#dependencies}}
use work.{{identifier}};
{{/dependencies}}
use work.util.all;


entity {{identifier}} is
  {{?generics}}
    generic (
  {{# generics}}
  {{#  is_complex}}
      {{identifier_ms}} : {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
      {{identifier_sm}} : {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
  {{|  is_complex}}
      {{identifier}} : {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
  {{/  is_complex}}
  {{/ generics}}
  {{/generics}}
  {{?ports}}
    port (
  {{# ports}}
  {{#  is_complex}}
      {{identifier_ms}} : {{mode_ms}} {{#is_scalar}}{{type.qualified_ms}}{{|is_scalar}}{{type.qualified_v_ms}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}};
      {{identifier_sm}} : {{mode_sm}} {{#is_scalar}}{{type.qualified_sm}}{{|is_scalar}}{{type.qualified_v_sm}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
  {{|  is_complex}}
      {{identifier}} : {{mode}} {{#is_scalar}}{{type.qualified}}{{|is_scalar}}{{type.qualified_v}} (0 to {{=size}}{{?is_literal}}{{=type}}{{=value}}{{*..x_format}}{{/value}}{{/type}}{{|is_literal}}{{qualified}}{{/is_literal}}{{/size}}-1){{/is_scalar}}{{?_last}}){{/_last}};
  {{/  is_complex}}
  {{/ ports}}
  {{/ports}}
end {{identifier}};

architecture AxiWrMultiplexer of {{identifier}} is
  alias ai_sys is {{x_psys.identifier}};

  alias am_axiWr_ms is {{x_pm_axiWr.identifier_ms}};
  alias am_axiWr_sm is {{x_pm_axiWr.identifier_sm}};

  alias as_axiWrs_ms is {{x_ps_axiWrs.identifier_ms}};
  alias as_axiWrs_sm is {{x_ps_axiWrs.identifier_sm}};

  subtype t_PortVector is unsigned (g_PortCount-1 downto 0);
  constant c_PortNumberWidth : natural := f_clog2(g_PortCount);
  subtype t_PortNumber is unsigned (c_PortNumberWidth-1 downto 0);

  -- Address Channel AR or AW:
  type t_NativeAxiA_od is record
    addr    : {{x_pm_axiWr.type.x_taddr.qualified}};
    len     : {{x_pm_axiWr.type.x_tlen.qualified}};
    size    : {{x_pm_axiWr.type.x_tsize.qualified}};
    burst   : {{x_pm_axiWr.type.x_tburst.qualified}};
    lock    : {{x_pm_axiWr.type.x_tlock.qualified}};
    cache   : {{x_pm_axiWr.type.x_tcache.qualified}};
    prot    : {{x_pm_axiWr.type.x_tprot.qualified}};
    qos     : {{x_pm_axiWr.type.x_tqos.qualified}};
    region  : {{x_pm_axiWr.type.x_tregion.qualified}};
    id      : {{x_pm_axiWr.type.x_tid.qualified}};
    user    : {{x_pm_axiWr.type.x_tawuser.qualified}};
    valid   : {{x_pm_axiWr.type.x_tlogic.qualified}};
  end record;
  type t_NativeAxiA_do is record
    ready   : {{x_pm_axiWr.type.x_tlogic.qualified}};
  end record;

  constant c_NativeAxiANull_od : t_NativeAxiA_od := (
    addr    => {{x_pm_axiWr.type.x_taddr.x_cnull.qualified}},
    len     => {{x_pm_axiWr.type.x_tlen.x_cnull.qualified}},
    size    => {{x_pm_axiWr.type.x_tsize.x_cnull.qualified}},
    burst   => {{x_pm_axiWr.type.x_tburst.x_cnull.qualified}},
    lock    => {{x_pm_axiWr.type.x_tlock.x_cnull.qualified}},
    cache   => {{x_pm_axiWr.type.x_tcache.x_cnull.qualified}},
    prot    => {{x_pm_axiWr.type.x_tprot.x_cnull.qualified}},
    qos     => {{x_pm_axiWr.type.x_tqos.x_cnull.qualified}},
    region  => {{x_pm_axiWr.type.x_tregion.x_cnull.qualified}},
    id      => {{x_pm_axiWr.type.x_tid.x_cnull.qualified}},
    user    => {{x_pm_axiWr.type.x_taruser.x_cnull.qualified}},
    valid   => {{x_pm_axiWr.type.x_tlogic.x_cnull.qualified}});

  constant c_NativeAxiANull_do : t_NativeAxiA_do := (
    ready  => {{x_pm_axiWr.type.x_tlogic.x_cnull.qualified}});
  type t_NativeAxiA_v_od is array (integer range <>) of t_NativeAxiA_od;
  type t_NativeAxiA_v_do is array (integer range <>) of t_NativeAxiA_do;

  -- Write Channel W:
  type t_NativeAxiW_od is record
    data    : {{x_pm_axiWr.type.x_tdata.qualified}};
    strb    : {{x_pm_axiWr.type.x_tstrb.qualified}};
    last    : {{x_pm_axiWr.type.x_tlogic.qualified}};
    user    : {{x_pm_axiWr.type.x_twuser.qualified}};
    valid   : {{x_pm_axiWr.type.x_tlogic.qualified}};
  end record;
  type t_NativeAxiW_do is record
    ready   : {{x_pm_axiWr.type.x_tlogic.qualified}};
  end record;
  constant c_NativeAxiWNull_od : t_NativeAxiW_od := (
    data    => {{x_pm_axiWr.type.x_tdata.x_cnull.qualified}},
    strb    => {{x_pm_axiWr.type.x_tstrb.x_cnull.qualified}},
    last    => {{x_pm_axiWr.type.x_tlogic.x_cnull.qualified}},
    user    => {{x_pm_axiWr.type.x_twuser.x_cnull.qualified}},
    valid   => {{x_pm_axiWr.type.x_tlogic.x_cnull.qualified}});
  constant c_NativeAxiWNull_do : t_NativeAxiW_do := (
    ready   => {{x_pm_axiWr.type.x_tlogic.x_cnull.qualified}});
  type t_NativeAxiW_v_od is array (integer range <>) of t_NativeAxiW_od;
  type t_NativeAxiW_v_do is array (integer range <>) of t_NativeAxiW_do;

  -- Write Response Channel B:
  type t_NativeAxiB_od is record
    resp    : {{x_pm_axiWr.type.x_tresp.qualified}};
    id    : {{x_pm_axiWr.type.x_tid.qualified}};
    user    : {{x_pm_axiWr.type.x_tbuser.qualified}};
    valid   : {{x_pm_axiWr.type.x_tlogic.qualified}};
  end record;
  type t_NativeAxiB_do is record
    ready   : {{x_pm_axiWr.type.x_tlogic.qualified}};
  end record;
  constant c_NativeAxiBNull_od : t_NativeAxiB_od := (
    resp    => {{x_pm_axiWr.type.x_tresp.x_cnull.qualified}},
    id      => {{x_pm_axiWr.type.x_tid.x_cnull.qualified}},
    user    => {{x_pm_axiWr.type.x_tbuser.x_cnull.qualified}},
    valid   => {{x_pm_axiWr.type.x_tlogic.x_cnull.qualified}});
  constant c_NativeAxiBNull_do : t_NativeAxiB_do := (
    ready   => {{x_pm_axiWr.type.x_tlogic.x_cnull.qualified}});
  type t_NativeAxiB_v_od is array (integer range <>) of t_NativeAxiB_od;
  type t_NativeAxiB_v_do is array (integer range <>) of t_NativeAxiB_do;

  -- Separate Address, Write and Response Channels:
  signal so_masterA_od   : t_NativeAxiA_od;
  signal si_masterA_do   : t_NativeAxiA_do;
  signal so_masterW_od   : t_NativeAxiW_od;
  signal si_masterW_do   : t_NativeAxiW_do;
  signal so_masterB_do   : t_NativeAxiB_do;
  signal si_masterB_od   : t_NativeAxiB_od;

  signal si_slavesA_od   : t_NativeAxiA_v_od(g_PortCount-1 downto 0);
  signal so_slavesA_do   : t_NativeAxiA_v_do(g_PortCount-1 downto 0);
  signal si_slavesW_od   : t_NativeAxiW_v_od(g_PortCount-1 downto 0);
  signal so_slavesW_do   : t_NativeAxiW_v_do(g_PortCount-1 downto 0);
  signal si_slavesB_do   : t_NativeAxiB_v_do(g_PortCount-1 downto 0);
  signal so_slavesB_od   : t_NativeAxiB_v_od(g_PortCount-1 downto 0);

  -- Address/Write Channel Arbiter and Switches:
  signal s_arbitRequest  : t_PortVector;
  signal s_arbitPort     : t_PortNumber;
  signal s_arbitValid   : std_logic;
  signal s_arbitReady     : std_logic;

  signal s_barDone       : unsigned(2 downto 0);
  alias a_barDoneA is s_barDone(0);
  alias a_barDoneW is s_barDone(1);
  alias a_barDoneB is s_barDone(2);
  signal s_barMask       : unsigned(2 downto 0);
  alias a_barMaskA is s_barMask(0);
  alias a_barMaskW is s_barMask(1);
  alias a_barMaskB is s_barMask(2);
  signal s_barContinue   : std_logic;

  signal s_switchAEnable : std_logic;
  signal s_switchASelect : t_PortNumber;
  signal s_slavesAValid  : t_PortVector;

  -- Write Channel FIFO and Switch:
  signal s_fifoWInReady  : std_logic;
  signal s_fifoWInValid  : std_logic;

  signal s_fifoWOutPort  : t_PortNumber;
  signal s_fifoWOutReady : std_logic;
  signal s_fifoWOutValid : std_logic;

  signal s_switchWEnable : std_logic;
  signal s_switchWSelect : t_PortNumber;

  -- Response Channel FIFO and Switch:
  signal s_fifoBInValid  : std_logic;
  signal s_fifoBInReady  : std_logic;

  signal s_fifoBOutPort  : t_PortNumber;
  signal s_fifoBOutValid : std_logic;
  signal s_fifoBOutReady : std_logic;

  signal s_switchBEnable : std_logic;
  signal s_switchBSelect : t_PortNumber;

begin

  -- Separate Address, Write and Response Channels:
  process (am_axiWr_sm, so_masterA_od, so_masterW_od, so_masterB_do,
           as_axiWrs_ms, so_slavesA_do, so_slavesW_do, so_slavesB_od)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    -- am_axiWr_ms <= f_nativeAxiWrJoin_ms(so_masterA_od, so_masterW_od, so_masterB_do);
    am_axiWr_ms.awaddr   <= so_masterA_od.addr;
    am_axiWr_ms.awlen    <= so_masterA_od.len;
    am_axiWr_ms.awsize   <= so_masterA_od.size;
    am_axiWr_ms.awburst  <= so_masterA_od.burst;
    am_axiWr_ms.awlock   <= so_masterA_od.lock;
    am_axiWr_ms.awcache  <= so_masterA_od.cache;
    am_axiWr_ms.awprot   <= so_masterA_od.prot;
    am_axiWr_ms.awqos    <= so_masterA_od.qos;
    am_axiWr_ms.awregion <= so_masterA_od.region;
    am_axiWr_ms.awid     <= so_masterA_od.id;
    am_axiWr_ms.awuser   <= so_masterA_od.user;
    am_axiWr_ms.awvalid  <= so_masterA_od.valid;
    am_axiWr_ms.wdata    <= so_masterW_od.data;
    am_axiWr_ms.wstrb    <= so_masterW_od.strb;
    am_axiWr_ms.wlast    <= so_masterW_od.last;
    am_axiWr_ms.wuser    <= so_masterW_od.user;
    am_axiWr_ms.wvalid   <= so_masterW_od.valid;
    am_axiWr_ms.bready   <= so_masterB_do.ready;

    -- si_masterA_do <= f_nativeAxiWrSplitA_sm(am_axiWr_sm);
    si_masterA_do.ready <= am_axiWr_sm.awready;

    -- si_masterW_do <= f_nativeAxiWrSplitW_sm(am_axiWr_sm);
    si_masterW_do.ready <= am_axiWr_sm.wready;

    -- si_masterB_od <= f_nativeAxiWrSplitB_sm(am_axiWr_sm);
    si_masterB_od.resp    <= am_axiWr_sm.bresp;
    si_masterB_od.id      <= am_axiWr_sm.bid;
    si_masterB_od.user    <= am_axiWr_sm.buser;
    si_masterB_od.valid   <= am_axiWr_sm.bvalid;

    for v_idx in 0 to g_PortCount-1 loop
      -- as_axiWrs_sm(v_idx) <= f_nativeAxiWrJoin_sm(so_slavesA_do(v_idx), so_slavesW_do(v_idx), so_slavesB_od(v_idx));
      as_axiWrs_sm(v_idx).awready  <= so_slavesA_do(v_idx).ready;
      as_axiWrs_sm(v_idx).wready   <= so_slavesW_do(v_idx).ready;
      as_axiWrs_sm(v_idx).bresp    <= so_slavesB_od(v_idx).resp;
      as_axiWrs_sm(v_idx).bid      <= so_slavesB_od(v_idx).id;
      as_axiWrs_sm(v_idx).buser    <= so_slavesB_od(v_idx).user;
      as_axiWrs_sm(v_idx).bvalid   <= so_slavesB_od(v_idx).valid;

      -- si_slavesA_od(v_idx) <= f_nativeAxiWrSplitA_ms(as_axiWrs_ms(v_idx));
      si_slavesA_od(v_idx).addr   <= as_axiWrs_ms(v_idx).awaddr;
      si_slavesA_od(v_idx).len    <= as_axiWrs_ms(v_idx).awlen;
      si_slavesA_od(v_idx).size   <= as_axiWrs_ms(v_idx).awsize;
      si_slavesA_od(v_idx).burst  <= as_axiWrs_ms(v_idx).awburst;
      si_slavesA_od(v_idx).lock   <= as_axiWrs_ms(v_idx).awlock;
      si_slavesA_od(v_idx).cache  <= as_axiWrs_ms(v_idx).awcache;
      si_slavesA_od(v_idx).prot   <= as_axiWrs_ms(v_idx).awprot;
      si_slavesA_od(v_idx).qos    <= as_axiWrs_ms(v_idx).awqos;
      si_slavesA_od(v_idx).region <= as_axiWrs_ms(v_idx).awregion;
      si_slavesA_od(v_idx).id     <= as_axiWrs_ms(v_idx).awid;
      si_slavesA_od(v_idx).user   <= as_axiWrs_ms(v_idx).awuser;
      si_slavesA_od(v_idx).valid  <= as_axiWrs_ms(v_idx).awvalid;

      -- si_slavesW_od(v_idx) <= f_nativeAxiWrSplitW_ms(as_axiWrs_ms(v_idx));
      si_slavesW_od(v_idx).data     <= as_axiWrs_ms(v_idx).wdata;
      si_slavesW_od(v_idx).strb     <= as_axiWrs_ms(v_idx).wstrb;
      si_slavesW_od(v_idx).last     <= as_axiWrs_ms(v_idx).wlast;
      si_slavesW_od(v_idx).user     <= as_axiWrs_ms(v_idx).wuser;
      si_slavesW_od(v_idx).valid    <= as_axiWrs_ms(v_idx).wvalid;

      -- si_slavesB_do(v_idx) <= f_nativeAxiWrSplitB_ms(as_axiWrs_ms(v_idx));
      si_slavesB_do(v_idx).ready   <= as_axiWrs_ms(v_idx).bready;
    end loop;
  end process;

  -- Address Channel Arbiter:
  s_arbitRequest <= s_slavesAValid;
  s_arbitReady <= s_barContinue;
  i_arbiter : entity work.UtilStableArbiter
    generic map (
      g_PortCount => g_PortCount)
    port map (
      pi_clk      => ai_sys.clk,
      pi_rst_n    => ai_sys.rst_n,
      pi_request  => s_arbitRequest,
      po_port     => s_arbitPort,
      po_valid    => s_arbitValid,
      pi_ready    => s_arbitReady);

  i_barrier : entity work.UtilBarrier
    generic map (
      g_Count => 3)
    port map (
      pi_clk => ai_sys.clk,
      pi_rst_n => ai_sys.rst_n,
      pi_signal => s_barDone,
      po_mask => s_barMask,
      po_continue => s_barContinue);

  -- Address Channel Switch
  s_switchAEnable <= s_arbitValid and not a_barMaskA;
  s_switchASelect <= s_arbitPort;
  a_barDoneA <= so_masterA_od.valid and si_masterA_do.ready;
  process (s_switchAEnable, s_switchASelect, si_slavesA_od, si_masterA_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterA_od <= c_NativeAxiANull_od;
    for v_idx in 0 to g_PortCount-1 loop
      s_slavesAValid(v_idx) <= si_slavesA_od(v_idx).valid;
      so_slavesA_do(v_idx) <= c_NativeAxiANull_do;
      if s_switchAEnable = '1' and
          v_idx = to_integer(s_switchASelect) then
        so_masterA_od <= si_slavesA_od(v_idx);
        so_slavesA_do(v_idx) <= si_masterA_do;
      end if;
    end loop;
  end process;

  -- Write Channel FIFO:
  s_fifoWInValid <= s_arbitValid and not a_barMaskW;
  a_barDoneW <= s_fifoWInValid and s_fifoWInReady;
  i_fifoW : entity work.UtilFastFIFO
    generic map (
      g_DataWidth => c_PortNumberWidth,
      g_LogDepth  => g_FIFOLogDepth)
    port map (
      pi_clk      => ai_sys.clk,
      pi_rst_n    => ai_sys.rst_n,
      pi_inData   => s_arbitPort,
      pi_inValid  => s_fifoWInValid,
      po_inReady  => s_fifoWInReady,
      po_outData  => s_fifoWOutPort,
      po_outValid => s_fifoWOutValid,
      pi_outReady => s_fifoWOutReady);

  -- Write Channel Switch
  s_switchWEnable <= s_fifoWOutValid;
  s_switchWSelect <= s_fifoWOutPort;
  s_fifoWOutReady <= so_masterW_od.valid and so_masterW_od.last and si_masterW_do.ready;
  process (s_switchWEnable, s_switchWSelect, si_slavesW_od, si_masterW_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterW_od <= c_NativeAxiWNull_od;
    for v_idx in 0 to g_PortCount-1 loop
      so_slavesW_do(v_idx) <= c_NativeAxiWNull_do;
      if s_switchWEnable = '1' and
          v_idx = to_integer(s_switchWSelect) then
        so_masterW_od <= si_slavesW_od(v_idx);
        so_slavesW_do(v_idx) <= si_masterW_do;
      end if;
    end loop;
  end process;

  -- Response Channel FIFO:
  s_fifoBInValid <= s_arbitValid and not a_barMaskB;
  a_barDoneB <= s_fifoBInValid and s_fifoBInReady;
  i_fifoB : entity work.UtilFastFIFO
    generic map (
      g_DataWidth => c_PortNumberWidth,
      g_LogDepth  => g_FIFOLogDepth)
    port map (
      pi_clk      => ai_sys.clk,
      pi_rst_n    => ai_sys.rst_n,
      pi_inData   => s_arbitPort,
      pi_inValid  => s_fifoBInValid,
      po_inReady  => s_fifoBInReady,
      po_outData  => s_fifoBOutPort,
      po_outValid => s_fifoBOutValid,
      pi_outReady => s_fifoBOutReady);

  -- Response Channel Switch
  s_switchBEnable <= s_fifoBOutValid;
  s_switchBSelect <= s_fifoBOutPort;
  s_fifoBOutReady <= si_masterB_od.valid and so_masterB_do.ready;
  process (s_switchBEnable, s_switchBSelect, si_masterB_od, si_slavesB_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterB_do <= c_NativeAxiBNull_do;
    for v_idx in 0 to g_PortCount-1 loop
      so_slavesB_od(v_idx) <= c_NativeAxiBNull_od;
      if s_switchBEnable = '1' and
          v_idx = to_integer(s_switchBSelect) then
        so_masterB_do <= si_slavesB_do(v_idx);
        so_slavesB_od(v_idx) <= si_masterB_od;
      end if;
    end loop;
  end process;

end AxiWrMultiplexer;
