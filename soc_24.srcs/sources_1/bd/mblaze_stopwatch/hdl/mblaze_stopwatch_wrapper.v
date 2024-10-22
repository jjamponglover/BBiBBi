//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Fri May 24 11:22:51 2024
//Host        : Digital-15 running 64-bit major release  (build 9200)
//Command     : generate_target mblaze_stopwatch_wrapper.bd
//Design      : mblaze_stopwatch_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module mblaze_stopwatch_wrapper
   (btn_4bits_tri_i,
    com_0,
    reset,
    seg_7_0,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  input [3:0]btn_4bits_tri_i;
  output [3:0]com_0;
  input reset;
  output [7:0]seg_7_0;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [3:0]btn_4bits_tri_i;
  wire [3:0]com_0;
  wire reset;
  wire [7:0]seg_7_0;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  mblaze_stopwatch mblaze_stopwatch_i
       (.btn_4bits_tri_i(btn_4bits_tri_i),
        .com_0(com_0),
        .reset(reset),
        .seg_7_0(seg_7_0),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
