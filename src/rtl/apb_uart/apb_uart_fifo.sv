/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/24/2023
 * ---------------------------------------------------------------
 * apb_uart_fifo: Flop based FIFO
 * ---------------------------------------------------------------
*/

module apb_uart_fifo #(
    parameter WIDTH = 32,               // Data width
    parameter DEPTH = 4,                // FIFO depth
    parameter AWIDTH = $clog2(DEPTH)
) (
    input  logic                clk,
    input  logic                rst_b,
    input  logic                push,
    input  logic                pop,
    input  logic [WIDTH-1:0]    din,
    output logic [WIDTH-1:0]    dout,
    output logic                full,
    output logic                empty,
    output logic [AWIDTH:0]     entry
);



    reg [WIDTH-1:0]     mem[2**AWIDTH-1:0];
    reg [AWIDTH:0]      rd_ptr;
    reg [AWIDTH:0]      rd_ptr_nxt;
    reg [AWIDTH:0]      wt_ptr;
    reg [AWIDTH:0]      wt_ptr_nxt;

    logic               rd_en;
    logic               wr_en;
    logic [AWIDTH:0]    wrptr_minus_rdptr_next;

    // --------------------------------
    // FIFO control logic
    // --------------------------------
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            rd_ptr <= 'b0;
            wt_ptr <= 'b0;
        end
        else begin
            if (rd_en) rd_ptr <= rd_ptr_nxt;
            if (wr_en) wt_ptr <= wt_ptr_nxt;

        end
    end

    assign rd_ptr_nxt = rd_ptr + 1'b1;
    assign wt_ptr_nxt = wt_ptr + 1'b1;

    assign wr_en = ~full & push;
    assign rd_en = ~empty & pop;

    assign entry = wt_ptr - rd_ptr;

    // Make full and empty register based for better timing

    assign wrptr_minus_rdptr_next = wt_ptr_nxt - rd_ptr_nxt;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            full <= 1'b0;
            empty <= 1'b1; // FIFO is empty at reset
        end
        else begin
            full  <= (wrptr_minus_rdptr_next == DEPTH);
            empty <= (wrptr_minus_rdptr_next == 0);
        end
    end

    // --------------------------------
    // RAM control logic
    // --------------------------------
    always @(posedge clk) begin
        if (wr_en)
        begin
            mem[wt_ptr[AWIDTH-1:0]] <= din;
        end
    end

    // asynchronous read
    assign dout = mem[rd_ptr[AWIDTH-1:0]];


endmodule