# APB Uart



## Introduction

APB Uart based on SiFive-E300-platform.



## Memory Map

| Address | Name   | Description               |
| ------- | ------ | ------------------------- |
| 0x000   | txdata | Transmit data register    |
| 0x004   | rxdata | Receive data register     |
| 0x008   | txctrl | Transmit control register |
| 0x00C   | rxctrl | Receive control register  |
| 0x010   | ie     | interrupt enable          |
| 0x014   | ip     | Interrupt pending         |
| 0x018   | div    | rate divisor              |

Check [SiFive-E300-platform]( <https://static.dev.sifive.com/SiFive-E300-platform-reference-manual-v1.0.1.pdf>) for detail register field definition.
