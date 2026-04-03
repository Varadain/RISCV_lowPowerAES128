# risc-base

SystemVerilog RTL implementation and verification of a **5-stage pipelined RISC-V (RV32I subset) core**

---

## Pipeline Stages

- IF  : `if_stage.sv`  
- ID  : `id_stage.sv`  
- EX  : `ex_stage.sv`  
- MEM : `mem_stage.sv`  
- WB  : `wb_stage.sv`  

---

## Key Modules

- `alu.sv` – ALU operations  
- `control_unit.sv` – instruction decode and control signals  
- `imm_gen.sv` – immediate generation (I/S/B/U/J)  
- `reg_file.sv` – register file  
- `hazard_unit.sv` – hazard detection  
- `forwarding_unit.sv` – data forwarding  
- `load_store_unit.sv` – subword load/store handling  

---

## Verification

Directed SystemVerilog testbench with modular tasks:

- `run_rtype_tests`  
- `run_itype_tests`  
- `run_load_store_tests`  
- `run_branch_tests`  
- `run_u_jtype_tests`  
- `run_system_fence_pseudo_tests`  

Each instruction is checked using `check_and_report(...)`.

---

## Instruction Coverage

- ALU: `ADD`, `SUB`, `SLL`, `SLT`, `SLTU`, `XOR`, `SRL`, `SRA`, `OR`, `AND`  
- Immediate: `ADDI`, `SLTI`, `SLTIU`, `XORI`, `ORI`, `ANDI`, `SLLI`, `SRLI`, `SRAI`  
- Load/Store: `LB`, `LH`, `LW`, `LBU`, `LHU`, `SB`, `SH`, `SW`  
- Branch: `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU`  
- Jump: `JAL`, `JALR`  
- Upper: `LUI`, `AUIPC`  
- System: `ECALL`, `EBREAK`  
- Fence: `FENCE`, `FENCE.I`  
- Pseudo: `NOP`, `MV`, `LI`, `J`  

---

## Results

```
Total Checks : 47
Passed       : 47
Failed       : 0
```

---

## Waveform

Waveform used to validate:
- pipeline flow (`IF → ID → EX → MEM → WB`)  
- ALU results  
- register writeback  
- memory access  
- PC updates  

---

## Notes

- fully self-checking testbench  
- no pipeline structure changes during verification  
- waveform files are auto-generated  

---

## Next Steps

- UVM-based verification  
- constrained-random testing  
- AES integration  
