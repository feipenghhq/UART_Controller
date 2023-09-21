/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/19/2022
 * ---------------------------------------------------------------
 * Uart Core
 * ---------------------------------------------------------------
*/

module uart_core (
    input           clk,
    input           rst_b,

    input [15:0]    cfg_div,
    input           cfg_txen,
    input           cfg_rxen,
    input           cfg_nstop,

    input           tx_valid,
    input [7:0]     tx_data,
    output          tx_ready,
    output          rx_valid,
    output [7:0]    rx_data,

    output          uart_txd,
    input           uart_rxd
);

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_tx u_uart_tx(.*);
    uart_rx u_uart_rx(.*);

endmodule
