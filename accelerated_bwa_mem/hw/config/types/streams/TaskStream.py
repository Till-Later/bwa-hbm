with Pkg("taskStream", x_templates={"generic/package.vhd": "pkg/task_stream.vhd"}):
    TypeHlsFifo("TaskStreamSource", data_bits=66, is_source=True)
    TypeHlsFifo("TaskStreamSink", data_bits=66, is_sink=True)

    TypeHlsFifo("FollowUpTaskStreamSource", data_bits=95 + PIPELINE_INDEX_WIDTH, is_source=True)
    TypeHlsFifo("FollowUpTaskStreamSink", data_bits=95 + PIPELINE_INDEX_WIDTH, is_sink=True)
