Inc("dfaccto.py")


class OCAccelEnv:
    def __init__(self):
        import os

        self.ContextBits = 9
        self.InterruptBits = 64
        self.AxiCtrl_DataBytes = 4
        self.AxiCtrl_AddrBits = 32
        self.AxiHost_DataBytes = (
            64 if os.environ.get("ACTION_HALF_WIDTH", False) else 128
        )
        self.AxiHost_AddrBits = 64
        self.AxiHost_IdBits = os.environ.get("AXI_ID_WIDTH", 1)
        self.AxiHost_UserBits = self.ContextBits
        self.AxiDdr_DataBytes = 64
        self.AxiDdr_AddrBits = 33
        self.AxiDdr_IdBits = 4
        self.AxiDdr_UserBits = 1
        self.AxiDdrEnabled = "ENABLE_DDR" in os.environ
        self.AxiHbm_DataBytes = 32
        self.AxiHbm_AddrBits = 34
        self.AxiHbm_IdBits = 6
        self.AxiHbm_UserBits = 1
        self.AxiHbmEnabled = "ENABLE_HBM" in os.environ
        self.AxiHbmCount = int(os.environ.get("HBM_AXI_IF_NUM", "1"))
        self.AxiHbm_LenBits = 8  # HW only supports 4 Bits
        self.StmEth_DataBytes = 64
        self.StmEth_UserBits = 1
        self.StmEthEnabled = os.environ.get("ETHERNET_USED", "FALSE") == "TRUE"

        self.tlogic = T("Logic", "dfaccto")
        self.tsys = T("Sys", "dfaccto")
        self.pkg = Pkg(
            "ocaccel", x_templates={"generic/package.vhd": "pkg/ocaccel.vhd"}
        )
        with self.pkg:
            self.tctrl = AxiType(
                "AxiCtrl",
                self.AxiCtrl_DataBytes,
                self.AxiCtrl_AddrBits,
                has_burst=False,
            )
            self.thost = AxiType(
                "AxiHost",
                self.AxiHost_DataBytes,
                self.AxiHost_AddrBits,
                id_bits=self.AxiHost_IdBits,
                has_attr=True,
                aruser_bits=self.AxiHost_UserBits,
                awuser_bits=self.AxiHost_UserBits,
                ruser_bits=self.AxiHost_UserBits,
                wuser_bits=self.AxiHost_UserBits,
                buser_bits=self.AxiHost_UserBits,
            )
            self.tddr = AxiType(
                "AxiDdr",
                self.AxiDdr_DataBytes,
                self.AxiDdr_AddrBits,
                id_bits=self.AxiDdr_IdBits,
                has_attr=True,
                aruser_bits=self.AxiDdr_UserBits,
                awuser_bits=self.AxiDdr_UserBits,
                ruser_bits=self.AxiDdr_UserBits,
                wuser_bits=self.AxiDdr_UserBits,
                buser_bits=self.AxiDdr_UserBits,
            )
            self.thbm = AxiType(
                "AxiHbm",
                self.AxiHbm_DataBytes,
                self.AxiHbm_AddrBits,
                id_bits=self.AxiHbm_IdBits,
                has_attr=True,
                aruser_bits=self.AxiHbm_UserBits,
                awuser_bits=self.AxiHbm_UserBits,
                ruser_bits=self.AxiHbm_UserBits,
                wuser_bits=self.AxiHbm_UserBits,
                buser_bits=self.AxiHbm_UserBits,
                add_split=True,
                len_bits=self.AxiHbm_LenBits,
            )
            self.teth = AxiStreamType(
                "StmEth", self.StmEth_DataBytes, user_bits=self.StmEth_UserBits
            )

            self.tctx = UnsignedType("Context", width=self.ContextBits)

            self.tisrc = UnsignedType("InterruptSrc", width=self.InterruptBits)

            self.tintr = TypeC(
                "Interrupt",
                x_definition="{{>types/definition/interrupt.part}}",
                x_format_ms="{{>types/format/interrupt_ms.part}}",
                x_format_sm="{{>types/format/interrupt_sm.part}}",
                x_wrapeport="{{>types/wrapeport/interrupt.part}}",
                x_wrapeconv="{{>types/wrapeconv/interrupt.part}}",
                x_wrapidefs="{{>types/wrapidefs/interrupt.part}}",
                x_wrapiconv="{{>types/wrapiconv/interrupt.part}}",
                x_wrapipmap="{{>types/wrapipmap/interrupt.part}}",
                x_wrapigmap=None,
                x_tlogic=self.tlogic,
                x_tctx=self.tctx,
                x_tsrc=self.tisrc,
                x_cnull=lambda t: Con("InterruptNull", t, value=Lit({})),
            )

    def get_ports(self):
        ports = [
            PortI("sys", self.tsys, x_wrapname="ap"),
            PortM("intr", self.tintr, x_wrapname="interrupt"),
            PortS("ctrl", self.tctrl, x_wrapname="s_axi_ctrl_reg"),
            PortM("hmem", self.thost, x_wrapname="m_axi_host_mem"),
        ]

        if self.AxiDdrEnabled:
            ports.append(PortM("cmem", self.tddr, x_wrapname="m_axi_card_mem0"))

        if self.AxiHbmEnabled:
            for i in range(self.AxiHbmCount):
                ports.append(
                    PortM(
                        "hbm{:d}".format(i),
                        self.thbm,
                        x_wrapname="m_axi_card_hbm_p{:d}".format(i),
                    )
                )

        if self.StmEthEnabled:
            ports.append(PortM("ethTx", self.teth, x_wrapname="dout_eth"))
            ports.append(PortS("ethRx", self.teth, x_wrapname="din_eth"))
            ports.append(PortO("ethRxRst", self.tlogic, x_wrapname="eth_rx_fifo_reset"))
            ports.append(
                PortI("ethRxStatus", self.tlogic, x_wrapname="eth_stat_rx_status")
            )
            ports.append(
                PortI("ethRxAligned", self.tlogic, x_wrapname="eth_stat_rx_aligned")
            )

        return ports


ocaccel = OCAccelEnv()
