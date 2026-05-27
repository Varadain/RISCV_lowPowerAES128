Below is a **viva/presentation script for all important files** in your custom ISA project.

Project path:

```text
D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA
```

# Complete File Explanation Script

## 1. `riscv_aes_advancements.sv`

This is the **top-level module** of the complete processor system. It connects the 5-stage RISC-V pipeline with AES, UART, sensor/SPI, interrupt controller, DMA-lite, and power-management blocks.

In this file, the main processor stages are instantiated and connected:

```text
IF -> ID -> EX -> MEM -> WB
```

It also exposes debug outputs such as:

```text
current_pc_debug
aes_done_debug
aes_ciphertext_debug
uart_tx
irq_debug
sleep_debug
activity_counter_debug
```

These outputs are useful for FPGA observation and prevent Quartus from optimizing away important internal logic.

---

## 2. `pc_reg.sv`

This file implements the **program counter register**.

The program counter stores the address of the current instruction. On every clock cycle, it updates to the next PC value unless reset or stalled.

It is important because instruction execution starts from the PC.

Simple role:

```text
PC register decides which instruction is fetched next.
```

---

## 3. `if_stage.sv`

This is the **Instruction Fetch stage**.

It uses the PC to fetch an instruction from instruction memory. It also handles branch/jump target selection and passes the fetched instruction to the next pipeline stage.

The IF stage contains/uses:

```text
PC value
instruction memory
next PC logic
stall/flush support
```

---

## 4. `instr_mem.sv`

This is the **instruction memory**.

In simulation, the testbench directly loads instructions into the internal ROM array. That is why the Questa script uses:

```text
+define+SIMULATION
```

This preserves the testbench-visible ROM hierarchy:

```text
dut.u_if_stage.u_instr_mem.rom
```

In simple words:

```text
This file stores the program instructions executed by the RISC-V CPU.
```

---

## 5. `id_stage.sv`

This is the **Instruction Decode stage**.

It decodes the instruction fields:

```text
opcode
rd
rs1
rs2
funct3
funct7
immediate
```

It also reads source operands from the register file and generates control signals.

For the custom ISA, this stage recognizes the RISC-V `custom-0` opcode and marks custom security instructions.

---

## 6. `reg_file.sv`

This is the **RISC-V register file**.

It contains 32 general-purpose registers:

```text
x0 to x31
```

Register `x0` is always zero, as required by RISC-V.

The register file provides:

```text
two read ports
one write port
```

It is used by the decode stage and writeback stage.

---

## 7. `imm_gen.sv`

This file generates immediate values from instruction bits.

Different instruction types store immediate fields differently:

```text
I-type
S-type
B-type
U-type
J-type
```

This module extracts and sign-extends those immediate values.

---

## 8. `control_unit.sv`

This is the **main instruction control decoder**.

It decides what each instruction should do.

It generates control signals such as:

```text
reg_write
mem_read
mem_write
alu_src
branch
jump
result_src
alu_op
custom instruction control
```

For this project, it was extended to support custom security instructions using:

```text
opcode = 7'b0001011
```

---

## 9. `hazard_unit.sv`

This file handles **pipeline hazards**.

A pipeline hazard happens when one instruction depends on the result of a previous instruction that has not completed yet.

The hazard unit can generate:

```text
stall
flush
```

This keeps pipeline execution correct.

Example:

```text
lw x1, 0(x2)
addi x3, x1, 1
```

The second instruction needs `x1`, but load data may not be ready immediately.

---

## 10. `forwarding_unit.sv`

This module reduces pipeline stalls by forwarding results from later stages back to the execute stage.

Instead of waiting for writeback, the processor can reuse results from:

```text
EX/MEM stage
MEM/WB stage
```

This improves pipeline performance.

---

## 11. `ex_stage.sv`

This is the **Execute stage**.

It performs ALU operations and branch comparisons.

It contains the ALU and selects operands using forwarding logic.

For custom ISA, this stage also passes custom instruction operands forward so the MEM stage can execute custom AES/security operations.

---

## 12. `alu.sv`

This is the **Arithmetic Logic Unit**.

It performs operations such as:

```text
ADD
SUB
SLL
SLT
SLTU
XOR
SRL
SRA
OR
AND
```

It is used for R-type, I-type, branch comparison, and address calculation.

---

## 13. `mem_stage.sv`

This is one of the most important files.

Originally, the MEM stage mainly handled data memory and AES MMIO. Now it acts as the **MMIO peripheral decoder** for the complete IoT security processor.

It decodes addresses:

```text
0x0000_0300 -> AES / AES-CTR
0x0000_0400 -> Sensor / SPI
0x0000_0500 -> UART
0x0000_0600 -> Interrupt controller
0x0000_0700 -> DMA-lite
0x0000_0800 -> Power/activity control
```

It decides whether a load/store instruction should access normal RAM or a peripheral.

This file is the bridge between the RISC-V CPU and all hardware peripherals.

---

## 14. `load_store_unit.sv`

This file handles different load and store sizes.

It supports:

```text
LB
LH
LW
LBU
LHU
SB
SH
SW
```

It performs sign extension, zero extension, byte selection, and half-word/word formatting.

---

## 15. `data_mem.sv`

This is the normal **data memory RAM**.

The CPU uses it for load and store instructions when the address is not mapped to a peripheral.

In testbench, this RAM is also checked directly for load/store verification.

---

## 16. `aes128_lowpower.sv`

This is the core AES-128 encryption engine.

It implements iterative, hardware-reusable AES encryption.

Instead of using many parallel AES round units, it reuses AES transformation hardware across rounds.

It includes AES submodules:

```text
sub_bytes
shift_rows
mix_columns
mix_col
key_expand
aes_sbox
```

This is the main low-power AES architecture from the research paper.

---

## 17. `aes_mmio.sv`

This file wraps the AES core as a memory-mapped peripheral.

The CPU can write:

```text
AES key
plaintext
nonce
counter
control register
```

The CPU can read:

```text
AES status
ciphertext
```

It supports both:

```text
ECB mode
CTR mode
```

AES-CTR works as:

```text
keystream = AES_encrypt(nonce || counter)
ciphertext = plaintext XOR keystream
```

This wrapper preserves the original AES ECB behavior and adds IoT-friendly CTR encryption.

---

## 18. `uart_tx.sv`

This file implements the serial UART transmitter.

It sends one byte using `8-N-1` format:

```text
1 start bit
8 data bits
1 stop bit
```

It uses:

```text
baud_div
baud_count
bit_count
busy
done
```

The output pin is:

```text
uart_tx
```

This is the final encrypted data output path.

---

## 19. `uart_mmio.sv`

This file wraps the UART transmitter as an MMIO peripheral.

UART base address:

```text
0x0000_0500
```

Registers:

```text
UART_TXDATA
UART_STATUS
UART_CONTROL
UART_BAUD_DIV
```

The CPU writes ciphertext bytes to `UART_TXDATA`, and UART transmits them serially.

---

## 20. `sensor_mmio.sv`

This is the simple sensor interface.

It models sensor data as memory-mapped registers.

Registers:

```text
SENSOR_DATA
SENSOR_STATUS
SENSOR_CONTROL
```

For now, this is useful for simulation and verification. Later it can be replaced by a real SPI/I2C sensor interface.

---

## 21. `sensor_spi_mmio.sv`

This file connects the sensor address space to an SPI-style interface.

It provides MMIO access to SPI registers such as:

```text
SPI_RXDATA
SPI_TXDATA
SPI_STATUS
SPI_CONTROL
SPI_SLAVE_SELECT
```

This allows the processor to communicate with external sensors through SPI.

---

## 22. `ip/sensor_spi_ip/sensor_spi_ip.v`

This is the SPI IP wrapper/source used for sensor SPI communication.

It represents the optional Intel/Quartus SPI IP integration.

For portability, the custom `sensor_mmio.sv` can still be used as a simple behavioral sensor model.

---

## 23. `simple_intc.sv`

This is the simple interrupt controller.

It collects interrupt/event signals from:

```text
AES done
UART TX done
sensor data ready
DMA done
```

It provides MMIO registers:

```text
IRQ_PENDING
IRQ_ENABLE
IRQ_CLEAR
```

The output is:

```text
irq_debug
```

Since the CPU does not yet have full CSR/trap interrupt support, this interrupt is exposed and verified as a debug/event signal.

---

## 24. `dma_lite.sv`

This is the DMA-lite engine.

It is used to move words between memory/peripheral-like locations with less CPU involvement.

Registers:

```text
DMA_SRC_ADDR
DMA_DST_ADDR
DMA_LEN
DMA_CTRL
DMA_STATUS
```

It supports simple word transfers.

Purpose:

```text
Reduce CPU work for data movement.
```

---

## 25. `power_mgmt_mmio.sv`

This file implements sleep control and activity counters.

It tracks:

```text
CPU active cycles
AES active cycles
UART active cycles
DMA active cycles
sensor active cycles
sleep cycles
```

This is important for low-power IoT research because it helps measure activity at system level.

---

## 26. `wb_stage.sv`

This is the **Writeback stage**.

It selects what value should be written back into the register file.

Possible writeback sources include:

```text
ALU result
memory read data
PC + 4
custom instruction result
```

This completes the instruction execution pipeline.

---

## 27. `riscv_pkg.sv`

This package file stores shared definitions, constants, or typedefs used by the design.

It helps keep common parameters organized.

---

## 28. `program_counter.sv`

This appears to be an alternate or supporting program-counter related module.

The active design mainly uses `pc_reg.sv`, but this file may be kept as a supporting/legacy PC implementation.

---

# Testbench and Verification Files

## 29. `riscv_core_tb.sv`

This is the main testbench.

It verifies:

```text
R-type instructions
I-type instructions
load/store instructions
branch instructions
U/J instructions
system/fence/pseudo instructions
AES ECB
AES CTR
sensor MMIO
SPI IP
UART
interrupt controller
DMA-lite
power counters
custom security ISA
signal activity
```

It prints final result:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

It also contains helper tasks like:

```text
apply_reset()
run_cycles()
check_and_report()
```

---

# Custom ISA and Demo Files

## 30. `custom_isa_extension.md`

This document explains the custom security instruction extension.

It describes:

```text
custom-0 opcode
instruction format
funct3 commands
pipeline integration
thesis use
```

Custom instructions include:

```text
CSEC_XOR
CSEC_AES_STATUS
CSEC_AES_START
CSEC_AES_CT0
CSEC_AES_CLEAR
```

---

## 31. `custom_isa_demo.S`

This is an assembly/demo program showing how the custom security instructions can be used.

Since normal assemblers may not understand custom mnemonics, custom instructions can be represented using raw `.word` encodings.

---

## 32. `iot_security_demo.S`

This is the software/demo program idea for the IoT security processor.

It shows the intended flow:

```text
read sensor
configure AES
encrypt sensor data
send ciphertext through UART
sleep when done
```

---

# Documentation Files

## 33. `README.md`

This is the main project overview document.

It explains:

```text
project purpose
architecture
features
file structure
compile flow
simulation flow
verification
Git upload recommendation
```

---

## 34. `memory_map.md`

This file documents the MMIO address map.

Important ranges:

```text
0x300 AES
0x400 Sensor/SPI
0x500 UART
0x600 Interrupt controller
0x700 DMA-lite
0x800 Power/activity
```

This is useful for both hardware and software understanding.

---

## 35. `iot_security_processor_architecture.md`

This file explains the complete architecture of the Lightweight IoT Security Processor.

It is useful for thesis/report explanation.

---

## 36. `verification_plan.md`

This file explains what is verified and how.

It lists the verification targets:

```text
CPU instructions
AES modes
peripherals
interrupts
DMA
power counters
custom ISA
```

---

## 37. `thesis_contribution.md`

This file explains the research contribution.

Main contribution:

```text
low-power AES integrated into a RISC-V IoT security processor
AES-CTR sensor encryption
custom security ISA
activity measurement
```

---

## 38. `sensor_to_encrypted_output_flow.md`

This document explains the full application flow:

```text
sensor data
MMIO read
AES-CTR encryption
UART ciphertext output
receiver decryption
```

This is useful for presentation and poster explanation.

---

# Scripts and Tool Files

## 39. `compile_light.ps1`

This PowerShell script runs a lighter Quartus compile/check flow.

It is useful when full fitting takes too much time or heats the laptop.

---

## 40. `compile_full_low_power.ps1`

This script runs the fuller Quartus compile flow for the low-power processor project.

It is used for more complete FPGA compilation.

---

## 41. `run_questa_regression.ps1`

This script runs the Questa simulation regression automatically.

It compiles the SystemVerilog files and runs the testbench.

Expected result:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

---

## 42. `simulation/questa/riscv_aes_advancements_run_msim_rtl_verilog.do`

This is the Questa GUI simulation script.

It compiles files with:

```text
+define+SIMULATION
```

This is needed so the testbench can access the instruction ROM hierarchy.

It also keeps waveform visibility using:

```text
-voptargs="+acc"
add wave *
view structure
view signals
run -all
```

---

## 43. `tools/generate_instruction_waveform_pdf.py`

This Python script generates the submission-ready waveform report.

It reads the VCD waveform file and creates:

```text
custom_isa_instruction_waveforms.html
custom_isa_instruction_waveforms.pdf
```

The PDF separates waveform pages by instruction/peripheral type and includes beginner explanations.

---

# Quartus Project Files

## 44. `riscv_aes_advancements.qpf`

This is the Quartus project file.

It identifies the Quartus project.

---

## 45. `riscv_aes_advancements.qsf`

This is the Quartus settings file.

It includes:

```text
top-level entity
device selection
source file list
assignments
```

---

## 46. `riscv_aes_advancements.sdc`

This is the timing constraints file.

It defines the clock timing constraint, for example a 20 ns clock period.

It is important because Quartus Timing Analyzer needs an SDC file for proper timing analysis.

---

## 47. `.gitignore`

This file tells Git which generated files should not be uploaded.

It ignores files/folders such as:

```text
db/
incremental_db/
output_files/
simulation/questa/rtl_work/
*.vcd
*.rpt
*.qws
```

This keeps the Git repository clean.

---

# Final Speaking Summary

You can end your explanation like this:

```text
This project extends a 5-stage RV32I-style processor into a Lightweight IoT
Security Processor. The CPU communicates with AES, sensor/SPI, UART, interrupt,
DMA, and power-management blocks through MMIO. The AES core is preserved as a
low-power iterative hardware block, while the AES MMIO wrapper adds CTR mode for
secure sensor-stream encryption. UART provides encrypted data output, DMA reduces
CPU data-movement overhead, interrupts reduce polling, and activity counters
support low-power analysis. In the custom ISA version, selected AES operations
are also controlled using RISC-V custom-0 instructions, allowing comparison
between traditional MMIO accelerator control and custom instruction based
security acceleration.
```
