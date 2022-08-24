Inc("../../globals.py")
Inc("../../types/Monitor.py")
Inc("WrappedHlsEntity.py")
Inc("HlsPort.py")

WrappedHlsEntity(
    "stream_monitor_aggregator",
    HlsPortM("aggregated_monitor_counters", T("AggregatedMonitorMemWr"), suffix=""),
    *HlsPortsM("monitor_channel", T("MonitorMemRd"), NUM_STREAM_MONITORS, suffix=""),
    HlsPortM("termination_signal_stream", T("TerminationSignalStreamSink"), suffix="V"),
)
