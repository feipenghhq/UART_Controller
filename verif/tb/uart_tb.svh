/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/18/2022
 * ---------------------------------------------------------------
 * Include file for uart tb. Contains comment tasks
 * ---------------------------------------------------------------
*/

integer uart_driver_id = 0;
integer rx_scb_id = 0;
integer rx_error = 0;
integer tx_error = 0;
integer tx_scb_id = 0;
bit     tx_data_received = 0;

// ---------------------------------------------
// Uart Driver
// ---------------------------------------------

`ifdef UART_DRIVER
task uart_driver;
    input           cfg_nstop;
    input integer   period; // time to transfer one bit
    input [7:0]     data;
    begin
        $display("[uart_driver]     INFO: [ID:%0d] Start sending data: 0x%h.", uart_driver_id, data);
        // start condition
        @(posedge clk);
        #0 uart_rxd = 1'b0;
        #period;
        // send the 8 data bit
        repeat(8) begin
        uart_rxd = data[0]; // send LSB first
        data = data >> 1;
        #period;
        end
        // send the stop bit
        repeat(cfg_nstop+1) begin
        uart_rxd = 1'b1;
        #period;
        end
        $display("[uart_driver]     INFO: [ID:%0d] Finished Sending data.", uart_driver_id);
        uart_driver_id++;
    end
endtask
`endif

// ---------------------------------------------
// Uart RX Checker
// ---------------------------------------------

`ifdef UART_RX_CHECKER
task uart_rx_checker;
    input [7:0] golden_data;
    @(posedge rx_valid) begin
        if (rx_data !== golden_data) begin
            $error("[uart_scoreboard] ERROR: Received wrong data: 0x%h. Expected data: 0x%h. ID: %0d.", rx_data, golden_data, rx_scb_id);
            rx_error++;
        end
        else begin
            $display("[uart_scoreboard] INFO: [ID:%0d] Received correct data: 0x%h", rx_scb_id, rx_data);
        end
        rx_scb_id++;
    end
endtask
`endif

// ---------------------------------------------
// Uart Receiver
// ---------------------------------------------

`ifdef UART_RECEIVER
task uart_receiver;
    input           cfg_nstop;
    input integer   period; // time to transfer one bit
    output [7:0]    data;
    begin
        data = 8'b0;
        $display("[uart_receiver]   INFO: [ID:%0d] Start receiving data.", uart_driver_id);
        // detect start condition
        @(negedge uart_txd);
        // Delay half of the period to sample in the middle of the transfer.
        // since this is simulation, we don't expect to have glitch on the
        // data signal so no need to do 2/3 majority voter in testbench.
        #(period/2);
        if (uart_txd != 0) begin
            $error("[uart_receiver]   ERROR: Detected start condition but sampled uart_txd as high at the middle of the start bit");
            tx_error++;
        end
        // receive the 8 data bit
        repeat(8) begin
            #(period);
            // LSB is sent first
            data = {uart_txd, data} >> 1;
        end
        // send the stop bit
        repeat(cfg_nstop+1) begin
            #(period);
            if (uart_txd != 1) begin
                $error("[uart_receiver]   ERROR: Should receive stop condition but sampled uart_txd as low at the middle of the stop bit");
                tx_error++;
            end
        end
        $display("[uart_receiver]   INFO: [ID:%0d] Finished receiving data. Received: %0h", uart_driver_id, data);
        @(posedge clk);
        #0 tx_data_received = 1'b1;
        @(posedge clk);
        #0 tx_data_received = 1'b0;
        uart_driver_id++;
    end
endtask
`endif

// ---------------------------------------------
// Uart TX driver
// ---------------------------------------------
`ifdef UART_TX_DRIVER
task uart_tx_driver;
    input [7:0] data;
    begin
        wait(tx_ready);
        @(posedge clk);
        #0;
        tx_data = data;
        tx_valid = 1'b1;
        @(posedge clk);
        #0;
        tx_data = 0;
        tx_valid = 1'b0;
    end
endtask
`endif

// ---------------------------------------------
// Uart TX checker
// ---------------------------------------------
`ifdef UART_TX_CHECKER
task uart_tx_checker;
    input [7:0] send_data;
    input [7:0] received_data;
    if (send_data !== received_data) begin
        $error("[uart_scoreboard] ERROR: Uart TX send wrong data: 0x%h. Expected data: 0x%h. ID: %0d.",
                received_data, send_data, tx_scb_id);
        rx_error++;
    end
    else begin
        $display("[uart_scoreboard] INFO: [ID:%0d] Uart TX send correct data: 0x%h", tx_scb_id, received_data);
    end
    tx_scb_id++;
endtask
`endif

task display_pass;
    $display("--------------------------------");
    $display("Test Result");
    $display("--------------------------------");
    $display("");
    $display("      ____  ___   __________  ");
    $display("     / __ \\/   | / ___/ ___/  ");
    $display("    / /_/ / /| | \\__ \\__ \\   ");
    $display("   / ____/ ___ |___/ /__/ /   ");
    $display("  /_/   /_/  |_/____/____/    ");
    $display("");
    $display("--------------------------------");
endtask

task display_fail;
    $display("--------------------------------");
    $display("Test Result");
    $display("--------------------------------");
    $display("");
    $display("    _________    ______   ");
    $display("   / ____/   |  /  _/ /   ");
    $display("  / /_  / /| |  / // /    ");
    $display(" / __/ / ___ |_/ // /___  ");
    $display("/_/   /_/  |_/___/_____/  ");
    $display("                          ");
    $display("");
    $display("--------------------------------");
endtask
