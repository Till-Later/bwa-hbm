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

architecture AxiRdMultiplexer of {{identifier}} is
  alias ai_sys is {{x_psys.identifier}};

  alias am_axiRd_ms is {{x_pm_axiRd.identifier_ms}};
  alias am_axiRd_sm is {{x_pm_axiRd.identifier_sm}};

  alias as_axiRds_ms is {{x_ps_axiRds.identifier_ms}};
  alias as_axiRds_sm is {{x_ps_axiRds.identifier_sm}};

  -- Address Channel AR or AW:
  type t_NativeAxiA_od is record
    addr    : {{x_pm_axiRd.type.x_taddr.qualified}};
    len     : {{x_pm_axiRd.type.x_tlen.qualified}};
    size    : {{x_pm_axiRd.type.x_tsize.qualified}};
    burst   : {{x_pm_axiRd.type.x_tburst.qualified}};
    lock    : {{x_pm_axiRd.type.x_tlock.qualified}};
    cache   : {{x_pm_axiRd.type.x_tcache.qualified}};
    prot    : {{x_pm_axiRd.type.x_tprot.qualified}};
    qos     : {{x_pm_axiRd.type.x_tqos.qualified}};
    region  : {{x_pm_axiRd.type.x_tregion.qualified}};
    id      : {{x_pm_axiRd.type.x_tid.qualified}};
    user    : {{x_pm_axiRd.type.x_taruser.qualified}};
    valid   : {{x_pm_axiRd.type.x_tlogic.qualified}};
  end record;
  type t_NativeAxiA_do is record
    ready   : {{x_pm_axiRd.type.x_tlogic.qualified}};
  end record;

  constant c_NativeAxiANull_od : t_NativeAxiA_od := (
    addr    => {{x_pm_axiRd.type.x_taddr.x_cnull.qualified}},
    len     => {{x_pm_axiRd.type.x_tlen.x_cnull.qualified}},
    size    => {{x_pm_axiRd.type.x_tsize.x_cnull.qualified}},
    burst   => {{x_pm_axiRd.type.x_tburst.x_cnull.qualified}},
    lock    => {{x_pm_axiRd.type.x_tlock.x_cnull.qualified}},
    cache   => {{x_pm_axiRd.type.x_tcache.x_cnull.qualified}},
    prot    => {{x_pm_axiRd.type.x_tprot.x_cnull.qualified}},
    qos     => {{x_pm_axiRd.type.x_tqos.x_cnull.qualified}},
    region  => {{x_pm_axiRd.type.x_tregion.x_cnull.qualified}},
    id      => {{x_pm_axiRd.type.x_tid.x_cnull.qualified}},
    user    => {{x_pm_axiRd.type.x_taruser.x_cnull.qualified}},
    valid   => {{x_pm_axiRd.type.x_tlogic.x_cnull.qualified}});

  constant c_NativeAxiANull_do : t_NativeAxiA_do := (
    ready  => {{x_pm_axiRd.type.x_tlogic.x_cnull.qualified}});
  type t_NativeAxiA_v_od is array (integer range <>) of t_NativeAxiA_od;
  type t_NativeAxiA_v_do is array (integer range <>) of t_NativeAxiA_do;

  -- Read Channel R:
  type t_NativeAxiR_od is record
    data    : {{x_pm_axiRd.type.x_tdata.qualified}};
    resp    : {{x_pm_axiRd.type.x_tresp.qualified}};
    last    : {{x_pm_axiRd.type.x_tlogic.qualified}};
    id      : {{x_pm_axiRd.type.x_tid.qualified}};
    user    : {{x_pm_axiRd.type.x_truser.qualified}};
    valid   : {{x_pm_axiRd.type.x_tlogic.qualified}};
  end record;
  type t_NativeAxiR_do is record
    ready   : {{x_pm_axiRd.type.x_tlogic.qualified}};
  end record;
  constant c_NativeAxiRNull_od : t_NativeAxiR_od := (
    data    => {{x_pm_axiRd.type.x_tdata.x_cnull.qualified}},
    resp    => {{x_pm_axiRd.type.x_tresp.x_cnull.qualified}},
    last    => {{x_pm_axiRd.type.x_tlogic.x_cnull.qualified}},
    id    => {{x_pm_axiRd.type.x_tid.x_cnull.qualified}},
    user    => {{x_pm_axiRd.type.x_truser.x_cnull.qualified}},
    valid   => {{x_pm_axiRd.type.x_tlogic.x_cnull.qualified}});
  constant c_NativeAxiRNull_do : t_NativeAxiR_do := (
    ready   => {{x_pm_axiRd.type.x_tlogic.x_cnull.qualified}});
  type t_NativeAxiR_v_od is array (integer range <>) of t_NativeAxiR_od;
  type t_NativeAxiR_v_do is array (integer range <>) of t_NativeAxiR_do;

  subtype t_PortVector is unsigned (g_PortCount-1 downto 0);
  constant c_PortNumberWidth : natural := f_clog2(g_PortCount);
  subtype t_PortNumber is unsigned (c_PortNumberWidth-1 downto 0);

  -- Separate Address and Read Channels:
  signal so_masterA_od   : t_NativeAxiA_od;
  signal si_masterA_do   : t_NativeAxiA_do;
  signal so_masterR_do   : t_NativeAxiR_do;
  signal si_masterR_od   : t_NativeAxiR_od;

  signal si_slavesA_od   : t_NativeAxiA_v_od(g_PortCount-1 downto 0);
  signal so_slavesA_do   : t_NativeAxiA_v_do(g_PortCount-1 downto 0);
  signal si_slavesR_do   : t_NativeAxiR_v_do(g_PortCount-1 downto 0);
  signal so_slavesR_od   : t_NativeAxiR_v_od(g_PortCount-1 downto 0);

  -- Address Channel Arbiter and Switch:
  signal s_arbitRequest  : t_PortVector;
  signal s_arbitPort     : t_PortNumber;
  signal s_arbitValid   : std_logic;
  signal s_arbitReady     : std_logic;

  signal s_barDone       : unsigned(1 downto 0);
  alias a_barDoneA is s_barDone(0);
  alias a_barDoneR is s_barDone(1);
  signal s_barMask       : unsigned(1 downto 0);
  alias a_barMaskA is s_barMask(0);
  alias a_barMaskR is s_barMask(1);
  signal s_barContinue   : std_logic;

  signal s_switchAEnable : std_logic;
  signal s_switchASelect : t_PortNumber;
  signal s_slavesAValid  : t_PortVector;

  -- Read Channel FIFO and Switch:
  signal s_fifoRInReady  : std_logic;
  signal s_fifoRInValid  : std_logic;

  signal s_fifoROutPort  : t_PortNumber;
  signal s_fifoROutReady : std_logic;
  signal s_fifoROutValid : std_logic;

  signal s_switchREnable : std_logic;
  signal s_switchRSelect : t_PortNumber;

begin

  -- Separate NativeAxiRd Address and Read Channels:
  process (am_axiRd_sm, so_masterA_od, so_masterR_do,
           as_axiRds_ms, so_slavesA_do, so_slavesR_od)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    -- am_axiRd_ms <= f_nativeAxiRdJoin_ms(so_masterA_od, so_masterR_do);
    am_axiRd_ms.araddr   <= so_masterA_od.addr;
    am_axiRd_ms.arlen    <= so_masterA_od.len;
    am_axiRd_ms.arsize   <= so_masterA_od.size;
    am_axiRd_ms.arburst  <= so_masterA_od.burst;
    am_axiRd_ms.arlock     <= so_masterA_od.lock;
    am_axiRd_ms.arcache     <= so_masterA_od.cache;
    am_axiRd_ms.arprot     <= so_masterA_od.prot;
    am_axiRd_ms.arqos     <= so_masterA_od.qos;
    am_axiRd_ms.arregion     <= so_masterA_od.region;
    am_axiRd_ms.arid     <= so_masterA_od.id;
    am_axiRd_ms.aruser     <= so_masterA_od.user;
    am_axiRd_ms.arvalid  <= so_masterA_od.valid;
    am_axiRd_ms.rready   <= so_masterR_do.ready;



    -- si_masterA_do <= f_nativeAxiRdSplitA_sm(am_axiRd_sm);
    si_masterA_do.ready <= am_axiRd_sm.arready;

    -- si_masterR_od <= f_nativeAxiRdSplitR_sm(am_axiRd_sm);
    si_masterR_od.data   <= am_axiRd_sm.rdata;
    si_masterR_od.resp   <= am_axiRd_sm.rresp;
    si_masterR_od.last   <= am_axiRd_sm.rlast;
    si_masterR_od.id   <= am_axiRd_sm.rid;
    si_masterR_od.user   <= am_axiRd_sm.ruser;
    si_masterR_od.valid  <= am_axiRd_sm.rvalid;

    for v_idx in 0 to g_PortCount-1 loop
      -- as_axiRds_sm(v_idx) <= f_nativeAxiRdJoin_sm(so_slavesA_do(v_idx), so_slavesR_od(v_idx));
      as_axiRds_sm(v_idx).arready  <= so_slavesA_do(v_idx).ready;
      as_axiRds_sm(v_idx).rdata    <= so_slavesR_od(v_idx).data;
      as_axiRds_sm(v_idx).rresp    <= so_slavesR_od(v_idx).resp;
      as_axiRds_sm(v_idx).rlast    <= so_slavesR_od(v_idx).last;
      as_axiRds_sm(v_idx).rid      <= so_slavesR_od(v_idx).id;
      as_axiRds_sm(v_idx).ruser    <= so_slavesR_od(v_idx).user;
      as_axiRds_sm(v_idx).rvalid   <= so_slavesR_od(v_idx).valid;


      -- si_slavesA_od(v_idx) <= f_nativeAxiRdSplitA_ms(as_axiRds_ms(v_idx));
      si_slavesA_od(v_idx).addr   <= as_axiRds_ms(v_idx).araddr;
      si_slavesA_od(v_idx).len    <= as_axiRds_ms(v_idx).arlen;
      si_slavesA_od(v_idx).size   <= as_axiRds_ms(v_idx).arsize;
      si_slavesA_od(v_idx).burst  <= as_axiRds_ms(v_idx).arburst;
      si_slavesA_od(v_idx).lock  <= as_axiRds_ms(v_idx).arlock;
      si_slavesA_od(v_idx).cache  <= as_axiRds_ms(v_idx).arcache;
      si_slavesA_od(v_idx).prot  <= as_axiRds_ms(v_idx).arprot;
      si_slavesA_od(v_idx).qos  <= as_axiRds_ms(v_idx).arqos;
      si_slavesA_od(v_idx).region  <= as_axiRds_ms(v_idx).arregion;
      si_slavesA_od(v_idx).id  <= as_axiRds_ms(v_idx).arid;
      si_slavesA_od(v_idx).user  <= as_axiRds_ms(v_idx).aruser;
      si_slavesA_od(v_idx).valid  <= as_axiRds_ms(v_idx).arvalid;

      -- si_slavesR_do(v_idx) <= f_nativeAxiRdSplitR_ms(as_axiRds_ms(v_idx));
      si_slavesR_do(v_idx).ready  <= as_axiRds_ms(v_idx).rready;

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
      g_Count => 2)
    port map (
      pi_clk => ai_sys.clk,
      pi_rst_n => ai_sys.rst_n,
      pi_signal => s_barDone,
      po_mask => s_barMask,
      po_continue => s_barContinue);


  -- Address Channel Switch:
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

  -- Read Channel FIFO:
  s_fifoRInValid <= s_arbitValid and not a_barMaskR;
  a_barDoneR <= s_fifoRInValid and s_fifoRInReady;
  i_fifoR : entity work.UtilFastFIFO
    generic map (
      g_DataWidth => c_PortNumberWidth,
      g_LogDepth  => g_FIFOLogDepth)
    port map (
      pi_clk      => ai_sys.clk,
      pi_rst_n    => ai_sys.rst_n,
      pi_inData   => s_arbitPort,
      pi_inValid  => s_fifoRInValid,
      po_inReady  => s_fifoRInReady,
      po_outData  => s_fifoROutPort,
      po_outValid => s_fifoROutValid,
      pi_outReady => s_fifoROutReady);

  -- Read Channel Switch:
  s_switchREnable <= s_fifoROutValid;
  s_switchRSelect <= s_fifoROutPort;
  s_fifoROutReady <= si_masterR_od.valid and si_masterR_od.last and so_masterR_do.ready;
  process (s_switchREnable, s_switchRSelect, si_masterR_od, si_slavesR_do)
    variable v_idx : integer range 0 to g_PortCount-1;
  begin
    so_masterR_do <= c_NativeAxiRNull_do;
    for v_idx in 0 to g_PortCount-1 loop
      so_slavesR_od(v_idx) <= c_NativeAxiRNull_od;
      if s_switchREnable = '1' and
          v_idx = to_integer(s_switchRSelect) then
        so_masterR_do <= si_slavesR_do(v_idx);
        so_slavesR_od(v_idx) <= si_masterR_od;
      end if;
    end loop;
  end process;

end AxiRdMultiplexer;
