// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Thu May 16 16:21:44 2024
// Host        : Digital-15 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               d:/LSS/vivado_2019/soc_24_1/soc_24_1.srcs/sources_1/bd/mblaze_btn/ip/mblaze_btn_clk_wiz_0_0/mblaze_btn_clk_wiz_0_0_stub.v
// Design      : mblaze_btn_clk_wiz_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module mblaze_btn_clk_wiz_0_0(clk_out1, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,reset,locked,clk_in1" */;
  output clk_out1;
  input reset;
  output locked;
  input clk_in1;
endmodule