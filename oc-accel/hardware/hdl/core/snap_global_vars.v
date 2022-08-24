`timescale 1ns/1ps
`define DEBUG
`define FRAMEWORK
`define AD9H7
`define ENABLE_AXI_CARD_MEM
`define ENABLE_BRAM



`define ENABLE_AXI_CARD_MEM
`define ENABLE_HBM
`define HBM_AXI_IF_P0


`define HBM_AXI_IF_P1


`define HBM_AXI_IF_P2


`define HBM_AXI_IF_P3


`define HBM_AXI_IF_P4


`define HBM_AXI_IF_P5


`define HBM_AXI_IF_P6


`define HBM_AXI_IF_P7


`define HBM_AXI_IF_P8


`define HBM_AXI_IF_P9


`define HBM_AXI_IF_P10


`define HBM_AXI_IF_P11


`define HBM_AXI_IF_P12


`define HBM_AXI_IF_P13


`define HBM_AXI_IF_P14


`define HBM_AXI_IF_P15


`define HBM_AXI_IF_P16


`define HBM_AXI_IF_P17


`define HBM_AXI_IF_P18


`define HBM_AXI_IF_P19


`define HBM_AXI_IF_P20


`define HBM_AXI_IF_P21


`define HBM_AXI_IF_P22


`define HBM_AXI_IF_P23


`define HBM_AXI_IF_P24


`define HBM_AXI_IF_P25


`define HBM_AXI_IF_P26


`define HBM_AXI_IF_P27


`define HBM_AXI_IF_P28


`define HBM_AXI_IF_P29


`define HBM_AXI_IF_P30


`define HBM_AXI_IF_P31





  `define IMP_VERSION_DAT 64'h33_43_0540_E516_75C7
  `define BUILD_DATE_DAT 64'h0000_2022_0822_1801
  `define CARD_TYPE 8'h33
  `define USERCODE 64'h0



  `define HLS_ACTION_TYPE 32'h0
  `define HLS_RELEASE_LEVEL 32'h0



  `define NUM_OF_ACTIONS 16'h0
  `define DMA_XFER_SIZE 4'h0
  `define DMA_ALIGNMENT 4'h0
  `define SDRAM_SIZE 16'h0




`define IDW 1

  `define CTXW 9
  `define TAGW 7





  `define AXI_MM_DW 1024
  `define AXI_ST_DW 1024


  `define AXI_MM_AW 64
  `define AXI_ST_AW 64
  `define AXI_LITE_DW 32
  `define AXI_LITE_AW 32
  `define AXI_AWUSER 9
  `define AXI_ARUSER 9
  `define AXI_WUSER 9
  `define AXI_RUSER 9
  `define AXI_BUSER 9
  `define AXI_ST_USER 9

  `define AXI_CARD_HBM_ID_WIDTH 4
  `define AXI_CARD_MEM_DATA_WIDTH 512
  `define AXI_CARD_MEM_ADDR_WIDTH 33
  `define AXI_CARD_MEM_USER_WIDTH 1

  `define AXI_CARD_HBM_ID_WIDTH 6
  `define AXI_CARD_HBM_DATA_WIDTH 256
  `define AXI_CARD_HBM_ADDR_WIDTH 34
  `define AXI_CARD_HBM_USER_WIDTH 1

  `define INT_BITS 64

`ifdef ACTION_HALF_WIDTH
  `define AXI_ACT_DW 512
`else
  `define AXI_ACT_DW 1024
`endif
