from functools import partial
from enum import Enum, auto

Inc("globals.py")


def fixedNameMapping(mapping):
    parameter_list = {}

    for key, value in mapping.items():
        parameter_list[key] = partial(lambda name, e: e.ports[name], value)

    return parameter_list


class MonitorPosition(Enum):
    NONE = auto()
    SOURCE = auto()
    SINK = auto()
    BOTH = auto()


def createStreamBufferInstances(
    streamTypeName,
    streamName,
    count,
    FIFOLogDepth=DEFAULT_STREAM_BUFFER_LOG_DEPTH,
    monitorPosition=MonitorPosition.NONE
):
    for i in range(count):
        bufferSourceSignalName = f"{streamName}_source_{i}"
        if (
            monitorPosition == MonitorPosition.SOURCE
            or monitorPosition == MonitorPosition.BOTH
        ):
            Ins(
                f"HlsStreamMonitor{streamTypeName}Source",
                f"hls_stream_monitor_{streamName}_source_{i}",
                MapGeneric("FIFOLogDepth", Lit(FIFOLogDepth)),
                MapPort("sys", S("sys")),
                MapPort("slave", S(f"{streamName}_source_{i}")),
                MapPort("master", S(f"{streamName}_monitored_source_{i}")),
                MapPort("reset_counters", S("reset_counters")),
                MapPort("memRd", S(f"{streamName}_source_monitor_channel_{i}")),
            )
            bufferSourceSignalName = f"{streamName}_monitored_source_{i}"

        bufferSinkSignalName = f"{streamName}_sink_{i}"
        if (
            monitorPosition == MonitorPosition.SINK
            or monitorPosition == MonitorPosition.BOTH
        ):
            Ins(
                f"HlsStreamMonitor{streamTypeName}Sink",
                f"hls_stream_monitor_{streamName}_sink_{i}",
                MapGeneric("FIFOLogDepth", Lit(FIFOLogDepth)),
                MapPort("sys", S("sys")),
                MapPort("master", S(f"{streamName}_monitored_sink_{i}")),
                MapPort("slave", S(f"{streamName}_sink_{i}")),
                MapPort("reset_counters", S("reset_counters")),
                MapPort("memRd", S(f"{streamName}_sink_monitor_channel_{i}")),
            )
            bufferSinkSignalName = f"{streamName}_monitored_sink_{i}"
            
        Ins(
            f"HlsStreamBuffer{streamTypeName}",
            f"hls_stream_buffer_{streamName}_{i}",
            MapGeneric("FIFOLogDepth", Lit(FIFOLogDepth)),
            MapPort("sys", S("sys")),
            MapPort("source", S(bufferSourceSignalName)),
            MapPort("sink", S(bufferSinkSignalName)),
        )

def createStreamBufferInstance(
    streamTypeName,
    streamName,
    FIFOLogDepth=DEFAULT_STREAM_BUFFER_LOG_DEPTH,
    monitorPosition=MonitorPosition.NONE,
):
    bufferSourceSignalName = f"{streamName}_source"
    if (
        monitorPosition == MonitorPosition.SOURCE
        or monitorPosition == MonitorPosition.BOTH
    ):
        Ins(
            f"HlsStreamMonitor{streamTypeName}Source",
            f"hls_stream_monitor_{streamName}_source",
            MapGeneric("FIFOLogDepth", Lit(FIFOLogDepth)),
            MapPort("sys", S("sys")),
            MapPort("slave", S(f"{streamName}_source")),
            MapPort("master", S(f"{streamName}_monitored_source")),
            MapPort("reset_counters", S("reset_counters")),
            MapPort("memRd", S(f"{streamName}_source_monitor_channel")),
        )
        bufferSourceSignalName = f"{streamName}_monitored_source"

    bufferSinkSignalName = f"{streamName}_sink"
    if (
        monitorPosition == MonitorPosition.SINK
        or monitorPosition == MonitorPosition.BOTH
    ):
        Ins(
            f"HlsStreamMonitor{streamTypeName}Sink",
            f"hls_stream_monitor_{streamName}_sink",
            MapGeneric("FIFOLogDepth", Lit(FIFOLogDepth)),
            MapPort("sys", S("sys")),
            MapPort("master", S(f"{streamName}_monitored_sink")),
            MapPort("slave", S(f"{streamName}_sink")),
            MapPort("reset_counters", S("reset_counters")),
            MapPort("memRd", S(f"{streamName}_sink_monitor_channel")),
        )
        bufferSinkSignalName = f"{streamName}_monitored_sink"

    Ins(
        f"HlsStreamBuffer{streamTypeName}",
        f"hls_stream_buffer_{streamName}",
        MapGeneric("FIFOLogDepth", Lit(FIFOLogDepth)),
        MapPort("sys", S("sys")),
        MapPort("source", S(bufferSourceSignalName)),
        MapPort("sink", S(bufferSinkSignalName)),
    )
