# UART controller

- [UART controller](#uart-controller)
  - [Introduction](#introduction)
    - [Features](#features)
  - [UART Core](#uart-core)
  - [AXI-lite Uart](#axi-lite-uart)
  - [Reference](#reference)


## Introduction

This repo implements an UART module designed in systemverilog.

It contains the RTL source code, a testbench to verify its function, and a software driver.

It also contains a demo program to run in Arty A7 FPGA board.

### Features

The UART controller supports the following features (same as SiFive-E300-platform):

- 8-N-1 and 8-N-2 formats: 8 data bits, no parity bit, 1 start bit, 1 or 2 stop bits.
- 8-entry transmit and receive FIFO buffers with programmable watermark interrupts
- 16× Rx oversampling with 2/3 majority voting per bit

## UART Core

The UART core is the main block to performance the UART transaction protocol. It contains 4 RTL files:

**uart_baud.sv** - Generate sample tick for a given baud rate.

**uart_tx.sv** - uart transmit module.

**uart_rx.sv** - uart receive module.

**uart_core.sv** - instantiate all the 3 above modules.

Check [uart_core.md](doc/uart_core.md) for detailed implementation.

## AXI-lite Uart

AXI-lite Uart design provide a AXI-lite Memory Mapped Interface to interact with the Uart core. The memory map is based on SiFive-E300-platform.


| Address | Name   | Description               |
| ------- | ------ | ------------------------- |
| 0x000   | txdata | Transmit data register    |
| 0x004   | rxdata | Receive data register     |
| 0x008   | txctrl | Transmit control register |
| 0x00C   | rxctrl | Receive control register  |
| 0x010   | ie     | interrupt enable          |
| 0x014   | ip     | Interrupt pending         |
| 0x018   | div    | rate divisor              |

Check [axilite_uart.md](doc/axilite_uart.md) for detailed implementation.

## Reference

1. SiFive-E300-platform: <https://static.dev.sifive.com/SiFive-E300-platform-reference-manual-v1.0.1.pdf>
