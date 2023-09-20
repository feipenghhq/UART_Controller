/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/19/2023
 * ---------------------------------------------------------------
 * uart_rx_tb: testbench for uart_rx module
 * ---------------------------------------------------------------
*/

`timescale 1ns/10ps

module uart_rx_tb();

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    localparam CLK_PERIOD = 10;     // 10 ns clock
    localparam CLK_FREQ   = 1 * 1000000000 / CLK_PERIOD;
    localparam BAUD_RATE  = 115200;

    logic        clk;
    logic        rst_b;
    logic [15:0] cfg_div;
    logic        cfg_rxen;
    logic        cfg_nstop;
    logic        rx_valid;
    logic [7:0]  rx_data;
    logic        uart_rxd;

    // --------------------------------------------
    //  Instantiate DUT
    // --------------------------------------------

    uart_rx u_uart_rx (.*);

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
    localparam TEST_NUM = 16;

    // initial value
    initial begin
        cfg_nstop = 1'b0;
        cfg_rxen = 1'b1;
        cfg_div = CLK_FREQ / BAUD_RATE + 1;
        uart_rxd = 1'b1;
    end

    initial begin
        @(posedge rst_b);
        $display("--------------------------------");
        $display("Running Test: uart_rx_tb");
        $display("--------------------------------");
        repeat(TEST_NUM) begin
            send_data = $random;
            fork
            uart_driver(cfg_nstop, period, send_data);
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
            $dumpvars(0,uart_rx_tb);
        end
    end

endmodule