/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/20/2022
 * ---------------------------------------------------------------
 * uart_demo program
 * ---------------------------------------------------------------
*/

module uart_demo #(
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

    // --------------------------------------------
    //  Signal Declarations
    // --------------------------------------------

    logic [15:0]    cfg_div;
    logic           cfg_txen;
    logic           cfg_rxen;
    logic           cfg_nstop;

    logic           tx_valid;
    logic [7:0]     tx_data;
    logic           tx_ready;
    logic           rx_valid;
    logic [7:0]     rx_data;

    logic [7:0]     rcvd_data;
    logic [3:0]     sw_data;
    logic [3:0]     led_data;

    logic [2:0]     btn0_sync;
    logic [2:0]     btn1_sync;

    logic           btn0_pulse;
    logic           btn1_pulse;

    // --------------------------------------------
    //  Set up config
    // --------------------------------------------

    assign cfg_txen = 1'b1;
    assign cfg_rxen = 1'b1;
    assign cfg_nstop = 1'b0;
    assign cfg_div = (CLK_FREQ / BAUDRATE) + 1'b1;

    // --------------------------------------------
    //  Receive the data from host
    // --------------------------------------------

    always @(posedge clk) begin
        if (!rst_b) begin
            rcvd_data <= 8'b0;
        end
        else begin
            if (rx_valid) begin
                rcvd_data <= rx_data;
            end
        end
    end

    assign led_data = rcvd_data[3:0];
    assign led = led_data;

    // --------------------------------------------
    //  Send the data to host
    // --------------------------------------------

    // synchronize btn
    always @(posedge clk) begin
        if (!rst_b) begin
            btn0_sync <= 3'b0;
            btn1_sync <= 3'b0;
        end
        else begin
            btn0_sync <= {btn0_sync[1:0], btn0};
            btn1_sync <= {btn1_sync[1:0], btn1};
        end
    end

    // create a pulse from btn
    assign btn0_pulse = btn0_sync[1] & ~btn0_sync[2];
    assign btn1_pulse = btn1_sync[1] & ~btn1_sync[2];

    // send request to uart
    assign tx_valid = (btn0_pulse | btn1_pulse) & tx_ready;
    assign tx_data = btn0_pulse ? rcvd_data : {4'b0, sw};

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_core u_uart_core(.*);

endmodule