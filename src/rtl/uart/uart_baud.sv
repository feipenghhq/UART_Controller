/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/18/2023
 * ---------------------------------------------------------------
 * uart_baud: generate baud tick for tx and rx module
 * ---------------------------------------------------------------
*/

module uart_baud (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [15:0] cfg_div,        // cfg_div = F_clk/F_baud - 1
    input  logic        baud_clear,     // Clear the clock divider counter and start a new sampling.
    output logic        baud_tick_6th,
    output logic        baud_tick_8th,
    output logic        baud_tick_10th,
    output logic        baud_tick_16th
);

    logic        baud_tick;
    logic [13:0] baud_counter;
    logic [3:0]  baud_tick_count;

    // Because we use 16x oversampling, we count the value of cfg_div/16 for each tick.
    // This will lost some accuracy but it is acceptable with clock rate > 50Mhz.
    // For example, if clock frequency is 50Mhz and baud rate is 115200.
    // cfg_div = 50 * 1000000 / 115200 - 1 = 433
    // cfg_div / 16 = 433 >> 2 = 108
    // 108 * 4 = 432 so the delta is (433 - 432) / 433 = 0.231%

    always @(posedge clk) begin
        if (!rst_b) begin
            baud_counter <= 14'b0;
        end
        else begin
            if (baud_clear || baud_tick) baud_counter <= cfg_div[15:4];
            else baud_counter <= baud_counter - 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!rst_b) begin
            baud_tick_count <= 4'b0;
        end
        else begin
            if (baud_clear || baud_tick_16th) baud_tick_count <= 0;
            else if (baud_tick) baud_tick_count <= baud_tick_count + 1'b1;
        end
    end

    assign baud_tick = (baud_counter == 14'b1); // tick at the last count so it's 1 instead of 0.
    assign baud_tick_6th = baud_tick & (baud_tick_count == 4'd5);
    assign baud_tick_8th = baud_tick & (baud_tick_count == 4'd7);
    assign baud_tick_10th = baud_tick & (baud_tick_count == 4'd9);
    assign baud_tick_16th = baud_tick & (baud_tick_count == 4'd15);

endmodule
