# Short glossary

[Home](../README.md) · [Documentation map](README.md)

| Term | Meaning here |
| --- | --- |
| RTL | Register-transfer-level description of the hardware |
| FSM | Finite-state machine; the AES round controller is one |
| AES-128 | AES with a 128-bit key and 128-bit blocks |
| S-box | A fixed nonlinear byte-substitution table |
| Iterative / reusable | The same hardware performs successive parts/rounds |
| Latency | Time/cycles before one result becomes available |
| Throughput | Sustained rate of completed results |
| MMIO | Memory-mapped I/O: addresses select device registers |
| CTR | Counter mode: AES-generated keystream XORed with data |
| Nonce | Per-message/session value used with a counter; uniqueness matters |
| RV32I-style | 32-bit RISC-V-inspired integer pipeline; not a compliance claim |
| IF/ID/EX/MEM/WB | Fetch, decode, execute, memory, writeback |
| Forwarding | Send a result to a dependent instruction before normal writeback |
| Stall / flush | Hold pipeline progress / discard wrong-path work |
| Sticky flag | Status that stays asserted until acknowledged |
| IRQ / ISR | Interrupt request / interrupt service routine; this project exposes IRQ but not a complete CPU ISR path |
| W1C | Write-one-to-clear a status bit |
| DMA-lite | This project's simple RAM word-copy engine |
| UVM | SystemVerilog verification methodology used for the AES/UART test |
| DPI | Interface between SystemVerilog and the independent C model |
| Scoreboard | Compares expected and observed results |
| Coverage bin | A defined category the test attempts to exercise |
| ALM | Intel/Altera FPGA adaptive logic module |
| SDC | Timing-constraint file |
| Slack | Required time minus arrival time for a timing check |
| Vectorless power | Tool estimate without measured transaction switching traces |

For architecture standards, see [NIST AES](https://csrc.nist.gov/pubs/fips/197/final), [NIST block-cipher modes](https://csrc.nist.gov/pubs/sp/800/38/a/final), and the [official RISC-V ISA manuals](https://docs.riscv.org/reference/isa/).
