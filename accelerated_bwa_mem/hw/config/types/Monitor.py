Inc("../globals.py")

with Pkg("monitor_types", x_templates={"generic/package.vhd": "pkg/monitor_types.vhd"}):
    aggregatedMonitorMemAddrBits = (
        int(math.log2((2 * 3 * NUM_STREAM_MONITORS) - 1)) + 1
    )
    TypeHlsMemory(
        "AggregatedMonitorMem",
        data_bits=32,
        addr_bits=aggregatedMonitorMemAddrBits,
        has_rd=True,
        has_wr=True,
    )
    TypeHlsMemory(
        "AggregatedMonitorMemWr",
        data_bits=32,
        addr_bits=aggregatedMonitorMemAddrBits,
        has_rd=False,
        has_wr=True,
    )
    TypeHlsMemory("MonitorMemRd", data_bits=8, addr_bits=5, has_rd=True, has_wr=False)
