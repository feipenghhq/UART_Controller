/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/24/2023
 * ---------------------------------------------------------------
 * apb_uart_tb: testbench for apb_uart module
 * ---------------------------------------------------------------
*/

// This testbench loop back the uart_txd to uart_rxd and checks if the received data is the same as the send data

`timescale 1ns/10ps

`include "uart_tb.svh"
`define ASSERT(cond) assert(cond); if (!(cond)) error++;

module apb_uart_tb();

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    localparam CLK_PERIOD = 10;     // 10 ns clock
    localparam CLK_FREQ   = 1 * 1000000000 / CLK_PERIOD;
    localparam BAUD_RATE  = 115200;
    localparam TRANS_TIME = (1 * 1000000000 / BAUD_RATE) * 10 + 1000;

    logic        clk;
    logic        rst_b;
    logic        apb_penable;
    logic        apb_psel;
    logic        apb_pwrite;
    logic [4:0]  apb_paddr;
    logic [31:0] apb_pwdata;
    logic [31:0] apb_prdata;
    logic        apb_pready;
    logic        apb_pslverr;
    logic        uart_txd;
    logic        uart_rxd;
    logic        txwm;
    logic        rxwm;

    // --------------------------------------------
    //  Instantiate DUT
    // --------------------------------------------

    apb_uart u_apb_uart (.*);

    assign uart_rxd = uart_txd;

    // --------------------------------------------
    //  clock and reset
    // --------------------------------------------

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

    txdata_t        txdata;
    rxdata_t        rxdata;
    txctrl_t        txctrl;
    rxctrl_t        rxctrl;
    ie_t            ie;
    ip_t            ip;
    div_t           div;

    integer         error = 0;
    integer         tx_id = 0;
    integer         rx_id = 0;
    bit [7:0]       tx_data_arr[0:10];
    bit [7:0]       rx_data_arr[0:10];

    assign txctrl.txcnt = 4;
    assign txctrl.nstop = 0;
    assign txctrl.txen = 1;

    assign rxctrl.rxcnt = 4;
    assign rxctrl.rxen = 1;

    assign ie.txwm = 1;
    assign ie.rxwm = 1;

    assign div.rsvd = 0;
    assign div.div = CLK_FREQ / BAUD_RATE + 1;

    logic [7:0] send_data;

    // initial value
    initial begin
        apb_penable = 0;
        apb_psel = 0;
        apb_pwrite = 0;
        apb_paddr = 0;
        apb_pwdata = 0;
    end

    initial begin
        @(posedge rst_b);
        $display("--------------------------------");
        $display("Running Test: apb_uart_tb");
        $display("--------------------------------");
        uart_setup();
        test_reg();
        #20;
        if (!error) display_pass();
        else display_fail();
        $finish;
    end

    // --------------------------------------------
    //  Test task
    // --------------------------------------------

    task uart_setup;
        apb_driver(5'h8,  txctrl);
        apb_driver(5'hC,  rxctrl);
        apb_driver(5'h10, ie);
        apb_driver(5'h18, div);
    endtask

    task send_random_data;
        send_data = $random;
        apb_driver(5'h0, {24'b0, send_data});
        tx_data_arr[tx_id] = send_data;
        tx_id++;
    endtask

    task receive_data;
        apb_reader(5'h4, rxdata);
        rx_data_arr[rx_id] = rxdata.data;
        rx_id++;
    endtask

    // test registers
    task test_reg;
        apb_reader(5'h0, txdata);
        apb_reader(5'h4, rxdata);
        apb_reader(5'h14, ip);
        `ASSERT(txdata.full == 1'b0);
        `ASSERT(rxdata.empty == 1'b1);
        `ASSERT(ip.txwm == 1'b1);
        `ASSERT(ip.rxwm == 1'b0);
        // send 4 data and txwm should be 1
        repeat (4) begin
            send_random_data();
        end
        apb_reader(5'h14, ip);
        `ASSERT(ip.txwm == 1'b1);
        // send 5th data and txwm should be 0
        send_random_data();
        apb_reader(5'h14, ip);
        `ASSERT(ip.txwm == 1'b0);
        // send 4 more data and txdata full should be 1
        repeat (4) send_random_data();
        apb_reader(5'h0, txdata);
        `ASSERT(txdata.full == 1'b1);
        // Now wait for the rx
        #TRANS_TIME;
        receive_data(); // receive 1st data
        `ASSERT(rxdata.empty == 1'b0);
        // Wait for 4 more data and rxwm should be 0
        #(TRANS_TIME*4);
        apb_reader(5'h14, ip);
        `ASSERT(ip.rxwm == 1'b0);
        // Wait for 1 more data and rxwm should be 1
        #(TRANS_TIME);
        apb_reader(5'h14, ip);
        `ASSERT(ip.rxwm == 1'b1);
        // Wait for the rest of the data
        #(TRANS_TIME*3);
        // receive the remaining data
        repeat(8) receive_data();
        // check data
        for (int i = 0; i < 9; i++) begin
            assert(tx_data_arr[i] == rx_data_arr[i]) else begin
                error++;
                $error("Received wrong data. ID: %d. Expected: %h. Recieved: %h", i, tx_data_arr[i], rx_data_arr[i]);
            end
        end
    endtask

    // --------------------------------------------
    //  APB Functions
    // --------------------------------------------

    task apb_driver;
        input integer addr;
        input [31:0]  data;
        // Setup state
        @(posedge clk);
        #0;
        apb_psel    = 1'b1;
        apb_penable = 1'b0;
        apb_pwrite  = 1'b1;
        apb_paddr   = addr;
        apb_pwdata  = data;
        // Access state
        @(posedge clk);
        #0;
        apb_psel    = 1'b1;
        apb_penable = 1'b1;
        apb_pwrite  = 1'b1;
        apb_paddr   = addr;
        apb_pwdata  = data;
        // Clear request
        @(posedge clk);
        #0;
        apb_psel    = 0;
        apb_penable = 0;
        apb_pwrite  = 0;
        apb_paddr   = 0;
        apb_pwdata  = 0;
    endtask

    task apb_reader;
        input  integer addr;
        output [31:0]  data;
        // Setup state
        @(posedge clk);
        #0;
        apb_psel    = 1'b1;
        apb_penable = 1'b0;
        apb_pwrite  = 1'b0;
        apb_paddr   = addr;
        // Access state
        @(posedge clk);
        #0;
        apb_psel    = 1'b1;
        apb_penable = 1'b1;
        apb_pwrite  = 1'b0;
        apb_paddr   = addr;
        @(negedge clk);
        data        = apb_prdata;
        // Clear request
        @(posedge clk);
        #0;
        apb_psel    = 0;
        apb_penable = 0;
        apb_pwrite  = 0;
        apb_paddr   = 0;
    endtask

    // --------------------------------------------
    //  waveform
    // --------------------------------------------

    initial begin
        if ($test$plusargs("DUMP")) begin
            $dumpfile("dump.vcd");
            $dumpvars(0,apb_uart_tb);
        end
    end

endmodule