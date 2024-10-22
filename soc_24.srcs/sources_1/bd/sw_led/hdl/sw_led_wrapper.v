//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Fri May 17 11:23:08 2024
//Host        : Digital-15 running 64-bit major release  (build 9200)
//Command     : generate_target sw_led_wrapper.bd
//Design      : sw_led_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module sw_led_wrapper
   (dip_switches_16bits_tri_io,
    led_16bits_tri_i,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  inout [15:0]dip_switches_16bits_tri_io;
  input [15:0]led_16bits_tri_i;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire [0:0]dip_switches_16bits_tri_i_0;
  wire [1:1]dip_switches_16bits_tri_i_1;
  wire [10:10]dip_switches_16bits_tri_i_10;
  wire [11:11]dip_switches_16bits_tri_i_11;
  wire [12:12]dip_switches_16bits_tri_i_12;
  wire [13:13]dip_switches_16bits_tri_i_13;
  wire [14:14]dip_switches_16bits_tri_i_14;
  wire [15:15]dip_switches_16bits_tri_i_15;
  wire [2:2]dip_switches_16bits_tri_i_2;
  wire [3:3]dip_switches_16bits_tri_i_3;
  wire [4:4]dip_switches_16bits_tri_i_4;
  wire [5:5]dip_switches_16bits_tri_i_5;
  wire [6:6]dip_switches_16bits_tri_i_6;
  wire [7:7]dip_switches_16bits_tri_i_7;
  wire [8:8]dip_switches_16bits_tri_i_8;
  wire [9:9]dip_switches_16bits_tri_i_9;
  wire [0:0]dip_switches_16bits_tri_io_0;
  wire [1:1]dip_switches_16bits_tri_io_1;
  wire [10:10]dip_switches_16bits_tri_io_10;
  wire [11:11]dip_switches_16bits_tri_io_11;
  wire [12:12]dip_switches_16bits_tri_io_12;
  wire [13:13]dip_switches_16bits_tri_io_13;
  wire [14:14]dip_switches_16bits_tri_io_14;
  wire [15:15]dip_switches_16bits_tri_io_15;
  wire [2:2]dip_switches_16bits_tri_io_2;
  wire [3:3]dip_switches_16bits_tri_io_3;
  wire [4:4]dip_switches_16bits_tri_io_4;
  wire [5:5]dip_switches_16bits_tri_io_5;
  wire [6:6]dip_switches_16bits_tri_io_6;
  wire [7:7]dip_switches_16bits_tri_io_7;
  wire [8:8]dip_switches_16bits_tri_io_8;
  wire [9:9]dip_switches_16bits_tri_io_9;
  wire [0:0]dip_switches_16bits_tri_o_0;
  wire [1:1]dip_switches_16bits_tri_o_1;
  wire [10:10]dip_switches_16bits_tri_o_10;
  wire [11:11]dip_switches_16bits_tri_o_11;
  wire [12:12]dip_switches_16bits_tri_o_12;
  wire [13:13]dip_switches_16bits_tri_o_13;
  wire [14:14]dip_switches_16bits_tri_o_14;
  wire [15:15]dip_switches_16bits_tri_o_15;
  wire [2:2]dip_switches_16bits_tri_o_2;
  wire [3:3]dip_switches_16bits_tri_o_3;
  wire [4:4]dip_switches_16bits_tri_o_4;
  wire [5:5]dip_switches_16bits_tri_o_5;
  wire [6:6]dip_switches_16bits_tri_o_6;
  wire [7:7]dip_switches_16bits_tri_o_7;
  wire [8:8]dip_switches_16bits_tri_o_8;
  wire [9:9]dip_switches_16bits_tri_o_9;
  wire [0:0]dip_switches_16bits_tri_t_0;
  wire [1:1]dip_switches_16bits_tri_t_1;
  wire [10:10]dip_switches_16bits_tri_t_10;
  wire [11:11]dip_switches_16bits_tri_t_11;
  wire [12:12]dip_switches_16bits_tri_t_12;
  wire [13:13]dip_switches_16bits_tri_t_13;
  wire [14:14]dip_switches_16bits_tri_t_14;
  wire [15:15]dip_switches_16bits_tri_t_15;
  wire [2:2]dip_switches_16bits_tri_t_2;
  wire [3:3]dip_switches_16bits_tri_t_3;
  wire [4:4]dip_switches_16bits_tri_t_4;
  wire [5:5]dip_switches_16bits_tri_t_5;
  wire [6:6]dip_switches_16bits_tri_t_6;
  wire [7:7]dip_switches_16bits_tri_t_7;
  wire [8:8]dip_switches_16bits_tri_t_8;
  wire [9:9]dip_switches_16bits_tri_t_9;
  wire [15:0]led_16bits_tri_i;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  IOBUF dip_switches_16bits_tri_iobuf_0
       (.I(dip_switches_16bits_tri_o_0),
        .IO(dip_switches_16bits_tri_io[0]),
        .O(dip_switches_16bits_tri_i_0),
        .T(dip_switches_16bits_tri_t_0));
  IOBUF dip_switches_16bits_tri_iobuf_1
       (.I(dip_switches_16bits_tri_o_1),
        .IO(dip_switches_16bits_tri_io[1]),
        .O(dip_switches_16bits_tri_i_1),
        .T(dip_switches_16bits_tri_t_1));
  IOBUF dip_switches_16bits_tri_iobuf_10
       (.I(dip_switches_16bits_tri_o_10),
        .IO(dip_switches_16bits_tri_io[10]),
        .O(dip_switches_16bits_tri_i_10),
        .T(dip_switches_16bits_tri_t_10));
  IOBUF dip_switches_16bits_tri_iobuf_11
       (.I(dip_switches_16bits_tri_o_11),
        .IO(dip_switches_16bits_tri_io[11]),
        .O(dip_switches_16bits_tri_i_11),
        .T(dip_switches_16bits_tri_t_11));
  IOBUF dip_switches_16bits_tri_iobuf_12
       (.I(dip_switches_16bits_tri_o_12),
        .IO(dip_switches_16bits_tri_io[12]),
        .O(dip_switches_16bits_tri_i_12),
        .T(dip_switches_16bits_tri_t_12));
  IOBUF dip_switches_16bits_tri_iobuf_13
       (.I(dip_switches_16bits_tri_o_13),
        .IO(dip_switches_16bits_tri_io[13]),
        .O(dip_switches_16bits_tri_i_13),
        .T(dip_switches_16bits_tri_t_13));
  IOBUF dip_switches_16bits_tri_iobuf_14
       (.I(dip_switches_16bits_tri_o_14),
        .IO(dip_switches_16bits_tri_io[14]),
        .O(dip_switches_16bits_tri_i_14),
        .T(dip_switches_16bits_tri_t_14));
  IOBUF dip_switches_16bits_tri_iobuf_15
       (.I(dip_switches_16bits_tri_o_15),
        .IO(dip_switches_16bits_tri_io[15]),
        .O(dip_switches_16bits_tri_i_15),
        .T(dip_switches_16bits_tri_t_15));
  IOBUF dip_switches_16bits_tri_iobuf_2
       (.I(dip_switches_16bits_tri_o_2),
        .IO(dip_switches_16bits_tri_io[2]),
        .O(dip_switches_16bits_tri_i_2),
        .T(dip_switches_16bits_tri_t_2));
  IOBUF dip_switches_16bits_tri_iobuf_3
       (.I(dip_switches_16bits_tri_o_3),
        .IO(dip_switches_16bits_tri_io[3]),
        .O(dip_switches_16bits_tri_i_3),
        .T(dip_switches_16bits_tri_t_3));
  IOBUF dip_switches_16bits_tri_iobuf_4
       (.I(dip_switches_16bits_tri_o_4),
        .IO(dip_switches_16bits_tri_io[4]),
        .O(dip_switches_16bits_tri_i_4),
        .T(dip_switches_16bits_tri_t_4));
  IOBUF dip_switches_16bits_tri_iobuf_5
       (.I(dip_switches_16bits_tri_o_5),
        .IO(dip_switches_16bits_tri_io[5]),
        .O(dip_switches_16bits_tri_i_5),
        .T(dip_switches_16bits_tri_t_5));
  IOBUF dip_switches_16bits_tri_iobuf_6
       (.I(dip_switches_16bits_tri_o_6),
        .IO(dip_switches_16bits_tri_io[6]),
        .O(dip_switches_16bits_tri_i_6),
        .T(dip_switches_16bits_tri_t_6));
  IOBUF dip_switches_16bits_tri_iobuf_7
       (.I(dip_switches_16bits_tri_o_7),
        .IO(dip_switches_16bits_tri_io[7]),
        .O(dip_switches_16bits_tri_i_7),
        .T(dip_switches_16bits_tri_t_7));
  IOBUF dip_switches_16bits_tri_iobuf_8
       (.I(dip_switches_16bits_tri_o_8),
        .IO(dip_switches_16bits_tri_io[8]),
        .O(dip_switches_16bits_tri_i_8),
        .T(dip_switches_16bits_tri_t_8));
  IOBUF dip_switches_16bits_tri_iobuf_9
       (.I(dip_switches_16bits_tri_o_9),
        .IO(dip_switches_16bits_tri_io[9]),
        .O(dip_switches_16bits_tri_i_9),
        .T(dip_switches_16bits_tri_t_9));
  sw_led sw_led_i
       (.dip_switches_16bits_tri_i({dip_switches_16bits_tri_i_15,dip_switches_16bits_tri_i_14,dip_switches_16bits_tri_i_13,dip_switches_16bits_tri_i_12,dip_switches_16bits_tri_i_11,dip_switches_16bits_tri_i_10,dip_switches_16bits_tri_i_9,dip_switches_16bits_tri_i_8,dip_switches_16bits_tri_i_7,dip_switches_16bits_tri_i_6,dip_switches_16bits_tri_i_5,dip_switches_16bits_tri_i_4,dip_switches_16bits_tri_i_3,dip_switches_16bits_tri_i_2,dip_switches_16bits_tri_i_1,dip_switches_16bits_tri_i_0}),
        .dip_switches_16bits_tri_o({dip_switches_16bits_tri_o_15,dip_switches_16bits_tri_o_14,dip_switches_16bits_tri_o_13,dip_switches_16bits_tri_o_12,dip_switches_16bits_tri_o_11,dip_switches_16bits_tri_o_10,dip_switches_16bits_tri_o_9,dip_switches_16bits_tri_o_8,dip_switches_16bits_tri_o_7,dip_switches_16bits_tri_o_6,dip_switches_16bits_tri_o_5,dip_switches_16bits_tri_o_4,dip_switches_16bits_tri_o_3,dip_switches_16bits_tri_o_2,dip_switches_16bits_tri_o_1,dip_switches_16bits_tri_o_0}),
        .dip_switches_16bits_tri_t({dip_switches_16bits_tri_t_15,dip_switches_16bits_tri_t_14,dip_switches_16bits_tri_t_13,dip_switches_16bits_tri_t_12,dip_switches_16bits_tri_t_11,dip_switches_16bits_tri_t_10,dip_switches_16bits_tri_t_9,dip_switches_16bits_tri_t_8,dip_switches_16bits_tri_t_7,dip_switches_16bits_tri_t_6,dip_switches_16bits_tri_t_5,dip_switches_16bits_tri_t_4,dip_switches_16bits_tri_t_3,dip_switches_16bits_tri_t_2,dip_switches_16bits_tri_t_1,dip_switches_16bits_tri_t_0}),
        .led_16bits_tri_i(led_16bits_tri_i),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
