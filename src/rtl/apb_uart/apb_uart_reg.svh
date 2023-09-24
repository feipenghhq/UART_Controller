/* ---------------------------------------------------------------
 * Copyright (c) 2022. Heqing Huang (feipenghhq@gmail.com)
 *
 * Author: Heqing Huang
 * Date Created: 09/24/2023
 * ---------------------------------------------------------------
 * apb_uart_reg: APB uart register definition
 * ---------------------------------------------------------------
*/

`ifndef APB_UART_REG_H_
`define APB_UART_REG_H_

typedef struct packed {
    logic           full;
    logic [30:8]    rsvd;
    logic [7:0]     data;
} txdata_t;

typedef struct packed {
    logic           empty;
    logic [30:8]    rsvd;
    logic [7:0]     data;
} rxdata_t;

typedef struct packed {
    logic [31:19]   rsvd1;
    logic [18:16]   txcnt;
    logic [15:2]    rsvd0;
    logic [1:1]     nstop;
    logic [0:0]     txen;
} txctrl_t;

typedef struct packed {
    logic [31:19]   rsvd1;
    logic [18:16]   rxcnt;
    logic [15:1]    rsvd0;
    logic [0:0]     rxen;
} rxctrl_t;

typedef struct packed {
    logic [31:2]    rsvd;
    logic [1:1]     rxwm;
    logic [0:0]     txwm;
} ie_t;

typedef struct packed {
    logic [31:2]    rsvd;
    logic [1:1]     rxwm;
    logic [0:0]     txwm;
} ip_t;

typedef struct packed {
    logic [31:16]   rsvd;
    logic [15:0]    div;
} div_t;

`endif