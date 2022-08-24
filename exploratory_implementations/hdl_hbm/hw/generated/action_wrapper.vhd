library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto;
use work.dfaccto_axi;
use work.user;
use work.ocaccel;

entity action_wrapper is
  port (
    -- sys:
    ap_clk   : in std_logic;
    ap_rst_n : in std_logic;
    -- intr:
    interrupt     : out std_logic;
    interrupt_src : out std_logic_vector(64-1 downto 0);
    interrupt_ctx : out std_logic_vector(9-1 downto 0);
    interrupt_ack : in std_logic;
    -- ctrl:
    s_axi_ctrl_reg_awaddr   : in std_logic_vector(32-1 downto 0);
    s_axi_ctrl_reg_awvalid  : in std_logic;
    s_axi_ctrl_reg_awready  : out std_logic;
    s_axi_ctrl_reg_wdata    : in std_logic_vector(32-1 downto 0);
    s_axi_ctrl_reg_wstrb    : in std_logic_vector(4-1 downto 0);
    s_axi_ctrl_reg_wvalid   : in std_logic;
    s_axi_ctrl_reg_wready   : out std_logic;
    s_axi_ctrl_reg_bresp    : out std_logic_vector(2-1 downto 0);
    s_axi_ctrl_reg_bvalid   : out std_logic;
    s_axi_ctrl_reg_bready   : in std_logic;
    s_axi_ctrl_reg_araddr   : in std_logic_vector(32-1 downto 0);
    s_axi_ctrl_reg_arvalid  : in std_logic;
    s_axi_ctrl_reg_arready  : out std_logic;
    s_axi_ctrl_reg_rdata    : out std_logic_vector(32-1 downto 0);
    s_axi_ctrl_reg_rresp    : out std_logic_vector(2-1 downto 0);
    s_axi_ctrl_reg_rvalid   : out std_logic;
    s_axi_ctrl_reg_rready   : in std_logic;
    -- hmem:
    m_axi_host_mem_awaddr   : out std_logic_vector(64-1 downto 0);
    m_axi_host_mem_awlen    : out std_logic_vector(8-1 downto 0);
    m_axi_host_mem_awsize   : out std_logic_vector(3-1 downto 0);
    m_axi_host_mem_awburst  : out std_logic_vector(2-1 downto 0);
    m_axi_host_mem_awlock   : out std_logic_vector(2-1 downto 0);
    m_axi_host_mem_awcache  : out std_logic_vector(4-1 downto 0);
    m_axi_host_mem_awprot   : out std_logic_vector(3-1 downto 0);
    m_axi_host_mem_awqos    : out std_logic_vector(4-1 downto 0);
    m_axi_host_mem_awregion : out std_logic_vector(4-1 downto 0);
    m_axi_host_mem_awid     : out std_logic_vector(1-1 downto 0);
    m_axi_host_mem_awuser   : out std_logic_vector(9-1 downto 0);
    m_axi_host_mem_awvalid  : out std_logic;
    m_axi_host_mem_awready  : in std_logic;
    m_axi_host_mem_wdata    : out std_logic_vector(1024-1 downto 0);
    m_axi_host_mem_wstrb    : out std_logic_vector(128-1 downto 0);
    m_axi_host_mem_wlast    : out std_logic;
    m_axi_host_mem_wuser    : out std_logic_vector(9-1 downto 0);
    m_axi_host_mem_wvalid   : out std_logic;
    m_axi_host_mem_wready   : in std_logic;
    m_axi_host_mem_bresp    : in std_logic_vector(2-1 downto 0);
    m_axi_host_mem_bid      : in std_logic_vector(1-1 downto 0);
    m_axi_host_mem_buser    : in std_logic_vector(9-1 downto 0);
    m_axi_host_mem_bvalid   : in std_logic;
    m_axi_host_mem_bready   : out std_logic;
    m_axi_host_mem_araddr   : out std_logic_vector(64-1 downto 0);
    m_axi_host_mem_arlen    : out std_logic_vector(8-1 downto 0);
    m_axi_host_mem_arsize   : out std_logic_vector(3-1 downto 0);
    m_axi_host_mem_arburst  : out std_logic_vector(2-1 downto 0);
    m_axi_host_mem_arlock   : out std_logic_vector(2-1 downto 0);
    m_axi_host_mem_arcache  : out std_logic_vector(4-1 downto 0);
    m_axi_host_mem_arprot   : out std_logic_vector(3-1 downto 0);
    m_axi_host_mem_arqos    : out std_logic_vector(4-1 downto 0);
    m_axi_host_mem_arregion : out std_logic_vector(4-1 downto 0);
    m_axi_host_mem_arid     : out std_logic_vector(1-1 downto 0);
    m_axi_host_mem_aruser   : out std_logic_vector(9-1 downto 0);
    m_axi_host_mem_arvalid  : out std_logic;
    m_axi_host_mem_arready  : in std_logic;
    m_axi_host_mem_rdata    : in std_logic_vector(1024-1 downto 0);
    m_axi_host_mem_rresp    : in std_logic_vector(2-1 downto 0);
    m_axi_host_mem_rlast    : in std_logic;
    m_axi_host_mem_rid      : in std_logic_vector(1-1 downto 0);
    m_axi_host_mem_ruser    : in std_logic_vector(9-1 downto 0);
    m_axi_host_mem_rvalid   : in std_logic;
    m_axi_host_mem_rready   : out std_logic;
    -- hbm0:
    m_axi_card_hbm_p0_awaddr   : out std_logic_vector(34-1 downto 0);
    m_axi_card_hbm_p0_awlen    : out std_logic_vector(8-1 downto 0);
    m_axi_card_hbm_p0_awsize   : out std_logic_vector(3-1 downto 0);
    m_axi_card_hbm_p0_awburst  : out std_logic_vector(2-1 downto 0);
    m_axi_card_hbm_p0_awlock   : out std_logic_vector(2-1 downto 0);
    m_axi_card_hbm_p0_awcache  : out std_logic_vector(4-1 downto 0);
    m_axi_card_hbm_p0_awprot   : out std_logic_vector(3-1 downto 0);
    m_axi_card_hbm_p0_awqos    : out std_logic_vector(4-1 downto 0);
    m_axi_card_hbm_p0_awregion : out std_logic_vector(4-1 downto 0);
    m_axi_card_hbm_p0_awid     : out std_logic_vector(6-1 downto 0);
    m_axi_card_hbm_p0_awuser   : out std_logic_vector(1-1 downto 0);
    m_axi_card_hbm_p0_awvalid  : out std_logic;
    m_axi_card_hbm_p0_awready  : in std_logic;
    m_axi_card_hbm_p0_wdata    : out std_logic_vector(256-1 downto 0);
    m_axi_card_hbm_p0_wstrb    : out std_logic_vector(32-1 downto 0);
    m_axi_card_hbm_p0_wlast    : out std_logic;
    m_axi_card_hbm_p0_wuser    : out std_logic_vector(1-1 downto 0);
    m_axi_card_hbm_p0_wvalid   : out std_logic;
    m_axi_card_hbm_p0_wready   : in std_logic;
    m_axi_card_hbm_p0_bresp    : in std_logic_vector(2-1 downto 0);
    m_axi_card_hbm_p0_bid      : in std_logic_vector(6-1 downto 0);
    m_axi_card_hbm_p0_buser    : in std_logic_vector(1-1 downto 0);
    m_axi_card_hbm_p0_bvalid   : in std_logic;
    m_axi_card_hbm_p0_bready   : out std_logic;
    m_axi_card_hbm_p0_araddr   : out std_logic_vector(34-1 downto 0);
    m_axi_card_hbm_p0_arlen    : out std_logic_vector(8-1 downto 0);
    m_axi_card_hbm_p0_arsize   : out std_logic_vector(3-1 downto 0);
    m_axi_card_hbm_p0_arburst  : out std_logic_vector(2-1 downto 0);
    m_axi_card_hbm_p0_arlock   : out std_logic_vector(2-1 downto 0);
    m_axi_card_hbm_p0_arcache  : out std_logic_vector(4-1 downto 0);
    m_axi_card_hbm_p0_arprot   : out std_logic_vector(3-1 downto 0);
    m_axi_card_hbm_p0_arqos    : out std_logic_vector(4-1 downto 0);
    m_axi_card_hbm_p0_arregion : out std_logic_vector(4-1 downto 0);
    m_axi_card_hbm_p0_arid     : out std_logic_vector(6-1 downto 0);
    m_axi_card_hbm_p0_aruser   : out std_logic_vector(1-1 downto 0);
    m_axi_card_hbm_p0_arvalid  : out std_logic;
    m_axi_card_hbm_p0_arready  : in std_logic;
    m_axi_card_hbm_p0_rdata    : in std_logic_vector(256-1 downto 0);
    m_axi_card_hbm_p0_rresp    : in std_logic_vector(2-1 downto 0);
    m_axi_card_hbm_p0_rlast    : in std_logic;
    m_axi_card_hbm_p0_rid      : in std_logic_vector(6-1 downto 0);
    m_axi_card_hbm_p0_ruser    : in std_logic_vector(1-1 downto 0);
    m_axi_card_hbm_p0_rvalid   : in std_logic;
    m_axi_card_hbm_p0_rready   : out std_logic);
end action_wrapper;

architecture ExternalWrapper of action_wrapper is

-- Internal Ports

  -- sys
  signal pi_sys : dfaccto.t_Sys;
  -- intr
  signal po_intr_ms : ocaccel.t_Interrupt_ms;
  signal pi_intr_sm : ocaccel.t_Interrupt_sm;
  -- ctrl
  signal pi_ctrl_ms : ocaccel.t_AxiCtrl_ms;
  signal po_ctrl_sm : ocaccel.t_AxiCtrl_sm;
  -- hmem
  signal po_hmem_ms : ocaccel.t_AxiHost_ms;
  signal pi_hmem_sm : ocaccel.t_AxiHost_sm;
  -- hbm0
  signal po_hbm0_ms : ocaccel.t_AxiHbm_ms;
  signal pi_hbm0_sm : ocaccel.t_AxiHbm_sm;

-- Signals

  signal s_hbmRd_ms : ocaccel.t_AxiHbmRd_ms;
  signal s_hbmRd_sm : ocaccel.t_AxiHbmRd_sm;
  signal s_hbmWr_ms : ocaccel.t_AxiHbmWr_ms;
  signal s_hbmWr_sm : ocaccel.t_AxiHbmWr_sm;
  signal s_stmRd_ms : user.t_StmHbm_ms;
  signal s_stmRd_sm : user.t_StmHbm_sm;
  signal s_regsRd_ms : user.t_RegPort_ms;
  signal s_regsRd_sm : user.t_RegPort_sm;
  signal s_startRd : dfaccto.t_Logic;
  signal s_readyRd : dfaccto.t_Logic;
  signal s_stmWr_ms : user.t_StmHbm_ms;
  signal s_stmWr_sm : user.t_StmHbm_sm;
  signal s_regsWr_ms : user.t_RegPort_ms;
  signal s_regsWr_sm : user.t_RegPort_sm;
  signal s_startWr : dfaccto.t_Logic;
  signal s_readyWr : dfaccto.t_Logic;

begin

  -- Instantiations

  i_hbm_splitter : entity work.AxiSplitter
    port map (
      pi_sys => pi_sys,
      po_axi_ms => po_hbm0_ms,
      pi_axi_sm => pi_hbm0_sm,
      pi_axiRd_ms => s_hbmRd_ms,
      po_axiRd_sm => s_hbmRd_sm,
      pi_axiWr_ms => s_hbmWr_ms,
      po_axiWr_sm => s_hbmWr_sm);
  i_hbm_reader : entity work.AxiReader
    generic map (
      g_FIFOLogDepth => 4)
    port map (
      pi_sys => pi_sys,
      pi_start => s_startRd,
      po_ready => s_readyRd,
      pi_regs_ms => s_regsRd_ms,
      po_regs_sm => s_regsRd_sm,
      po_status => open,
      po_axiRd_ms => s_hbmRd_ms,
      pi_axiRd_sm => s_hbmRd_sm,
      po_axiStm_ms => s_stmRd_ms,
      pi_axiStm_sm => s_stmRd_sm);
  i_hbm_writer : entity work.AxiWriter
    generic map (
      g_FIFOLogDepth => 4)
    port map (
      pi_sys => pi_sys,
      pi_start => s_startWr,
      po_ready => s_readyWr,
      pi_regs_ms => s_regsWr_ms,
      po_regs_sm => s_regsWr_sm,
      po_status => open,
      pi_axiStm_ms => s_stmWr_ms,
      po_axiStm_sm => s_stmWr_sm,
      po_axiWr_ms => s_hbmWr_ms,
      pi_axiWr_sm => s_hbmWr_sm);
  i_hbm_benchmark_controller : entity work.HbmBenchmarkController
    port map (
      pi_sys => pi_sys,
      po_axiStmWr_ms => s_stmWr_ms,
      pi_axiStmWr_sm => s_stmWr_sm,
      pi_axiStmRd_ms => s_stmRd_ms,
      po_axiStmRd_sm => s_stmRd_sm,
      po_regsRd_ms => s_regsRd_ms,
      pi_regsRd_sm => s_regsRd_sm,
      po_regsWr_ms => s_regsWr_ms,
      pi_regsWr_sm => s_regsWr_sm,
      po_startRd => s_startRd,
      pi_readyRd => s_readyRd,
      po_startWr => s_startWr,
      pi_readyWr => s_readyWr);


  -- Port Mapping

  -- sys
  pi_sys.clk   <= ap_clk;
  pi_sys.rst_n <= ap_rst_n;
  -- intr
  interrupt     <= po_intr_ms.stb;
  interrupt_src <= std_logic_vector(po_intr_ms.src);
  interrupt_ctx <= std_logic_vector(po_intr_ms.ctx);
  pi_intr_sm.ack <= interrupt_ack;
  -- ctrl
  pi_ctrl_ms.awaddr   <= ocaccel.t_AxiCtrlAddr(s_axi_ctrl_reg_awaddr);
  pi_ctrl_ms.awvalid  <= s_axi_ctrl_reg_awvalid;
  pi_ctrl_ms.wdata    <= ocaccel.t_AxiCtrlData(s_axi_ctrl_reg_wdata);
  pi_ctrl_ms.wstrb    <= ocaccel.t_AxiCtrlStrb(s_axi_ctrl_reg_wstrb);
  pi_ctrl_ms.wvalid   <= s_axi_ctrl_reg_wvalid;
  pi_ctrl_ms.bready   <= s_axi_ctrl_reg_bready;
  pi_ctrl_ms.araddr   <= ocaccel.t_AxiCtrlAddr(s_axi_ctrl_reg_araddr);
  pi_ctrl_ms.arvalid  <= s_axi_ctrl_reg_arvalid;
  pi_ctrl_ms.rready   <= s_axi_ctrl_reg_rready;
  s_axi_ctrl_reg_awready  <= po_ctrl_sm.awready;
  s_axi_ctrl_reg_wready   <= po_ctrl_sm.wready;
  s_axi_ctrl_reg_bresp    <= std_logic_vector(po_ctrl_sm.bresp);
  s_axi_ctrl_reg_bvalid   <= po_ctrl_sm.bvalid;
  s_axi_ctrl_reg_arready  <= po_ctrl_sm.arready;
  s_axi_ctrl_reg_rdata    <= std_logic_vector(po_ctrl_sm.rdata);
  s_axi_ctrl_reg_rresp    <= std_logic_vector(po_ctrl_sm.rresp);
  s_axi_ctrl_reg_rvalid   <= po_ctrl_sm.rvalid;
  -- hmem
  m_axi_host_mem_awaddr   <= std_logic_vector(po_hmem_ms.awaddr);
  m_axi_host_mem_awlen    <= std_logic_vector(po_hmem_ms.awlen);
  m_axi_host_mem_awsize   <= std_logic_vector(po_hmem_ms.awsize);
  m_axi_host_mem_awburst  <= std_logic_vector(po_hmem_ms.awburst);
  m_axi_host_mem_awlock   <= std_logic_vector(po_hmem_ms.awlock);
  m_axi_host_mem_awcache  <= std_logic_vector(po_hmem_ms.awcache);
  m_axi_host_mem_awprot   <= std_logic_vector(po_hmem_ms.awprot);
  m_axi_host_mem_awqos    <= std_logic_vector(po_hmem_ms.awqos);
  m_axi_host_mem_awregion <= std_logic_vector(po_hmem_ms.awregion);
  m_axi_host_mem_awid     <= std_logic_vector(po_hmem_ms.awid);
  m_axi_host_mem_awuser   <= std_logic_vector(po_hmem_ms.awuser);
  m_axi_host_mem_awvalid  <= po_hmem_ms.awvalid;
  m_axi_host_mem_wdata    <= std_logic_vector(po_hmem_ms.wdata);
  m_axi_host_mem_wstrb    <= std_logic_vector(po_hmem_ms.wstrb);
  m_axi_host_mem_wlast    <= po_hmem_ms.wlast;
  m_axi_host_mem_wuser    <= std_logic_vector(po_hmem_ms.wuser);
  m_axi_host_mem_wvalid   <= po_hmem_ms.wvalid;
  m_axi_host_mem_bready   <= po_hmem_ms.bready;
  m_axi_host_mem_araddr   <= std_logic_vector(po_hmem_ms.araddr);
  m_axi_host_mem_arlen    <= std_logic_vector(po_hmem_ms.arlen);
  m_axi_host_mem_arsize   <= std_logic_vector(po_hmem_ms.arsize);
  m_axi_host_mem_arburst  <= std_logic_vector(po_hmem_ms.arburst);
  m_axi_host_mem_arlock   <= std_logic_vector(po_hmem_ms.arlock);
  m_axi_host_mem_arcache  <= std_logic_vector(po_hmem_ms.arcache);
  m_axi_host_mem_arprot   <= std_logic_vector(po_hmem_ms.arprot);
  m_axi_host_mem_arqos    <= std_logic_vector(po_hmem_ms.arqos);
  m_axi_host_mem_arregion <= std_logic_vector(po_hmem_ms.arregion);
  m_axi_host_mem_arid     <= std_logic_vector(po_hmem_ms.arid);
  m_axi_host_mem_aruser   <= std_logic_vector(po_hmem_ms.aruser);
  m_axi_host_mem_arvalid  <= po_hmem_ms.arvalid;
  m_axi_host_mem_rready   <= po_hmem_ms.rready;
  pi_hmem_sm.awready <= m_axi_host_mem_awready;
  pi_hmem_sm.wready  <= m_axi_host_mem_wready;
  pi_hmem_sm.bresp   <= dfaccto_axi.t_AxiResp(m_axi_host_mem_bresp);
  pi_hmem_sm.bid     <= ocaccel.t_AxiHostId(m_axi_host_mem_bid);
  pi_hmem_sm.buser   <= ocaccel.t_AxiHostBUser(m_axi_host_mem_buser);
  pi_hmem_sm.bvalid  <= m_axi_host_mem_bvalid;
  pi_hmem_sm.arready <= m_axi_host_mem_arready;
  pi_hmem_sm.rdata   <= ocaccel.t_AxiHostData(m_axi_host_mem_rdata);
  pi_hmem_sm.rresp   <= dfaccto_axi.t_AxiResp(m_axi_host_mem_rresp);
  pi_hmem_sm.rlast   <= m_axi_host_mem_rlast;
  pi_hmem_sm.rid     <= ocaccel.t_AxiHostId(m_axi_host_mem_rid);
  pi_hmem_sm.ruser   <= ocaccel.t_AxiHostRUser(m_axi_host_mem_ruser);
  pi_hmem_sm.rvalid  <= m_axi_host_mem_rvalid;
  -- hbm0
  m_axi_card_hbm_p0_awaddr   <= std_logic_vector(po_hbm0_ms.awaddr);
  m_axi_card_hbm_p0_awlen    <= std_logic_vector(po_hbm0_ms.awlen);
  m_axi_card_hbm_p0_awsize   <= std_logic_vector(po_hbm0_ms.awsize);
  m_axi_card_hbm_p0_awburst  <= std_logic_vector(po_hbm0_ms.awburst);
  m_axi_card_hbm_p0_awlock   <= std_logic_vector(po_hbm0_ms.awlock);
  m_axi_card_hbm_p0_awcache  <= std_logic_vector(po_hbm0_ms.awcache);
  m_axi_card_hbm_p0_awprot   <= std_logic_vector(po_hbm0_ms.awprot);
  m_axi_card_hbm_p0_awqos    <= std_logic_vector(po_hbm0_ms.awqos);
  m_axi_card_hbm_p0_awregion <= std_logic_vector(po_hbm0_ms.awregion);
  m_axi_card_hbm_p0_awid     <= std_logic_vector(po_hbm0_ms.awid);
  m_axi_card_hbm_p0_awuser   <= std_logic_vector(po_hbm0_ms.awuser);
  m_axi_card_hbm_p0_awvalid  <= po_hbm0_ms.awvalid;
  m_axi_card_hbm_p0_wdata    <= std_logic_vector(po_hbm0_ms.wdata);
  m_axi_card_hbm_p0_wstrb    <= std_logic_vector(po_hbm0_ms.wstrb);
  m_axi_card_hbm_p0_wlast    <= po_hbm0_ms.wlast;
  m_axi_card_hbm_p0_wuser    <= std_logic_vector(po_hbm0_ms.wuser);
  m_axi_card_hbm_p0_wvalid   <= po_hbm0_ms.wvalid;
  m_axi_card_hbm_p0_bready   <= po_hbm0_ms.bready;
  m_axi_card_hbm_p0_araddr   <= std_logic_vector(po_hbm0_ms.araddr);
  m_axi_card_hbm_p0_arlen    <= std_logic_vector(po_hbm0_ms.arlen);
  m_axi_card_hbm_p0_arsize   <= std_logic_vector(po_hbm0_ms.arsize);
  m_axi_card_hbm_p0_arburst  <= std_logic_vector(po_hbm0_ms.arburst);
  m_axi_card_hbm_p0_arlock   <= std_logic_vector(po_hbm0_ms.arlock);
  m_axi_card_hbm_p0_arcache  <= std_logic_vector(po_hbm0_ms.arcache);
  m_axi_card_hbm_p0_arprot   <= std_logic_vector(po_hbm0_ms.arprot);
  m_axi_card_hbm_p0_arqos    <= std_logic_vector(po_hbm0_ms.arqos);
  m_axi_card_hbm_p0_arregion <= std_logic_vector(po_hbm0_ms.arregion);
  m_axi_card_hbm_p0_arid     <= std_logic_vector(po_hbm0_ms.arid);
  m_axi_card_hbm_p0_aruser   <= std_logic_vector(po_hbm0_ms.aruser);
  m_axi_card_hbm_p0_arvalid  <= po_hbm0_ms.arvalid;
  m_axi_card_hbm_p0_rready   <= po_hbm0_ms.rready;
  pi_hbm0_sm.awready <= m_axi_card_hbm_p0_awready;
  pi_hbm0_sm.wready  <= m_axi_card_hbm_p0_wready;
  pi_hbm0_sm.bresp   <= dfaccto_axi.t_AxiResp(m_axi_card_hbm_p0_bresp);
  pi_hbm0_sm.bid     <= ocaccel.t_AxiHbmId(m_axi_card_hbm_p0_bid);
  pi_hbm0_sm.buser   <= ocaccel.t_AxiHbmBUser(m_axi_card_hbm_p0_buser);
  pi_hbm0_sm.bvalid  <= m_axi_card_hbm_p0_bvalid;
  pi_hbm0_sm.arready <= m_axi_card_hbm_p0_arready;
  pi_hbm0_sm.rdata   <= ocaccel.t_AxiHbmData(m_axi_card_hbm_p0_rdata);
  pi_hbm0_sm.rresp   <= dfaccto_axi.t_AxiResp(m_axi_card_hbm_p0_rresp);
  pi_hbm0_sm.rlast   <= m_axi_card_hbm_p0_rlast;
  pi_hbm0_sm.rid     <= ocaccel.t_AxiHbmId(m_axi_card_hbm_p0_rid);
  pi_hbm0_sm.ruser   <= ocaccel.t_AxiHbmRUser(m_axi_card_hbm_p0_ruser);
  pi_hbm0_sm.rvalid  <= m_axi_card_hbm_p0_rvalid;

end ExternalWrapper;
