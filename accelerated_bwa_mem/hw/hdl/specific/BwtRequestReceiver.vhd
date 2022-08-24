library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto_axi;
use work.dfaccto;
use work.ocaccel;
use work.bwt_types;

entity BwtRequestReceiver is
  port (
    pi_sys : in dfaccto.t_Sys;
    -- bwt_position_stream
    po_ret_bwt_entry_stream_ms  : out bwt_types.t_HlsIdStream_source_512_ms;
    pi_ret_bwt_entry_stream_sm  : in bwt_types.t_HlsIdStream_source_512_sm;
    -- AxiHbmRdData_ms
    po_rready   : out dfaccto.t_Logic;
    -- AxiHbmRdData_sm
    pi_rdata    : in ocaccel.t_AxiHbmData;
    pi_rresp    : in dfaccto_axi.t_AxiResp;
    pi_rlast    : in dfaccto.t_Logic;
    pi_rid      : in ocaccel.t_AxiHbmId;
    pi_ruser    : in ocaccel.t_AxiHbmRUser;
    pi_rvalid   : in dfaccto.t_Logic);
end BwtRequestReceiver;

architecture BwtRequestReceiver of BwtRequestReceiver is
    type t_ReadStage is (Idle, Read, Done);
    signal s_readStage : t_ReadStage;

    signal responseLengthCounter : unsigned(5 downto 0) := (others => '0');
    signal bufferData            : bwt_types.t_HlsIdStream_source_512Data := (others => '0');
    signal bufferId              : ocaccel.t_AxiHbmId;
begin
    --with s_readStage select po_ret_bwt_entry_stream_ms.strobe <= '1' when Done, '0' when others;
    po_ret_bwt_entry_stream_ms.strobe <= '1' when (s_readStage = Done and pi_ret_bwt_entry_stream_sm.ready = '1') else '0';
    po_ret_bwt_entry_stream_ms.data <= bufferData;
    po_ret_bwt_entry_stream_ms.id <= bufferId;
    po_rready <= '1' when ((not (s_readStage = Done)) or pi_ret_bwt_entry_stream_sm.ready = '1') else '0';

    process (pi_sys.clk)
    begin
        if pi_sys.clk'event and pi_sys.clk = '1' then
          if pi_sys.rst_n = '0' then
            s_readStage <= Idle;
            responseLengthCounter <= to_unsigned(0, responseLengthCounter'length);
          else
            case s_readStage is
              when Idle =>
                if pi_rvalid = '1' then
                  bufferData(255 downto 0) <= pi_rdata;
                  responseLengthCounter <= to_unsigned(1, responseLengthCounter'length);

                  if pi_rlast = '1' then
                      bufferId <= pi_rid;
                      s_readStage <= Done;                      
                  else
                      s_readStage <= Read;
                  end if;
                end if;
              when Read =>
                if pi_rvalid = '1' then
                  bufferData((255 + 256 * to_integer(responseLengthCounter)) downto (256 * to_integer(responseLengthCounter))) <= pi_rdata;
                  if pi_rlast = '1' then
                    bufferId <= pi_rid;
                    s_readStage <= Done;
                  else
                    responseLengthCounter <= responseLengthCounter + 1;
                  end if;
                end if;
              when Done =>
                if pi_ret_bwt_entry_stream_sm.ready = '1' then
                  if pi_rvalid = '1' then
                    bufferData(255 downto 0) <= pi_rdata;
                    if pi_rlast = '0' then
                      bufferId <= pi_rid;
                      responseLengthCounter <= to_unsigned(1, responseLengthCounter'length);
                      s_readStage <= Read;
                    end if;
                  else
                    responseLengthCounter <= to_unsigned(0, responseLengthCounter'length);
                    s_readStage <= Read;
                  end if;
                end if;
            end case;
          end if;
        end if;
    end process;

end BwtRequestReceiver;