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

integer scoreboard_id = 0;
integer rx_error = 0;

task uart_rx_checker;
    input [7:0] golden_data;
    @(posedge rx_valid) begin
        if (rx_data !== golden_data) begin
            $error("[uart_scoreboard] ERROR: Received wrong data: 0x%h. Expected data: 0x%h. ID: %0d.", rx_data, golden_data, scoreboard_id);
            rx_error++;
        end
        else begin
            $display("[uart_scoreboard] INFO: [ID:%0d] Received correct data: 0x%h", scoreboard_id, rx_data);
        end
        scoreboard_id++;
    end
endtask

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
