/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/20/2023
 * ---------------------------------------------------------------
 * uart_core_tb: testbench for uart_core module
 * ---------------------------------------------------------------
*/

// This testbench loop back the uart_txd to uart_rxd and checks if the received data is the same as the send data

`timescale 1ns/10ps
`define UART_TX_DRIVER
`define UART_RX_CHECKER

module uart_core_tb();

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    localparam CLK_PERIOD = 10;     // 10 ns clock
    localparam CLK_FREQ   = 1 * 1000000000 / CLK_PERIOD;
    localparam BAUD_RATE  = 115200;

    logic        clk;
    logic        rst_b;
    logic [15:0] cfg_div;
    logic        cfg_txen;
    logic        cfg_rxen;
    logic        cfg_nstop;
    logic        tx_valid;
    logic [7:0]  tx_data;
    logic        tx_ready;
    logic        uart_txd;
    logic        rx_valid;
    logic [7:0]  rx_data;
    logic        uart_rxd;

    // --------------------------------------------
    //  Instantiate DUT
    // --------------------------------------------

    uart_core u_uart_core (.*);

    assign uart_rxd = uart_txd;

    // --------------------------------------------
    //  clock and reset
    // --------------------------------------------

    `include "uart_tb.svh"

    // clock and reset
    initial begin
        clk = 1'b0;
        rst_b = 1'b0;
        #30;
        @(posedge clk);
        #0 rst_b = 1'b1;
    end

    always @(*) #5 clk <= ~clk;

    // --------------------------------------------
    //  Test stimulus and checks
    // --------------------------------------------

    logic [7:0] send_data;
    integer period = 1 * 1000000000 / BAUD_RATE;
    integer send_id = 0;
    localparam TEST_NUM = 16;

    // initial value
    initial begin
        tx_valid = 1'b0;
        tx_data = 8'b0;
        cfg_nstop = 1'b0;
        cfg_txen = 1'b1;
        cfg_rxen = 1'b1;
        cfg_div = CLK_FREQ / BAUD_RATE + 1;
    end

    initial begin
        @(posedge rst_b);
        $display("--------------------------------");
        $display("Running Test: uart_core_tb");
        $display("--------------------------------");
        repeat(TEST_NUM) begin
            send_data = $random;
            fork
            $display("[uart_core_tb]    INFO: [ID:%0d] Sending data: 0x%h", send_id++, send_data);
            uart_tx_driver(send_data);
            uart_rx_checker(send_data);
            join
        end
        #20;
        if (!rx_error) display_pass();
        else display_fail();
        $finish;
    end

    // --------------------------------------------
    //  waveform
    // --------------------------------------------

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile("dump.vcd");
            $dumpvars(0,uart_core_tb);
        end
    end

endmodule