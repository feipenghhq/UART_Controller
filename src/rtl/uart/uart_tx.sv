/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/19/2022
 * ---------------------------------------------------------------
 * Uart TX.
 * ---------------------------------------------------------------
*/

module uart_tx (
    input  logic        clk,
    input  logic        rst_b,

    input  logic [15:0] cfg_div,
    input  logic        cfg_txen,
    input  logic        cfg_nstop,

    input  logic        tx_valid,
    input  logic [7:0]  tx_data,
    output logic        tx_ready,

    output logic        uart_txd
);

    // --------------------------------------------
    //  Signal Declaration
    // --------------------------------------------

    logic baud_tick_16th;
    logic baud_clear;

    logic [9:0] uart_data;
    logic [2:0] data_cnt;
    logic       stop_cnt;
    logic       last_data;
    logic       last_stop;

    localparam IDLE  = 0;
    localparam START = 1;
    localparam DATA  = 2;
    localparam STOP  = 3;

    logic [1:0] tx_state;
    logic [1:0] tx_state_next;

    logic arc_IDLE_to_START;
    logic arc_START_to_DATA;
    logic arc_DATA_to_STOP;
    logic arc_STOP_to_IDLE;

    logic IDLE_S;
    logic START_S;
    logic DATA_S;
    logic STOP_S;

    // --------------------------------------------
    //  TX State Machine
    // --------------------------------------------

    // state arc
    assign arc_IDLE_to_START = IDLE_S  & tx_valid & cfg_txen;
    assign arc_START_to_DATA = START_S & baud_tick_16th;
    assign arc_DATA_to_STOP  = DATA_S  & last_data & baud_tick_16th;
    assign arc_STOP_to_IDLE  = STOP_S  & last_stop & baud_tick_16th;

    // state
    assign IDLE_S  = (tx_state == IDLE);
    assign START_S = (tx_state == START);
    assign DATA_S  = (tx_state == DATA);
    assign STOP_S  = (tx_state == STOP);

    // state machine
    always @(posedge clk) begin
        if (!rst_b) begin
            tx_state <= IDLE;
        end
        else begin
            tx_state <= tx_state_next;
        end
    end

    always @(*) begin
        tx_state_next = tx_state;
        case(tx_state)
            IDLE: begin
                if (arc_IDLE_to_START)      tx_state_next = START;
            end
            START: begin
                if (arc_START_to_DATA)      tx_state_next = DATA;
            end
            DATA: begin
                if (arc_DATA_to_STOP)       tx_state_next = STOP;
            end
            STOP: begin
                if (arc_STOP_to_IDLE)       tx_state_next = IDLE;
            end
        endcase
    end

    // --------------------------------------------
    // uart_data
    // --------------------------------------------

    // uart data include the start bit, the data bits and the stop bits

    always @(posedge clk) begin
        if (!rst_b) begin
            data_cnt <= 3'b0;
            stop_cnt <= 1'b0;
            uart_data <= 10'b1; // LSB should be reset to one to make uart_txd default high.
        end
        else begin
            // received new data
            if (arc_IDLE_to_START) uart_data <= {1'b1, tx_data, 1'b0}; // stop, data, start
            // The UART module transmits and receives the Least Significant bit (LSb) first
            // Shift on the 16th sample tick in START and DATA state.
            // No need to shift on the STOP state as the data is fixed to 1 for stop bit.
            else if ((START_S || DATA_S) && baud_tick_16th) uart_data <= uart_data >> 1;

            // Data count will wrap back to zero after receiving the last data
            if (DATA_S && baud_tick_16th) data_cnt <= data_cnt + 1'b1;

            // stop bit
            if (arc_DATA_to_STOP) stop_cnt <= 1'b0;
            else if (STOP_S && baud_tick_16th) stop_cnt <= stop_cnt + 1'b1;
        end
    end

    assign last_data = (data_cnt == 3'd7);
    assign last_stop = (stop_cnt == cfg_nstop);

    // --------------------------------------------
    // uart_txd and misc
    // --------------------------------------------

    assign uart_txd = uart_data[0];
    assign tx_ready = IDLE_S;
    assign baud_clear = arc_IDLE_to_START;

    // --------------------------------------------
    //  Module instantiation
    // --------------------------------------------

    uart_baud u_uart_baud(
        .clk            (clk),
        .rst_b          (rst_b),
        .cfg_div        (cfg_div),
        .baud_clear     (baud_clear),
        .baud_tick_16th (baud_tick_16th)
    );

endmodule
