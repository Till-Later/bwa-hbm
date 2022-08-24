library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.dfaccto_axi;
use work.dfaccto;

package bwt_types is
    subtype t_HlsIdStream_source_512Data is unsigned (512-1 downto 0);

  type t_HlsIdStream_source_512_ms is record
    data   : t_HlsIdStream_source_512Data;
    strobe : dfaccto.t_Logic;
    id     : unsigned(5 downto 0);
  end record;
  type t_HlsIdStream_source_512_sm is record
    ready  : dfaccto.t_Logic;
  end record;

  type t_HlsIdStream_source_512_v_ms is array (integer range <>) of t_HlsIdStream_source_512_ms;
  type t_HlsIdStream_source_512_v_sm is array (integer range <>) of t_HlsIdStream_source_512_sm;

    subtype t_HlsIdStream_sink_26Data is unsigned (26-1 downto 0);

  type t_HlsIdStream_sink_26_ms is record
    strobe : dfaccto.t_Logic;
  end record;
  type t_HlsIdStream_sink_26_sm is record
    data   : t_HlsIdStream_sink_26Data;
    ready  : dfaccto.t_Logic;
    id     : unsigned(5 downto 0);
  end record;
  type t_HlsIdStream_sink_26_v_ms is array (integer range <>) of t_HlsIdStream_sink_26_ms;
  type t_HlsIdStream_sink_26_v_sm is array (integer range <>) of t_HlsIdStream_sink_26_sm;
end bwt_types;