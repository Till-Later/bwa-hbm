Inc("../../types/Numeric.py")
Inc("../../types/HlsHmem.py")
Inc("../../types/HlsHbm.py")
Inc("../../include/ocaccel.py")
Inc("WrappedHlsEntity.py")
Inc("HlsPort.py")


WrappedHlsEntity(
    "init_bwt",
    HlsPortI("bwt_host_address", T("u64")),
    HlsPortI("bwt_size", T("u32")),
    HlsPortM("m_axi_host_mem", T("HlsHmem"), suffix="V"),
    *HlsPortsM("m_axi_card_hbm", T("HlsHbm"), ocaccel.AxiHbmCount, suffix="")    
)
