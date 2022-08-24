Inc("../../globals.py")

with Pkg("pipelineIndexStream", x_templates={"generic/package.vhd": "pkg/pipeline_index_stream.vhd"}):
    TypeHlsFifo("PipelineIndexStreamSource", data_bits=PIPELINE_INDEX_WIDTH, is_source=True)
    TypeHlsFifo("PipelineIndexStreamSink", data_bits=PIPELINE_INDEX_WIDTH, is_sink=True)