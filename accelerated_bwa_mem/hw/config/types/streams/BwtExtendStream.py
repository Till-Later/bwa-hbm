Inc("../../globals.py")
Inc("../../include/ocaccel.py")

with Pkg("bwtExtendStream", x_templates={"generic/package.vhd": "pkg/bwt_extend_stream.vhd"}):
    TypeHlsFifo("BwtExtendStreamSource", data_bits=BWT_EXTEND_STREAM_ELEMENT_WIDTH, is_source=True)
    TypeHlsFifo("BwtExtendStreamSink", data_bits=BWT_EXTEND_STREAM_ELEMENT_WIDTH, is_sink=True)