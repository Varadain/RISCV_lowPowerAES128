# risc-base

SystemVerilog RTL implementation of a **5-stage pipelined RISC-V (RV32I subset) core**.

## Pipeline stages
- IF: `if_stage.sv`
- ID: `id_stage.sv`
- EX: `ex_stage.sv`
- MEM: `mem_stage.sv`
- WB: `wb_stage.sv`

## Included RTL modules (15 total)
1. `riscv_core_top.sv`
2. `pc_reg.sv`
3. `if_stage.sv`
4. `instr_mem.sv`
5. `id_stage.sv`
6. `reg_file.sv`
7. `imm_gen.sv`
8. `control_unit.sv`
9. `ex_stage.sv`
10. `alu.sv`
11. `mem_stage.sv`
12. `data_mem.sv`
13. `wb_stage.sv`
14. `hazard_unit.sv`
15. `forwarding_unit.sv`

## Features
- 5-stage pipeline with IF/ID, ID/EX, EX/MEM, MEM/WB registers.
- Basic hazard handling:
  - load-use stalling (`hazard_unit`)
  - data forwarding (`forwarding_unit`)
- Branch decision in EX stage with pipeline flush.
- Simple built-in instruction and data memories for simulation.

## Notes
- This is an educational baseline RTL core and not a full privileged-spec implementation.
- Current decode/control supports a compact RV32I subset (`add`, `sub`, `and`, `or`, `addi`, `lw`, `sw`, `beq`).
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
----
https://www.edaplayground.com/x/6qTp
https://www.edaplayground.com/x/CLFm
