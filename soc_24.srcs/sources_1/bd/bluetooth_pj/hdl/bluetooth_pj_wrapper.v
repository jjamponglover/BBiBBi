//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Fri May 31 11:03:50 2024
//Host        : Digital-15 running 64-bit major release  (build 9200)
//Command     : generate_target bluetooth_pj_wrapper.bd
//Design      : bluetooth_pj_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module bluetooth_pj_wrapper
   (col_0,
    iic_rtl_scl_io,
    iic_rtl_sda_io,
    reset,
    row_0,
    sys_clock,
    usb_uart_0_rxd,
    usb_uart_0_txd,
    usb_uart_rxd,
    usb_uart_txd);
  output [3:0]col_0;
  inout iic_rtl_scl_io;
  inout iic_rtl_sda_io;
  input reset;
  input [3:0]row_0;
  input sys_clock;
  input usb_uart_0_rxd;
  output usb_uart_0_txd;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [3:0]col_0;
  wire iic_rtl_scl_i;
  wire iic_rtl_scl_io;
  wire iic_rtl_scl_o;
  wire iic_rtl_scl_t;
  wire iic_rtl_sda_i;
  wire iic_rtl_sda_io;
  wire iic_rtl_sda_o;
  wire iic_rtl_sda_t;
  wire reset;
  wire [3:0]row_0;
  wire sys_clock;
  wire usb_uart_0_rxd;
  wire usb_uart_0_txd;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  bluetooth_pj bluetooth_pj_i
       (.col_0(col_0),
        .iic_rtl_scl_i(iic_rtl_scl_i),
        .iic_rtl_scl_o(iic_rtl_scl_o),
        .iic_rtl_scl_t(iic_rtl_scl_t),
        .iic_rtl_sda_i(iic_rtl_sda_i),
        .iic_rtl_sda_o(iic_rtl_sda_o),
        .iic_rtl_sda_t(iic_rtl_sda_t),
        .reset(reset),
        .row_0(row_0),
        .sys_clock(sys_clock),
        .usb_uart_0_rxd(usb_uart_0_rxd),
        .usb_uart_0_txd(usb_uart_0_txd),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
  IOBUF iic_rtl_scl_iobuf
       (.I(iic_rtl_scl_o),
        .IO(iic_rtl_scl_io),
        .O(iic_rtl_scl_i),
        .T(iic_rtl_scl_t));
  IOBUF iic_rtl_sda_iobuf
       (.I(iic_rtl_sda_o),
        .IO(iic_rtl_sda_io),
        .O(iic_rtl_sda_i),
        .T(iic_rtl_sda_t));
endmodule
