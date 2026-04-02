# risc-base

SystemVerilog RISC-V RTL + verification starter kit.

## What this repository includes

- `rtl/riscv_core.sv`: a small RV32I-style core in SystemVerilog (currently supports `ADDI`, `ADD`, and `ECALL` trap).
- `tb/riscv_if.sv`: interface exposing architectural-observable signals.
- `tb/riscv_scoreboard.sv`: lightweight ISA checks (including x0 hard-wired-zero validation).
- `tb/tb_top.sv`: runnable testbench top with clock/reset, DUT instantiation, scoreboard, and timeout guard.
- `tests/isa/smoke.hex`: basic smoke program.
- `Makefile`: `lint` and `run` targets (Icarus Verilog).

## Quick start

```bash
make lint
make run
```

## Current core behavior

The included RTL is intentionally small and educational:
- instruction memory is loaded via `$readmemh`
- register file has 32 x 32-bit registers
- x0 is forced to zero
- unsupported instructions raise `trap_o`

This gives you a concrete SV RTL baseline you can extend toward fuller RV32I/RV64I compliance.
