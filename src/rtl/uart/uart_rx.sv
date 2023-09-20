/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/18/2022
 * ---------------------------------------------------------------
 * Uart RX
 * ---------------------------------------------------------------
*/

module uart_rx (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [15:0] cfg_div,
    input  logic        cfg_rxen,
    input  logic        cfg_nstop,
    output logic        rx_valid,
    output logic [7:0]  rx_data,
    input  logic        uart_rxd
);

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    logic baud_tick_6th;
    logic baud_tick_8th;
    logic baud_tick_10th;
    logic baud_tick_16th;
    logic baud_clear;

    logic [2:0] data_cnt;
    logic       stop_cnt;
    logic       last_data;
    logic       last_stop;

    logic [1:0] uart_rxd_doublesync;
    logic       uart_rxd_sync;

    logic [2:0] uart_rxd_sample;
    logic       uart_rxd_vote;


    localparam IDLE  = 0;
    localparam START = 1;
    localparam DATA  = 2;
    localparam STOP  = 3;

    logic [1:0] rx_state;
    logic [1:0] rx_state_next;

    logic arc_IDLE_to_START;
    logic arc_START_to_IDLE;
    logic arc_START_to_DATA;
    logic arc_DATA_to_STOP;
    logic arc_STOP_to_IDLE;

    logic IDLE_S;
    logic START_S;
    logic DATA_S;
    logic STOP_S;

    // --------------------------------------------
    //  Synchronization
    // --------------------------------------------

    always @(posedge clk) begin
        if (!rst_b) begin
            uart_rxd_doublesync <= 2'b0;
        end
        else begin
            uart_rxd_doublesync[0] <= uart_rxd;
            uart_rxd_doublesync[1] <= uart_rxd_doublesync[0];
        end
    end

    assign uart_rxd_sync = uart_rxd_doublesync[1];

    // --------------------------------------------
    //  RX State Machine
    // --------------------------------------------

    // state arc
    assign arc_IDLE_to_START = IDLE_S  & !uart_rxd_sync & cfg_rxen;
    assign arc_START_to_IDLE = START_S & uart_rxd_vote & baud_tick_16th;
    assign arc_START_to_DATA = START_S & !uart_rxd_vote & baud_tick_16th;
    assign arc_DATA_to_STOP  = DATA_S  & last_data & baud_tick_16th;
    assign arc_STOP_to_IDLE  = STOP_S  & last_stop & baud_tick_16th;

    // state
    assign IDLE_S  = (rx_state == IDLE);
    assign START_S = (rx_state == START);
    assign DATA_S  = (rx_state == DATA);
    assign STOP_S  = (rx_state == STOP);

    // state machine
    always @(posedge clk) begin
        if (!rst_b) begin
            rx_state <= IDLE;
        end
        else begin
            rx_state <= rx_state_next;
        end
    end

    always @(*) begin
        rx_state_next = rx_state;
        case(rx_state)
            IDLE: begin
                if (arc_IDLE_to_START)      rx_state_next = START;
            end
            START: begin
                if (arc_START_to_DATA)      rx_state_next = DATA;
                else if (arc_START_to_IDLE) rx_state_next = IDLE;
            end
            DATA: begin
                if (arc_DATA_to_STOP)       rx_state_next = STOP;
            end
            STOP: begin
                if (arc_STOP_to_IDLE)       rx_state_next = IDLE;
            end
        endcase
    end

    assign baud_clear = arc_IDLE_to_START;

    // --------------------------------------------
    //  2/3 Majority voter
    // --------------------------------------------

    always @(posedge clk) begin
        if (!rst_b) begin
            uart_rxd_sample <= 3'b0;
        end
        else begin
            if (baud_tick_6th)  uart_rxd_sample[0] <= uart_rxd_sync;
            if (baud_tick_8th)  uart_rxd_sample[1] <= uart_rxd_sync;
            if (baud_tick_10th) uart_rxd_sample[2] <= uart_rxd_sync;
        end
    end

    assign uart_rxd_vote = (uart_rxd_sample[0] & uart_rxd_sample[1]) |
                           (uart_rxd_sample[0] & uart_rxd_sample[2]) |
                           (uart_rxd_sample[1] & uart_rxd_sample[2]) ;

    // --------------------------------------------
    //  Receive data
    // --------------------------------------------

    always @(posedge clk) begin
        if (!rst_b) begin
            data_cnt <= 3'b0;
            rx_data <= 8'b0;
        end
        else begin
            // Data count will wrap back to zero after receiving the last data
            if (DATA_S && baud_tick_16th) data_cnt <= data_cnt + 1'b1;
            // The UART module transmits and receives the Least Significant bit (LSb) first
            if (DATA_S && baud_tick_16th) rx_data <= {uart_rxd_vote, rx_data[7:1]};
        end
    end

    assign last_data = (data_cnt == 3'd7);

    // --------------------------------------------
    //  Receive stop
    // --------------------------------------------

    always @(posedge clk) begin
        if (!rst_b) begin
            stop_cnt <= 1'b0;
        end
        else begin
            // clear the stop count when we enter STOP state
            if (arc_DATA_to_STOP) stop_cnt <= 1'b0;
            else if (STOP_S && baud_tick_16th) stop_cnt <= stop_cnt + 1'b1;
        end
    end

    assign last_stop = (stop_cnt == cfg_nstop);

    assign rx_valid = arc_STOP_to_IDLE;

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_baud u_uart_baud(
        .*
    );

endmodule
