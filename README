# 🚀 RISC-V Pipeline + UVM Verification (QuestaSim)

## 📌 Overview
This project implements a **5-stage RISC-V processor** in SystemVerilog and verifies it using a **UVM-based testbench** in QuestaSim.

It demonstrates:
- RTL design (pipeline CPU)
- UVM verification (driver, monitor, scoreboard)
- Simulation + waveform debugging
- Real-world debugging scenarios

---

# 🏗️ Project Structure


risc_Q_UVM/
├── alu.sv
├── control_unit.sv
├── data_mem.sv
├── ex_stage.sv
├── forwarding_unit.sv
├── hazard_unit.sv
├── id_stage.sv
├── if_stage.sv
├── imm_gen.sv
├── instr_mem.sv
├── load_store_unit.sv
├── mem_stage.sv
├── pc_reg.sv
├── program_counter.sv
├── reg_file.sv
├── riscv_pkg.sv
├── wb_stage.sv
├── risc_Q_UVM.sv
│
├── riscv_if.sv
├── riscv_item.sv
├── riscv_basic_seq.sv
├── riscv_driver.sv
├── riscv_monitor.sv
├── riscv_agent.sv
├── riscv_env.sv
├── riscv_scoreboard.sv
├── riscv_test.sv
├── riscv_uvm_pkg.sv
│
├── top_tb.sv
├── run.do
└── simulation/
└── uvm_sim/


---

# ⚙️ How to Run (Windows + Questa)

## Step 1: Open CMD

cd /d "D:\mtech\sem 4\risc_Q_UVM\simulation\uvm_sim"


## Step 2: Run simulation

vsim -do run.do


❗ Note:
- `do run.do` works only inside Questa
- Always use `vsim -do run.do` in CMD

---

# 🧪 run.do Flow

CLEAN

vlib work
vmap work work

RTL

vlog -sv ../../*.sv

INTERFACE

vlog -sv ../../riscv_if.sv

UVM PACKAGE

vlog -sv ../../riscv_uvm_pkg.sv

TOP

vlog -sv ../../top_tb.sv

RUN

vsim -voptargs=+acc work.top_tb
run -all


---

# 🧠 RTL Architecture

5-stage pipeline:


IF → ID → EX → MEM → WB


Modules:
- IF: Instruction fetch
- ID: Decode + Register File
- EX: ALU operations
- MEM: Load/Store
- WB: Writeback
- Hazard + Forwarding Units

---

# 🧪 UVM Architecture


TEST
└── ENV
└── AGENT
├── DRIVER
├── MONITOR
└── SEQUENCER

SCOREBOARD


---

# 🔁 Data Flow


Sequence → Driver → DUT → Monitor → Scoreboard


---

# 🔥 Debug Journey (Key Issues & Fixes)

## 1. CMD vs Questa
Problem:

do run.do not working

Fix:

vsim -do run.do


---

## 2. Quartus Script Conflict
Problem:
Wrong .do file used  
Fix:
Use custom `run.do`

---

## 3. UVM Not Found
Fix:

import uvm_pkg::*;


---

## 4. Package vs Include Issue
Problem:
Duplicate / missing classes  
Fix:

Use package only


---

## 5. UVM Crash (SIGSEGV)
Problem:

vif = NULL

Fix:

uvm_config_db::get(...)


---

## 6. Infinite Simulation
Fix:

phase.drop_objection();
$finish;


---

## 7. work/_lock Error
Fix:

taskkill /F /IM vsim.exe
delete work/


---

## 8. RTL Error (Multiple Drivers)
Problem:

initial + always_ff

Fix:

Use only always_ff


---

## 9. Driver Issue
Problem:

uvm_hdl_deposit failed

Fix:
Use interface-driven stimulus

---

## 10. Scoreboard Fail
Problem:
Weak reference model  
Fix:
Decode instructions properly

---

# 📊 Waveform Debug

Check:
- PC increments
- Instruction changes
- ALU output valid
- Register writes happening

---

# ⚠️ Key Learnings

1. always_ff → single driver rule  
2. Never mix package + include  
3. Always use config_db for interface  
4. Avoid uvm_hdl_deposit  
5. Waveform is truth  
6. Simulation ≠ correctness  

---

# 🧑‍🏫 Teaching Flow

1. Build RTL  
2. Add interface  
3. Build UVM components  
4. Create package  
5. Write run.do  
6. Connect interface  
7. Debug using waves  
8. Add scoreboard  

---

# 🎯 Current Status

- RTL working  
- UVM working  
- Simulation running  
- Waveform visible  
- Scoreboard needs improvement  

---

# 🚀 Future Work

- Instruction-aware scoreboard  
- Pipeline verification  
- Hazard validation  
- Functional coverage  
- AXI / PCIe / CXL integration  

---

# 🏁 Conclusion

This project demonstrates:

- RTL Design  
- UVM Verification  
- Debugging skills  
- Simulation mastery  
