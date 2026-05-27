# MMIO Code Deep Dive

## Purpose

This document explains the memory-mapped I/O code used in the project:

```text
Lightweight RISC-V Based Secure Health-Monitoring IoT Processor
with AES-CTR Encryption and Custom Security ISA
```

MMIO means **Memory-Mapped Input/Output**. In this design, the RISC-V CPU
controls hardware peripherals using normal load and store instructions.

Instead of having special instructions for every peripheral, the CPU accesses
fixed addresses:

```text
lw -> read a peripheral register
sw -> write a peripheral register
```

Example:

```text
sw x5, 0(x1)
```

If `x1 = 0x0000_0500`, then this store writes to the UART transmit-data
register instead of normal RAM.

---

# 1. Why MMIO Is Used

MMIO allows the same RISC-V load/store path to control:

```text
AES accelerator
Sensor / SPI interface
UART transmitter
Interrupt controller
DMA-lite engine
Power/activity counters
```

The CPU does not need a separate bus protocol or special instruction for every
hardware block. The MEM stage checks the address and sends the access to the
correct peripheral.

Speaker note:

> MMIO is the bridge between the CPU and hardware peripherals. The CPU sees
> peripheral registers as memory addresses. When the CPU executes a load or
> store to a peripheral address, the MEM stage routes that access to the
> corresponding hardware block.

---

# 2. Global MMIO Address Map

The main MMIO address decoding is implemented in:

```text
mem_stage.sv
```

Address map:

| Base Address | Peripheral |
| --- | --- |
| `0x0000_0300` | AES / AES-CTR |
| `0x0000_0400` | Sensor MMIO + SPI |
| `0x0000_0500` | UART MMIO |
| `0x0000_0600` | Interrupt controller |
| `0x0000_0700` | DMA-lite |
| `0x0000_0800` | Power/activity control |

The decoder uses the upper address bits:

```systemverilog
assign aes_sel    = (eff_addr[31:8] == 24'h000003);
assign sensor_sel = (eff_addr[31:8] == 24'h000004);
assign uart_sel   = (eff_addr[31:8] == 24'h000005);
assign intc_sel   = (eff_addr[31:8] == 24'h000006);
assign dma_sel    = (eff_addr[31:8] == 24'h000007);
assign power_sel  = (eff_addr[31:8] == 24'h000008);
```

This means each peripheral gets a 256-byte address window.

Example:

```text
0x0000_0300 to 0x0000_03FF -> AES
0x0000_0400 to 0x0000_04FF -> Sensor/SPI
0x0000_0500 to 0x0000_05FF -> UART
```

---
