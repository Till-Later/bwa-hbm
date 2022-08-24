with Pkg("terminationSignalStream", x_templates={"generic/package.vhd": "pkg/termination_signal_stream.vhd"}):
    TypeHlsFifo("TerminationSignalStreamSource", data_bits=1, is_source=True)
    TypeHlsFifo("TerminationSignalStreamSink", data_bits=1, is_sink=True)