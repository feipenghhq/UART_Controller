/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/25/2023
 * ---------------------------------------------------------------
 * apb_uart: memory mapped UART with APB interface
 * ---------------------------------------------------------------
*/

module apb_uart (
    input  logic        clk,
    input  logic        rst_b,
    // APB interface
    input  logic        apb_penable,
    input  logic        apb_psel,
    input  logic        apb_pwrite,
    input  logic [4:0]  apb_paddr,
    input  logic [31:0] apb_pwdata,
    output logic [31:0] apb_prdata,
    output logic        apb_pready,
    output logic        apb_pslverr,
    // Uart signal
    output logic        uart_txd,
    input  logic        uart_rxd,
    // Interrupt
    output logic        txwm,
    output logic        rxwm
);

    // Interface to uart
    logic        tx_valid;
    logic [7:0]  tx_data;
    logic        tx_ready;
    logic        rx_valid;
    logic [7:0]  rx_data;
    logic [15:0] cfg_div;
    logic        cfg_txen;
    logic        cfg_rxen;
    logic        cfg_nstop;

    // Module instantiation
    uart_core u_uart_core(.*);
    apb_uart_ctrl u_apb_uart_ctrl(.*);

endmodule