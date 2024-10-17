//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Thu May 23 14:19:51 2024
//Host        : Digital-15 running 64-bit major release  (build 9200)
//Command     : generate_target pwm_servo_wrapper.bd
//Design      : pwm_servo_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module pwm_servo_wrapper
   (pwm_512_0,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  output pwm_512_0;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire pwm_512_0;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  pwm_servo pwm_servo_i
       (.pwm_512_0(pwm_512_0),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule
