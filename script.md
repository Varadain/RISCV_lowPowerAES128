# File Sequence Speaker Notes

## Topic

```text
Lightweight RISC-V Based Secure Health-Monitoring IoT Processor
with AES-CTR Encryption and Custom Security ISA
```

---

# 1. Top-Level Architecture File

## `riscv_aes_advancements.sv`

This is the top-level file of the complete project. I should explain this file
first because it shows how the entire processor system is connected.

Originally, the project was centered around a RISC-V processor and AES
accelerator. In the extended version, it is converted into a lightweight IoT
security processor by integrating multiple peripherals around the CPU.

The main blocks connected here are:

```text
5-stage RISC-V processor
AES-128 accelerator
AES-CTR wrapper
Sensor / SPI interface
UART transmitter
Interrupt controller
DMA-lite engine
Power and activity counter block
Debug outputs
```

The RISC-V pipeline remains:

```text
IF -> ID -> EX -> MEM -> WB
```

The top-level module connects these stages and exposes useful signals for FPGA
observation and simulation waveform debugging.

Important debug/output signals include:

```text
current_pc_debug
aes_done_debug
aes_ciphertext_debug
uart_tx
irq_debug
sleep_debug
activity_counter_debug
```

Speaker note:

> This file is the system integration point. It connects the RISC-V CPU with
> AES, UART, sensor/SPI, DMA, interrupt controller, and power-management blocks.
> It also exposes debug signals so that important internal activity can be
> observed during simulation and FPGA compilation.

---

# 2. RISC-V Processor Core Files

These files form the basic 5-stage RISC-V processor. They are the foundation of
the project.

## `pc_reg.sv`

This file implements the program counter register.

The program counter stores the address of the current instruction. On every
clock cycle, it updates to the next PC value unless reset or stalled.

The PC decides which instruction is fetched next.

Speaker note:

> The processor starts execution from the program counter. The PC register
> keeps track of the current instruction address and updates every cycle based
> on normal sequential execution, branch, jump, stall, or reset.

## `if_stage.sv`

This file implements the instruction fetch stage.

The IF stage uses the PC to fetch an instruction from instruction memory. It
also handles next-PC selection and supports pipeline control such as stalls and
flushes.

Main responsibilities:

```text
Read PC
Fetch instruction
Calculate or select next PC
Handle stall/flush
Pass instruction to decode stage
```

Speaker note:

> The IF stage is responsible for bringing instructions into the pipeline. It
> uses the PC value to access instruction memory and sends the fetched
> instruction to the decode stage.

## `instr_mem.sv`

This is the instruction memory.

In simulation, the testbench directly loads instruction words into the internal
ROM array. For this reason, the Questa simulation script uses:

```text
+define+SIMULATION
```

This keeps the ROM visible to the testbench as:

```text
dut.u_if_stage.u_instr_mem.rom
```

Speaker note:

> Instruction memory stores the program executed by the RISC-V processor. In
> simulation, the testbench writes instructions directly into this memory, so
> the simulation define is required to preserve the visible ROM hierarchy.

## `id_stage.sv`

This is the instruction decode stage.

It extracts instruction fields:

```text
opcode
rd
rs1
rs2
funct3
funct7
immediate
```

It also reads operands from the register file and receives control signals from
the control unit.

For the custom ISA extension, this file helps recognize custom security
instructions using the RISC-V custom opcode.

Speaker note:

> The decode stage understands what instruction has been fetched. It reads the
> required source registers, generates immediate values, and identifies whether
> the instruction is a normal RISC-V instruction or a custom security
> instruction.

## `reg_file.sv`

This is the RISC-V register file.

It contains 32 registers:

```text
x0 to x31
```

Register `x0` is always zero.

The register file has:

```text
two read ports
one write port
```

Speaker note:

> The register file stores the processor's working data. Most instructions read
> from `rs1` and `rs2` and write the final result into `rd`. Register `x0` is
> hardwired to zero according to the RISC-V standard.

## `imm_gen.sv`

This file generates immediate values from instruction fields.

Different instruction formats store immediate bits differently:

```text
I-type
S-type
B-type
U-type
J-type
```

The immediate generator extracts, arranges, and sign-extends these values.

Speaker note:

> Immediate generation is necessary because RISC-V instructions store immediate
> values in different bit positions depending on instruction type. This module
> converts those encoded bits into a usable 32-bit immediate.

## `control_unit.sv`

This is the main control decoder.

It generates signals such as:

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

For this project, it was updated to detect the custom security opcode:

```text
opcode = 7'b0001011
```

Speaker note:

> The control unit decides how every instruction should move through the
> datapath. For normal RISC-V instructions, it generates standard ALU, memory,
> branch, and writeback control. For the custom ISA extension, it identifies the
> custom opcode and enables the security instruction path.

## `hazard_unit.sv`

This file handles pipeline hazards.

A hazard occurs when one instruction depends on another instruction that has not
finished yet.

Example:

```text
lw x1, 0(x2)
addi x3, x1, 1
```

The second instruction needs `x1`, but the load value may not be available
immediately.

The hazard unit can generate:

```text
stall
flush
```

Speaker note:

> The hazard unit protects correctness in the pipeline. If data is not ready or
> a branch changes the instruction flow, this unit stalls or flushes pipeline
> stages so that wrong results are not produced.

## `forwarding_unit.sv`

This file improves pipeline performance by forwarding data from later pipeline
stages back to the execute stage.

Instead of waiting for writeback, the processor can use results from:

```text
EX/MEM stage
MEM/WB stage
```

Speaker note:

> Forwarding reduces unnecessary stalls. If a result has already been computed
> but not yet written back to the register file, the forwarding unit sends that
> value directly to the execute stage.

## `ex_stage.sv`

This is the execute stage.

It performs:

```text
ALU operations
branch comparison
address calculation
operand selection
forwarded operand handling
custom ISA operand passing
```

For custom security instructions, this stage passes operands forward so that
the MEM stage can perform custom AES-related operations.

Speaker note:

> The execute stage is where computation happens. ALU results, branch decisions,
> and memory addresses are generated here. In the custom ISA version, the
> execute stage also prepares operands for custom AES/security commands.

## `alu.sv`

This is the arithmetic logic unit.

It supports operations such as:

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

Speaker note:

> The ALU performs arithmetic and logical operations for R-type and I-type
> instructions. It is also used for address calculation in load and store
> instructions and for branch comparisons.

## `load_store_unit.sv`

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

It performs byte selection, half-word selection, word alignment, sign
extension, and zero extension.

Speaker note:

> The load-store unit makes memory access compatible with byte, half-word, and
> word operations. It formats read and write data correctly before data reaches
> the register file or memory.

## `data_mem.sv`

This is the normal data memory.

The CPU accesses this RAM when a load/store address is not inside the MMIO
peripheral address region.

Speaker note:

> Data memory stores normal program data. If a load/store address is not mapped
> to AES, UART, sensor, DMA, interrupt, or power registers, then the access goes
> to this RAM.

## `wb_stage.sv`

This is the writeback stage.

It selects the final value to write into the register file.

Possible sources include:

```text
ALU result
memory read data
PC + 4
custom instruction result
```

Speaker note:

> Writeback is the final stage of instruction execution. It writes the selected
> result into the destination register. For the custom ISA extension, custom AES
> results can also be written back through this stage.

---

# 3. Most Important Integration File

## `mem_stage.sv`

This is the most important file for peripheral integration.

In a basic RISC-V processor, the MEM stage handles normal data memory access.
In this project, the MEM stage was expanded into an MMIO decoder for the full
IoT security SoC.

It decodes these address ranges:

```text
0x0000_0300 -> AES / AES-CTR
0x0000_0400 -> Sensor / SPI
0x0000_0500 -> UART
0x0000_0600 -> Interrupt controller
0x0000_0700 -> DMA-lite
0x0000_0800 -> Power/activity counters
```

Before integration:

```text
CPU load/store -> data memory
CPU load/store -> AES
```

After integration:

```text
CPU load/store -> data memory or selected peripheral
```

This means normal RISC-V `lw` and `sw` instructions can control hardware
peripherals.

Examples:

```text
sw x5, AES_CTRL(x1)       -> start AES
lw x6, AES_STATUS(x1)     -> read AES status
lw x7, SENSOR_DATA(x1)    -> read sensor value
sw x8, UART_TXDATA(x1)    -> transmit encrypted byte
sw x9, DMA_CTRL(x1)       -> start DMA
lw x10, IRQ_PENDING(x1)   -> read interrupt events
lw x11, CPU_ACTIVE(x1)    -> read activity counter
```

Speaker note:

> The MEM stage is the bridge between the processor and the hardware
> peripherals. It checks the address generated by the execute stage and decides
> whether the access should go to RAM or to AES, sensor/SPI, UART, interrupt,
> DMA, or power-management registers. This allows the project to add many
> peripherals without rewriting the entire RISC-V pipeline.

---

# 4. AES And Security Files

## `aes128_lowpower.sv`

This is the low-power AES-128 encryption core.

It implements an iterative, hardware-reusable AES architecture. Instead of
instantiating many AES round blocks in parallel, it reuses the same datapath
across multiple rounds.

Internal AES operations include:

```text
SubBytes
ShiftRows
MixColumns
Key Expansion
AddRoundKey
```

Related submodules inside the file:

```text
sub_bytes
shift_rows
mix_columns
mix_col
key_expand
aes_sbox
```

Speaker note:

> This file contains the main cryptographic hardware. The key idea is hardware
> reuse. A single AES datapath is reused across rounds, reducing area and
> switching activity compared with fully parallel AES architectures. This is the
> core low-power contribution inherited from the AES research work.

## `aes_mmio.sv`

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

This wrapper supports:

```text
ECB mode
CTR mode
```

AES-CTR operation:

```text
keystream  = AES_encrypt(nonce || counter)
ciphertext = plaintext XOR keystream
```

Speaker note:

> The AES MMIO wrapper makes the AES core usable by the RISC-V processor. It
> preserves the original ECB functionality and adds CTR mode, which is more
> suitable for continuous sensor-data encryption in IoT applications.

---

# 5. Communication And Sensor Files

## `sensor_mmio.sv`

This is a simple memory-mapped sensor model.

It provides:

```text
SENSOR_DATA
SENSOR_STATUS
SENSOR_CONTROL
```

It is useful for simulation because the CPU can read sensor data without
needing a real external sensor.

Speaker note:

> This file models sensor data as MMIO registers. It is a simple starting point
> for health data such as heart rate, SpO2, or temperature. Later, this simple
> sensor model can be replaced by a real SPI or I2C sensor interface.

## `sensor_spi_mmio.sv`

This file provides a more practical SPI-based sensor interface.

It exposes SPI-related registers:

```text
SPI_RXDATA
SPI_TXDATA
SPI_STATUS
SPI_CONTROL
SPI_SLAVE_SELECT
```

Speaker note:

> The SPI MMIO wrapper connects the RISC-V processor to an SPI-style sensor
> interface. The CPU can configure SPI, write transmit data, read received data,
> and control slave select using normal load/store instructions.

## `ip/sensor_spi_ip/sensor_spi_ip.v`

This is the optional Intel/Quartus SPI IP source or wrapper.

It represents use of a practical FPGA IP block for sensor communication.

Speaker note:

> This file represents the optional SPI IP used for practical sensor
> interfacing. For simulation portability, the simple `sensor_mmio.sv` model can
> still be used. For FPGA-oriented work, this SPI IP shows how a real sensor
> interface can be connected.

## `uart_tx.sv`

This file implements the UART transmitter.

It sends serial data using 8-N-1 format:

```text
1 start bit
8 data bits
1 stop bit
```

Important internal signals:

```text
baud_div
baud_count
bit_count
busy
done
```

Speaker note:

> The UART transmitter converts each byte into a serial bit stream. This is the
> final output path for encrypted sensor data. After AES encryption, ciphertext
> bytes are sent through the `uart_tx` pin.

## `uart_mmio.sv`

This wraps the UART transmitter as an MMIO peripheral.

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

Speaker note:

> The UART MMIO wrapper allows the CPU to transmit data using normal store
> instructions. The CPU writes ciphertext bytes to `UART_TXDATA`, and the UART
> hardware sends them serially.

---

# 6. Interrupt, DMA, And Power Files

## `simple_intc.sv`

This is the simple interrupt controller.

It collects events from:

```text
AES done
UART done
sensor ready
DMA done
```

MMIO registers:

```text
IRQ_PENDING
IRQ_ENABLE
IRQ_CLEAR
```

Speaker note:

> The interrupt controller prevents the CPU from continuously polling every
> peripheral. When AES, UART, sensor, or DMA finishes an operation, the
> interrupt controller stores that event in the pending register and can assert
> a combined IRQ debug signal.

## `dma_lite.sv`

This is the DMA-lite engine.

It contains registers:

```text
DMA_SRC_ADDR
DMA_DST_ADDR
DMA_LEN
DMA_CTRL
DMA_STATUS
```

Purpose:

```text
Move words with less CPU involvement
```

Speaker note:

> DMA-lite reduces the amount of manual data movement done by the CPU. Instead
> of executing many load and store instructions for copying words, the CPU can
> configure source, destination, and length, then start the DMA.

## `power_mgmt_mmio.sv`

This file implements sleep control and activity counters.

Counters include:

```text
CPU active cycles
AES active cycles
UART active cycles
DMA active cycles
sensor active cycles
sleep cycles
```

Speaker note:

> This file supports the low-power research angle. It measures how long each
> block is active and how long the processor is in sleep mode. These counters
> can be used to compare polling, interrupt-based operation, DMA operation, and
> custom ISA operation.

---

# 7. Custom ISA Related Files And RISC-V Updates

## Why Custom ISA Was Added

MMIO is simple and portable, but it needs multiple load/store instructions to
control AES.

Example MMIO sequence:

```text
store key
store plaintext
store nonce
store counter
store AES control
load AES status
load ciphertext
```

The custom ISA reduces this software control overhead by adding security
instructions using the RISC-V `custom-0` opcode.

Custom opcode:

```text
opcode = 7'b0001011
```

Custom instructions:

```text
CSEC_XOR
CSEC_AES_STATUS
CSEC_AES_START
CSEC_AES_CT0
CSEC_AES_CLEAR
```

## Files Updated For Custom ISA

| File | Update |
| --- | --- |
| `control_unit.sv` | Detect custom opcode and generate custom control |
| `id_stage.sv` | Decode custom instruction fields |
| `ex_stage.sv` | Pass operands/control for custom operation |
| `mem_stage.sv` | Execute custom AES/security command |
| `wb_stage.sv` | Write custom result back to register file |

Speaker note:

> Normal peripherals such as UART, sensor, DMA, and interrupt controller are
> accessed through MMIO, so they do not require new RISC-V instructions. But
> custom AES operations require deeper CPU changes because the processor must
> recognize a new opcode, carry the custom command through the pipeline, execute
> it, and write the result back to a register.

## `custom_isa_extension.md`

This document explains the custom instruction format, opcode, commands, and
pipeline integration.

Speaker note:

> This document is useful for understanding the custom ISA design from a thesis
> point of view. It explains how custom AES operations are encoded and how they
> move through the pipeline.

## `custom_isa_demo.S`

This is a demo assembly file for custom instructions.

Because standard assemblers may not directly support custom mnemonics, custom
instructions can be written using raw instruction words.

Speaker note:

> This file demonstrates how software can use the custom security instructions.
> It is useful for showing the difference between conventional MMIO control and
> custom instruction based AES control.

---

# 8. Application Demo And Flow Documents

## `iot_security_demo.S`

This file describes the intended embedded software flow:

```text
read sensor data
configure AES
encrypt sensor packet
send ciphertext through UART
enter sleep/idle
```

Speaker note:

> This demo program connects the hardware blocks at the software level. It shows
> how a real health-monitoring IoT node would read sensor data, encrypt it, and
> transmit encrypted output.

## `sensor_to_encrypted_output_flow.md`

This document explains the full application flow:

```text
Health sensor
-> sensor/SPI MMIO
-> RISC-V CPU
-> AES-CTR encryption
-> UART ciphertext output
-> receiver decryption
```

Speaker note:

> This file is useful for explaining the real-world application. It clearly
> shows what data is read, what is encrypted, what output is transmitted, and
> how the receiver decrypts it.

## `instruction_data_flow_script.md`

This document explains how data moves through the processor for each
instruction type:

```text
R-type
I-type
load
store
branch
jump
MMIO
custom ISA
```

Speaker note:

> This is useful for beginner explanation and viva preparation. It explains how
> every instruction type moves through IF, ID, EX, MEM, and WB.

---

# 9. Testbench And Verification Files

## `riscv_core_tb.sv`

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

Important helper tasks:

```text
apply_reset()
run_cycles()
check_and_report()
```

Expected final result:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

Speaker note:

> The testbench proves that the original processor functionality is preserved
> and that the added IoT security features work correctly. It verifies both
> standard RISC-V instructions and the new AES, UART, sensor, interrupt, DMA,
> power, and custom ISA functionality.

## `verification_plan.md`

This document lists what is verified and why.

Speaker note:

> The verification plan gives structure to the testing strategy. It shows that
> CPU instructions, AES modes, peripherals, interrupts, DMA, power counters, and
> custom ISA behavior are all covered.

---

# 10. Documentation Files

## `README.md`

This is the main project overview.

It includes:

```text
project purpose
architecture
features
file structure
compile flow
simulation flow
verification summary
Git upload recommendation
```

## `memory_map.md`

This document gives the full MMIO address map:

```text
0x0000_0300 -> AES / AES-CTR
0x0000_0400 -> Sensor / SPI
0x0000_0500 -> UART
0x0000_0600 -> Interrupt controller
0x0000_0700 -> DMA-lite
0x0000_0800 -> Power/activity counters
```

## `iot_security_processor_architecture.md`

This explains the complete architecture and system-level contribution.

## `thesis_contribution.md`

This explains the research value:

```text
low-power AES integration
AES-CTR sensor encryption
custom security ISA
activity measurement
IoT security processor design
```

Speaker note:

> These documentation files are important because they make the project
> thesis-friendly. They explain not only what the code does, but also why the
> design is useful for low-power secure IoT applications.

---

# 11. Script And Tool Files

## `compile_light.ps1`

This script runs a lighter Quartus compile/check flow.

Speaker note:

> This is useful when full fitting takes too long or the laptop heats up. It is
> mainly for quicker synthesis-level checking.

## `compile_full_low_power.ps1`

This script runs the fuller Quartus compile flow.

Speaker note:

> This is used when a more complete FPGA compilation is required.

## `run_questa_regression.ps1`

This script runs the Questa regression automatically.

Expected result:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

## `simulation/questa/riscv_aes_advancements_run_msim_rtl_verilog.do`

This is the Questa GUI simulation script.

It compiles with:

```text
+define+SIMULATION
```

It keeps waveform visibility using:

```text
-voptargs="+acc"
add wave *
view structure
view signals
run -all
```

Speaker note:

> The Questa script is used for GUI simulation and waveform viewing. The
> simulation define is important because it keeps the instruction ROM visible
> to the testbench.

## `tools/generate_instruction_waveform_pdf.py`

This Python script converts waveform data into a submission-ready PDF/HTML
report.

Output:

```text
reports/waveforms/custom_isa_instruction_waveforms.html
reports/waveforms/custom_isa_instruction_waveforms.pdf
```

Speaker note:

> This script is useful for submission because it separates waveforms by
> instruction and peripheral type and includes beginner-friendly explanations.

---

# 12. Quartus Project Files

## `riscv_aes_advancements.qpf`

This is the Quartus project file.

## `riscv_aes_advancements.qsf`

This is the Quartus settings file. It includes source-file assignments, top
module, device selection, and project settings.

## `riscv_aes_advancements.sdc`

This is the timing constraints file. It defines the clock constraint used by
the Timing Analyzer.

Speaker note:

> The Quartus project files allow the complete design to be compiled for an
> Intel FPGA. The SDC file is important because it gives the timing analyzer a
> clock constraint.

## `.gitignore`

This file prevents generated build and simulation files from being committed.

Ignored examples:

```text
db/
incremental_db/
output_files/
simulation/questa/rtl_work/
*.vcd
*.rpt
*.qws
```

---

# 13. Which RISC-V Files Actually Needed Updates?

For adding AES, UART, SPI, DMA, interrupt, and power-management through MMIO,
the core pipeline did not need to be rewritten.

The main RISC-V files updated were:

| File | Reason |
| --- | --- |
| `riscv_aes_advancements.sv` | To instantiate and connect all new SoC blocks |
| `mem_stage.sv` | To decode MMIO address ranges and route load/store accesses |
| `riscv_core_tb.sv` | To verify all new features |

For custom ISA support, additional CPU files were updated:

| File | Reason |
| --- | --- |
| `control_unit.sv` | Detect custom opcode |
| `id_stage.sv` | Decode custom instruction fields |
| `ex_stage.sv` | Carry operands/control forward |
| `mem_stage.sv` | Execute custom AES/security commands |
| `wb_stage.sv` | Write custom result back to register file |

Mostly unchanged RISC-V files:

```text
pc_reg.sv
if_stage.sv
instr_mem.sv
reg_file.sv
imm_gen.sv
alu.sv
hazard_unit.sv
forwarding_unit.sv
load_store_unit.sv
data_mem.sv
```

Speaker note:

> The important point is that the original pipeline was preserved. Most
> peripherals were added through MMIO in the MEM stage. Only the custom ISA
> required deeper changes in decode, execute, memory, and writeback logic.

---

# 14. Comparison With Traditional Methods

This section can be used when explaining why this project is useful compared to
common ways of encrypting IoT sensor data.

## Traditional Method 1: Software AES On A Microcontroller

In a traditional low-cost IoT device, a microcontroller reads sensor data and
runs AES encryption completely in software.

Typical flow:

```text
Sensor
-> microcontroller
-> software AES routine
-> UART/Bluetooth/Wi-Fi
-> receiver
```

In this method, the CPU executes all AES operations as software instructions:

```text
SubBytes
ShiftRows
MixColumns
AddRoundKey
Key expansion
Loop control
Memory movement
```

Advantages:

```text
Easy to implement
Flexible
No extra hardware accelerator required
Works with common microcontrollers
```

Disadvantages:

```text
Large number of CPU instructions
Higher CPU active time
Higher energy per encrypted block
CPU cannot do other work during encryption
Slower for repeated sensor packets
```

Speaker note:

> Compared with software AES, this project offloads AES computation to a
> dedicated hardware accelerator. The CPU only configures the AES block and
> reads the ciphertext, so CPU active cycles and software overhead are reduced.

## Traditional Method 2: Vendor AES Peripheral

Many commercial microcontrollers include a built-in AES hardware peripheral.

Typical flow:

```text
Sensor
-> MCU
-> built-in AES peripheral
-> communication interface
-> receiver
```

Advantages:

```text
Faster than software AES
Lower CPU overhead
Practical for real products
```

Disadvantages:

```text
Architecture is usually fixed
Internal AES datapath is not modifiable
Limited research flexibility
Custom ISA integration is usually not possible
Often vendor-specific
```

Speaker note:

> This project is similar in concept to a microcontroller with an AES
> peripheral, but here the AES core is open RTL and is designed using an
> iterative hardware-reuse approach. This makes it useful for academic research
> because the datapath, switching activity, MMIO interface, CTR mode, and custom
> ISA path can all be studied and modified.

## Traditional Method 3: Wireless Protocol Encryption

Some IoT systems rely on communication protocols such as BLE, Wi-Fi, Zigbee, or
LoRaWAN to provide encryption.

Typical flow:

```text
Sensor
-> microcontroller
-> wireless stack encryption
-> receiver
```

Advantages:

```text
Industry standard
Protocol-level security
Often includes pairing/session mechanisms
Useful for commercial communication systems
```

Disadvantages:

```text
Encryption happens inside communication stack
Less control over encryption hardware
Higher software/protocol overhead
Sensor data may exist unencrypted inside local system
Not suitable for studying AES hardware architecture
```

Speaker note:

> Protocol encryption is useful in real products, but this project focuses on
> hardware-level encryption before data leaves the processor. The sensor packet
> is encrypted by the AES accelerator itself and then transmitted as ciphertext.

## Traditional Method 4: External Secure Element

Some systems use a separate security chip for cryptographic operations.

Typical flow:

```text
Sensor
-> MCU
-> external secure element over SPI/I2C
-> MCU
-> communication interface
```

Advantages:

```text
Good key protection
Better tamper resistance
Useful for commercial security products
```

Disadvantages:

```text
Extra chip cost
Extra board area
SPI/I2C communication overhead
Additional power consumption
Internal architecture is not available for research
```

Speaker note:

> Compared with an external security chip, this project integrates AES inside
> the RISC-V SoC. This avoids external bus delay and extra component cost, while
> allowing the AES hardware and processor integration to be studied at RTL
> level.

## Traditional Method 5: Gateway-Side Encryption

Some simple sensor nodes transmit raw sensor data to a gateway, and the gateway
encrypts it before sending it to the cloud.

Typical flow:

```text
Sensor node
-> raw sensor data
-> gateway
-> encrypted cloud upload
```

Advantages:

```text
Very simple sensor node
Lower local hardware requirement
Easy to implement
```

Disadvantages:

```text
Sensor data is exposed before reaching the gateway
Not suitable for private health data
Gateway must be fully trusted
Weak protection for local wireless links
```

Speaker note:

> For health-monitoring applications, gateway-side encryption is not ideal
> because private biomedical data is exposed before encryption. In this project,
> the data is encrypted at the sensor node itself before transmission.

## Proposed Method: RISC-V + Iterative AES + AES-CTR + Custom ISA

The proposed project uses:

```text
Sensor/SPI
-> RISC-V processor
-> low-power AES-CTR hardware accelerator
-> UART encrypted output
```

With optional custom ISA:

```text
Custom security instructions
-> direct AES start/status/ciphertext access
```

Advantages:

```text
AES runs in hardware instead of software
Iterative AES datapath reduces area and switching activity
AES-CTR supports continuous sensor-stream encryption
MMIO keeps compatibility with normal RISC-V load/store instructions
Custom ISA reduces AES control overhead
DMA reduces CPU data movement
Interrupts reduce polling
Power counters measure activity and sleep behavior
```

Tradeoffs:

```text
More complex than pure software AES
Custom ISA requires special instruction encoding or tool support
Full security would also require authentication and secure key storage
Current interrupt support is debug/pending-register level, not full CSR trap handling
```

Speaker note:

> The proposed method is efficient because it combines hardware AES
> acceleration with low-power datapath reuse. The CPU does not execute all AES
> steps in software. Instead, it controls a reusable AES accelerator through
> MMIO or custom security instructions. This reduces CPU workload, switching
> activity, and control overhead for repeated IoT sensor encryption.

## Comparison Table

| Method | Encryption Location | Main Advantage | Main Disadvantage |
| --- | --- | --- | --- |
| Software AES | CPU software | Simple and flexible | High CPU cycles and energy |
| Vendor AES peripheral | Fixed MCU hardware | Fast and practical | Less research/customization freedom |
| Wireless protocol encryption | BLE/Wi-Fi/Zigbee stack | Standard communication security | Less AES hardware control |
| External secure element | Separate crypto chip | Strong key protection | Extra cost and bus overhead |
| Gateway encryption | Gateway/cloud | Very simple sensor node | Raw data exposed before encryption |
| Proposed method | RISC-V SoC AES accelerator | Low-power, customizable, thesis-ready | More design complexity |

## Efficiency Explanation

The efficiency improvement comes from three levels:

```text
1. AES computation moves from software to hardware
2. AES hardware uses iterative datapath reuse
3. AES control can move from MMIO load/store sequence to custom ISA commands
```

Software AES requires many CPU instructions for one encryption block. In this
project, the CPU only configures or commands the AES accelerator.

Fully parallel AES hardware may give higher throughput, but it activates more
hardware at the same time. The proposed AES core reuses the same datapath across
rounds, reducing hardware duplication and switching activity.

MMIO control is compatible and simple, but it requires several load/store
instructions. Custom AES instructions can reduce this control overhead.

Speaker note:

> Therefore, the project is efficient compared with traditional methods because
> it reduces CPU computation, reduces AES hardware activity, and reduces
> accelerator control overhead. This makes it suitable for battery-powered IoT
> health-monitoring nodes where power and area are more important than maximum
> throughput.

---

# 15. Final Viva Summary

Use this as the closing explanation:

```text
This project converts a 5-stage RV32I-style processor into a Lightweight IoT
Security Processor. The RISC-V CPU remains the main controller, while AES,
sensor/SPI, UART, interrupt controller, DMA-lite, and power counters are added
as memory-mapped peripherals.

The most important integration file is mem_stage.sv, because it decodes the
MMIO address map and connects CPU load/store instructions to the correct
hardware block. The AES core is preserved as a low-power iterative
hardware-reusable AES-128 design, and aes_mmio.sv extends it with ECB and CTR
mode support.

For communication, UART sends encrypted ciphertext output. For sensor input,
the project supports simple sensor MMIO and an SPI interface. Interrupts reduce
polling, DMA reduces CPU data-movement overhead, and power counters support
low-power analysis.

The custom ISA version adds RISC-V custom-0 instructions for selected AES and
security operations. This allows comparison between traditional MMIO-based AES
control and custom instruction based AES acceleration.

Overall, the project demonstrates a thesis-ready secure IoT processor suitable
for health-monitoring applications, where sensor data is encrypted using
AES-CTR before transmission.
```
