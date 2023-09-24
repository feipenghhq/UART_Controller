/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/24/2023
 * ---------------------------------------------------------------
 * apb_uart_ctrl: APB uart register and control module
 * ---------------------------------------------------------------
*/

`include "apb_uart_reg.svh"

module apb_uart_ctrl (
    input  logic        clk,
    input  logic        rst_b,
    // APB interface
    input  logic        apb_penable,
    input  logic        apb_psel,
    input  logic        apb_pwrite,
    input  logic [4:0]  apb_paddr,
    input  logic [31:0] apb_pwdata,
    output logic [31:0] apb_prdata,
    output logic        apb_pready,
    output logic        apb_pslverr,
    // Interface to uart
    output logic        tx_valid,
    output logic [7:0]  tx_data,
    input  logic        tx_ready,
    input  logic        rx_valid,
    input  logic [7:0]  rx_data,
    output logic [15:0] cfg_div,
    output logic        cfg_txen,
    output logic        cfg_rxen,
    output logic        cfg_nstop,
    // Interrupt
    output logic        txwm,
    output logic        rxwm
);

    // --------------------------------------------
    //  Sginal Declaration
    // --------------------------------------------
    // FIFO control
    logic           txfifo_push;
    logic           txfifo_pop;
    logic [7:0]     txfifo_din;
    logic [7:0]     txfifo_dout;
    logic           txfifo_full;
    logic           txfifo_empty;
    logic [3:0]     txfifo_entry;

    logic           rxfifo_push;
    logic           rxfifo_pop;
    logic [7:0]     rxfifo_din;
    logic [7:0]     rxfifo_dout;
    logic           rxfifo_full;
    logic           rxfifo_empty;
    logic [3:0]     rxfifo_entry;

    logic           apb_setup;
    logic           apb_access;

    logic           reg_read;
    logic           reg_write;

    // registers
    txdata_t        txdata;

    rxdata_t        rxdata;

    txctrl_t        txctrl;
    logic [2:0]     txctrl_txcnt;
    logic           txctrl_nstop;
    logic           txctrl_txen;

    rxctrl_t        rxctrl;
    logic [2:0]     rxctrl_rxcnt;
    logic           rxctrl_rxen;

    ie_t            ie;
    logic           ie_rxwm;
    logic           ie_txwm;

    ip_t            ip;
    logic           ip_rxwm;
    logic           ip_txwm;

    div_t           div;
    logic [15:0]    div_div;


    // --------------------------------------------
    //  APB state and control
    // --------------------------------------------

    assign apb_setup  = apb_psel & ~apb_penable;
    assign apb_access = apb_psel & apb_penable;

    assign reg_read = apb_setup & ~apb_pwrite;
    assign reg_write = apb_setup & apb_pwrite;

    // --------------------------------------------
    //  Register and corresponding control logic
    // --------------------------------------------

    // Macros
    `define APB_UART_REG(name, addr) \
    logic ``name``_hit;     \
    logic ``name``_read;    \
    logic ``name``_write;   \
    assign ``name``_hit   = (apb_paddr == addr);        \
    assign ``name``_read  = ``name``_hit & reg_read;    \
    assign ``name``_write = ``name``_hit & reg_write;   \

    // ------------------------
    // txdata register
    // ------------------------
    `APB_UART_REG(txdata, 5'h0)

    assign txdata.full = txfifo_full;
    assign txdata.rsvd = 23'h0;
    assign txdata.data = 8'h0;  // data field is read only

    // ------------------------
    // rxdata register
    // ------------------------
    `APB_UART_REG(rxdata, 5'h4)

    assign rxdata.empty = rxfifo_empty;
    assign rxdata.rsvd = 23'h0;
    assign rxdata.data = rxfifo_dout;

    // ------------------------
    // txctrl register
    // ------------------------
    `APB_UART_REG(txctrl, 5'h8)

    assign txctrl.rsvd1 = 0;
    assign txctrl.rsvd0 = 0;
    assign txctrl.txcnt = txctrl_txcnt;
    assign txctrl.nstop = txctrl_nstop;
    assign txctrl.txen  = txctrl_txen;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            txctrl_txcnt <= 3'b0;
            txctrl_nstop <= 1'b0;
            txctrl_txen <= 1'b0;
        end
        else begin
            if (txctrl_write) begin
                txctrl_txcnt <= apb_pwdata[18:16];
                txctrl_nstop <= apb_pwdata[1];
                txctrl_txen  <= apb_pwdata[0];
            end
        end
    end

    // ------------------------
    // rxctrl register
    // ------------------------
    `APB_UART_REG(rxctrl, 5'hC)

    assign rxctrl.rsvd1 = 0;
    assign rxctrl.rsvd0 = 0;
    assign rxctrl.rxcnt = rxctrl_rxcnt;
    assign rxctrl.rxen  = rxctrl_rxen;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            rxctrl_rxcnt <= 3'b0;
            rxctrl_rxen <= 1'b0;
        end
        else begin
            if (rxctrl_write) begin
                rxctrl_rxcnt <= apb_pwdata[18:16];
                rxctrl_rxen  <= apb_pwdata[0];
            end
        end
    end

    // ------------------------
    // ie register
    // ------------------------
    `APB_UART_REG(ie, 5'h10)

    assign ie.rsvd = 0;
    assign ie.rxwm = ie_rxwm;
    assign ie.txwm = ie_txwm;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            ie_txwm <= 1'b0;
            ie_rxwm <= 1'b0;
        end
        else begin
            if (ie_write) begin
                ie_txwm <= apb_pwdata[0];
                ie_rxwm <= apb_pwdata[1];
            end
        end
    end

    // ------------------------
    // ip register
    // ------------------------
    `APB_UART_REG(ip, 5'h14)

    assign ip.rsvd = 0;
    assign ip.rxwm = ip_rxwm;
    assign ip.txwm = ip_txwm;

    assign ip_txwm = ie_txwm & (txfifo_entry[2:0] < txctrl_txcnt);
    assign ip_rxwm = ie_rxwm & (rxfifo_entry[2:0] > rxctrl_rxcnt) & ~rxfifo_empty;

    // ------------------------
    // div register
    // ------------------------
    `APB_UART_REG(div, 5'h18)

    assign div.rsvd = 0;
    assign div.div = div_div;


    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            div_div <= 16'b0;
        end
        else begin
            if (div_write) begin
                div_div <= apb_pwdata[15:0];
            end
        end
    end

    `undef APU_UART_REG

    // --------------------------------------------
    // FIFO and Uart control
    // --------------------------------------------

    // TX fifo and uart tx control
    assign txfifo_push = ~txfifo_full & txdata_write;
    assign txfifo_din = apb_pwdata[7:0];

    assign tx_data = txfifo_dout;
    assign tx_valid = ~txfifo_empty & tx_ready;
    assign txfifo_pop = tx_valid;

    // RX fifo and uart rx control
    assign rxfifo_pop = ~rxfifo_empty & rxdata_read;

    assign rxfifo_push = ~rxfifo_full & rx_valid;
    assign rxfifo_din = rx_data;

    // config
    assign cfg_nstop = txctrl_nstop;
    assign cfg_txen  = txctrl_txen;
    assign cfg_rxen  = rxctrl_rxen;
    assign cfg_div   = div_div;

    // interrupt
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            txwm <= 1'b0;
            rxwm <= 1'b0;
        end
        else begin
            txwm <= ip_txwm;
            rxwm <= ip_rxwm;
        end
    end

    // --------------------------------------------
    //  APB read logic
    // --------------------------------------------

    assign apb_pready = 1'b1;  // always set ready to 1
    assign apb_pslverr = 1'b0; // always set slv err to zero

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            apb_prdata <= 32'b0;
        end
        else begin
            apb_prdata <= ({32{txdata_read}} & txdata) |
                          ({32{rxdata_read}} & rxdata) |
                          ({32{txctrl_read}} & txctrl) |
                          ({32{rxctrl_read}} & rxctrl) |
                          ({32{ie_read}}     & ie    ) |
                          ({32{ip_read}}     & ip    ) |
                          ({32{div_read}}    & div   ) ;
        end
    end

    // --------------------------------------------
    // Uart FIFO instantiation
    // --------------------------------------------

    apb_uart_fifo #( .WIDTH (8), .DEPTH (8))
    u_tx_fifo (
        .clk    (clk),
        .rst_b  (rst_b),
        .push   (txfifo_push),
        .pop    (txfifo_pop),
        .din    (txfifo_din),
        .dout   (txfifo_dout),
        .full   (txfifo_full),
        .empty  (txfifo_empty),
        .entry  (txfifo_entry)
    );

    apb_uart_fifo #( .WIDTH (8), .DEPTH (8))
    u_rx_fifo (
        .clk    (clk),
        .rst_b  (rst_b),
        .push   (rxfifo_push),
        .pop    (rxfifo_pop),
        .din    (rxfifo_din),
        .dout   (rxfifo_dout),
        .full   (rxfifo_full),
        .empty  (rxfifo_empty),
        .entry  (rxfifo_entry)
    );

endmodule