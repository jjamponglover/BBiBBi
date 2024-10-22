//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Fri May 17 14:14:16 2024
//Host        : Digital-15 running 64-bit major release  (build 9200)
//Command     : generate_target mblaze_fnd_wrapper.bd
//Design      : mblaze_fnd_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module mblaze_fnd_wrapper
   (dip_switches_16bits_tri_i,
    reset,
    seven_seg_led_an_tri_o,
    seven_seg_led_disp_tri_o,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  input [15:0]dip_switches_16bits_tri_i;
  input reset;
  output [3:0]seven_seg_led_an_tri_o;
  output [7:0]seven_seg_led_disp_tri_o;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [15:0]dip_switches_16bits_tri_i;
  wire reset;
  wire [3:0]seven_seg_led_an_tri_o;
  wire [7:0]seven_seg_led_disp_tri_o;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  mblaze_fnd mblaze_fnd_i
       (.dip_switches_16bits_tri_i(dip_switches_16bits_tri_i),
        .reset(reset),
        .seven_seg_led_an_tri_o(seven_seg_led_an_tri_o),
        .seven_seg_led_disp_tri_o(seven_seg_led_disp_tri_o),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
