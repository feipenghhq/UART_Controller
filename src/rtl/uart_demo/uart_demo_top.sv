/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/20/2022
 * ---------------------------------------------------------------
 * top: Top level of the FPGA demo program
 * ---------------------------------------------------------------
*/

module uart_demo_top #(
    parameter BAUDRATE = 115200,
    parameter CLK_FREQ = 100 * 1000000
) (
    input           clk,
    input           rst_b,
    output          uart_txd,
    input           uart_rxd,
    input [3:0]     sw,
    input           btn0,
    input           btn1,
    output [3:0]    led
);

    uart_demo u_uart_demo(.*);

endmodule