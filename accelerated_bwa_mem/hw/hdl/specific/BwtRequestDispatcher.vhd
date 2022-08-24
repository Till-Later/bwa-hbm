library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto_axi;
use work.dfaccto;
use work.ocaccel;
use work.bwt_types;

entity BwtRequestDispatcher is
  generic (
    g_HbmCacheLinesPerBwtEntry : dfaccto.t_Integer);
  port (
    pi_sys : in dfaccto.t_Sys;
    -- bwt_position_stream
    po_req_bwt_position_stream_ms : out bwt_types.t_HlsIdStream_sink_26_ms;
    pi_req_bwt_position_stream_sm : in bwt_types.t_HlsIdStream_sink_26_sm;
    -- AxiHbmRdAddr_ms
    po_araddr   : out ocaccel.t_AxiHbmAddr;
    po_arlen    : out dfaccto_axi.t_AxiLen;
    po_arsize   : out dfaccto_axi.t_AxiSize;
    po_arburst  : out dfaccto_axi.t_AxiBurst;
    po_arlock   : out dfaccto_axi.t_AxiLock;
    po_arcache  : out dfaccto_axi.t_AxiCache;
    po_arprot   : out dfaccto_axi.t_AxiProt;
    po_arqos    : out dfaccto_axi.t_AxiQos;
    po_arregion : out dfaccto_axi.t_AxiRegion;
    po_arid     : out ocaccel.t_AxiHbmId;
    po_aruser   : out ocaccel.t_AxiHbmARUser;
    po_arvalid  : out dfaccto.t_Logic;
    -- AxiHbmRdAddr_sm
    pi_arready  : in dfaccto.t_Logic);
end BwtRequestDispatcher;

architecture BwtRequestDispatcher of BwtRequestDispatcher is

begin
    po_araddr      <= "00" & pi_req_bwt_position_stream_sm.data & "000000";
    po_arid        <= pi_req_bwt_position_stream_sm.id;
    po_arvalid     <= pi_req_bwt_position_stream_sm.ready;

    po_req_bwt_position_stream_ms.strobe <= pi_arready;

    po_aruser      <= ocaccel.c_AxiHbmARUserNull;
    po_arlen       <= to_unsigned(g_HbmCacheLinesPerBwtEntry - 1, dfaccto_axi.t_AxiLen'length); -- equals to HBM_CACHE_LINES_PER_BWT_ENTRY
    po_arsize      <= to_unsigned(5, dfaccto_axi.t_AxiSize'length);
    po_arburst     <= dfaccto_axi.c_AxiBurstIncr;
    po_arlock      <= dfaccto_axi.c_AxiLockNull;
    po_arcache     <= dfaccto_axi.c_AxiCacheNull;
    po_arprot      <= dfaccto_axi.c_AxiProtNull;
    po_arqos       <= dfaccto_axi.c_AxiQosNull;
    po_arregion    <= dfaccto_axi.c_AxiRegionNull;
end BwtRequestDispatcher;