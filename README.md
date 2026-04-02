# risc-base

SystemVerilog RTL reference for a **5-stage pipelined RISC-V (RV32I-style) core**.

## Pipeline
- IF: fetch with redirect + stall support
- ID: decode, register read, immediate generation
- EX: ALU, branch/jump resolution, forwarding muxes
- MEM: data memory access
- WB: register writeback mux

## Included RTL modules (15 total)
1. `riscv_core_top`
2. `if_stage`
3. `id_stage`
4. `ex_stage`
5. `mem_stage`
6. `wb_stage`
7. `program_counter`
8. `instr_mem`
9. `data_mem`
10. `reg_file`
11. `alu`
12. `control_unit`
13. `imm_gen`
14. `hazard_unit`
15. `forwarding_unit`

Package file: `riscv_pkg.sv` defines shared control types.
