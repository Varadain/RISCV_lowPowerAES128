# Signal Functionality Verification

## Purpose

This document explains how the functionality of the major processor,
peripheral, and debug signals was verified in the project:

```text
Lightweight RISC-V Based Secure Health-Monitoring IoT Processor
with AES-CTR Encryption and Custom Security ISA
```

The verification was performed using the SystemVerilog testbench:

```text
riscv_core_tb.sv
```

The simulation was run using Questa, and the expected result was:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

---

# 1. Verification Method

The testbench verifies the design using directed tests. For each test group, it
does the following:

```text
1. Clears instruction memory, data memory, and registers
2. Loads a small instruction sequence into instruction memory
3. Applies reset
4. Runs the processor for a fixed number of clock cycles
5. Checks registers, memory, peripheral registers, and debug outputs
6. Prints PASS or FAIL
```

Important testbench helper tasks:

```text
apply_reset()
run_cycles()
check_and_report()
check_seen()
reset_activity_counters()
```

## `apply_reset()`

This task applies reset to the processor and releases it after a few clock
cycles. It verifies that the design starts from a known state.

## `run_cycles()`

This task lets the design run for a fixed number of clock cycles.

Example:

```systemverilog
run_cycles(30);
```

This means the simulation waits for 30 positive clock edges before checking the
result.

## `check_and_report()`

This task compares the actual value with the expected value and prints PASS or
FAIL.

## `check_seen()`

This task checks whether an internal signal asserted at least once during
simulation.

---

# 2. Clock And Reset Verification

## Signals

```text
clk
rst_n
```

## Verification

The testbench generates the clock using:

```text
always #CLK_HALF clk = ~clk;
```

Reset is applied using `apply_reset()`.

Expected behavior:

```text
rst_n = 0 -> processor/peripherals reset
rst_n = 1 -> normal operation starts
```

How it was verified:

```text
All test groups call apply_reset()
Processor starts correctly after reset
Registers and memories are initialized before each test
All final checks pass
```

---

# 3. Program Counter And Instruction Fetch Verification

## Signals / Blocks

```text
current_pc_debug
pc
instruction
instr_mem.rom
```

## Verification

The testbench directly loads instructions into:

```text
dut.u_if_stage.u_instr_mem.rom[index]
```

Then the processor is reset and allowed to execute the instructions.

Expected behavior:

```text
PC starts from reset address
Instructions are fetched in sequence
Branch/jump instructions update PC correctly
```

Verified by:

```text
R-type tests
I-type tests
branch tests
U/J-type tests
system/pseudo instruction tests
current_pc_debug waveform visibility
```

---

# 4. Register File Verification

## Signals / Blocks

```text
regs[0:31]
reg_write
rd
rs1
rs2
writeback data
```

## Verification

The testbench checks final register values after instruction execution.

Examples:

```text
ADD  -> x3 = x1 + x2
SUB  -> x4 = x1 - x2
ADDI -> x1 = x0 + immediate
JAL  -> rd = PC + 4
```

Expected behavior:

```text
Correct destination register is updated
x0 remains zero
Wrong registers are not overwritten
```

Verified by:

```text
R-type checks
I-type checks
U/J-type checks
pseudo instruction checks
custom ISA writeback checks
```

---

# 5. ALU Signal Verification

## Signals / Blocks

```text
alu_result
alu_control
operand_a
operand_b
```

## Verification

The ALU was verified through instruction results.

Tested operations:

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
ADDI
XORI
ORI
ANDI
SLLI
SRLI
SRAI
```

Expected behavior:

```text
ALU produces correct arithmetic/logical result
Result is written back to correct register
```

Verified by:

```text
R-type test group
I-type test group
```

---

# 6. Load/Store Signal Verification

## Signals / Blocks

```text
mem_read
mem_write
mem_addr
write_data
read_data
byte_enable
data_mem.ram
```

## Verification

The testbench preloads memory with:

```text
0xAABBCCDD
```

Then it verifies:

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

Expected behavior:

```text
LB/LH sign-extend correctly
LBU/LHU zero-extend correctly
LW reads full word correctly
SB/SH/SW store correct data size
```

Verified by:

```text
Checking register values after loads
Checking data_mem.ram after stores
```

---

# 7. Hazard And Forwarding Verification

## Signals

```text
stall_if
flush_ifid
forward_a
forward_b
```

## Verification

The testbench includes signal activity checks that force situations where stall
and flush behavior should occur.

Example tested behavior:

```text
load-use dependency causes stall
branch/jump causes flush
forwarding avoids unnecessary stalls
```

Expected behavior:

```text
stall_if asserts at least once
flush_ifid asserts at least once
dependent instructions still produce correct results
```

Verified by:

```text
check_seen("stall_if", if_stall_seen_count)
check_seen("flush_ifid", if_flush_seen_count)
```

---

# 8. MMIO Address Decode Verification

## Signals / Blocks

```text
mem_stage address decoder
aes_sel
sensor_sel
uart_sel
intc_sel
dma_sel
power_sel
```

## Verification

The CPU executes load/store instructions to MMIO address ranges:

```text
0x0000_0300 -> AES
0x0000_0400 -> Sensor/SPI
0x0000_0500 -> UART
0x0000_0600 -> Interrupt controller
0x0000_0700 -> DMA-lite
0x0000_0800 -> Power/activity
```

Expected behavior:

```text
Only selected peripheral responds
Normal RAM is not selected for MMIO access
Read data comes from correct peripheral
Write enable goes to correct peripheral
```

Verified by:

```text
AES MMIO tests
Sensor MMIO tests
UART MMIO tests
Interrupt tests
DMA tests
Power/activity tests
Signal activity checks for aes_sel, aes_write_en, aes_read_en
```

---

# 9. AES ECB Verification

## Signals / Blocks

```text
aes_start
aes_busy
aes_done
key_reg
pt_reg
ct_reg
aes_ciphertext_debug
aes_done_debug
```

## Verification

The testbench writes a known AES key and plaintext, starts AES encryption, waits
for completion, and checks the ciphertext.

Expected NIST-compatible ciphertext words:

```text
CT0 = 0x70B4C55A
CT1 = 0xD8CDB780
CT2 = 0x6A7B0430
CT3 = 0x69C4E0D8
```

Expected status behavior:

```text
busy asserts during encryption
done asserts after completion
busy deasserts after completion
```

Verified by:

```text
AES-128 NIST MMIO tests
AES DONE check
AES BUSY check
Ciphertext checks CT0 to CT3
```

---

# 10. AES-CTR Verification

## Signals / Blocks

```text
mode_ctr_reg
nonce_reg
counter_reg
pt_reg
ct_reg
aes_done
```

## Verification

The testbench configures AES-CTR mode using:

```text
nonce
counter
plaintext
AES key
mode bit
```

AES-CTR operation:

```text
keystream  = AES_encrypt(nonce || counter)
ciphertext = plaintext XOR keystream
```

Expected behavior:

```text
CTR mode bit is set
Ciphertext equals plaintext XOR AES keystream
Counter auto-increments after block completion
```

Verified by:

```text
AES-CTR ciphertext checks
Counter increment check
Mode bit check
```

---

# 11. Sensor MMIO Verification

## Signals / Blocks

```text
sensor_data
sensor_status
sensor_control
sensor_data_ready_irq
```

## Verification

The CPU reads from the sensor MMIO base:

```text
0x0000_0400
```

Expected behavior:

```text
SENSOR_DATA returns expected sample value
SENSOR_STATUS is readable
Sensor ready event can feed interrupt controller
```

Verified by:

```text
Sensor MMIO tests
Register value checks
Interrupt pending test for sensor-ready bit
```

---

# 12. SPI IP Verification

## Signals / Blocks

```text
spi_sclk
spi_mosi
spi_miso
spi_ss_n
SPI_TXDATA
SPI_STATUS
SPI_CONTROL
SPI_SLAVE_SELECT
```

## Verification

The testbench configures the SPI interface through MMIO registers and checks
whether SPI activity is visible.

Expected behavior:

```text
SPI slave select asserts
SPI serial clock toggles
SPI loopback path provides waveform visibility
```

Verified by:

```text
spi_sclk_toggle_count > 0
spi_ss_n_tb == 0
```

---

# 13. UART Verification

## Signals / Blocks

```text
uart_tx
tx_busy_o
tx_done_o
done_latched
baud_div_reg
UART_TXDATA
UART_STATUS
UART_CONTROL
```

## Verification

The CPU writes a byte to:

```text
UART_TXDATA
```

The testbench sets a small baud divisor to make simulation faster.

Expected behavior:

```text
UART starts transmission
tx_busy asserts during transfer
uart_tx toggles serial data
done_latched asserts after byte is sent
tx_busy deasserts after completion
```

Verified by:

```text
UART DONE check
UART BUSY check
Waveform visibility on uart_tx
```

---

# 14. Interrupt Controller Verification

## Signals / Blocks

```text
aes_done_irq
uart_tx_done_irq
sensor_data_ready_irq
dma_done_irq
irq_pending
irq_enable
irq_clear
irq_debug
```

## Verification

The interrupt controller is tested through MMIO registers:

```text
0x0000_0600 -> IRQ_PENDING
0x0000_0604 -> IRQ_ENABLE
0x0000_0608 -> IRQ_CLEAR
```

Expected behavior:

```text
Peripheral event sets pending bit
Enable bit allows combined IRQ output
Clear register clears pending bit
irq_debug asserts when enabled pending interrupt exists
```

Verified by:

```text
Sensor-ready pending bit check
Combined irq_debug check
IRQ clear behavior
```

---

# 15. DMA-lite Verification

## Signals / Blocks

```text
dma_src_addr
dma_dst_addr
dma_len
dma_ctrl
dma_status
dma_busy
dma_done
data_mem.ram
```

## Verification

The testbench places a known word in RAM:

```text
ram[4] = 0xDEADBEEF
```

Then the CPU programs DMA to copy it to another RAM location.

Expected behavior:

```text
DMA starts after DMA_CTRL start bit
DMA copies source word to destination word
DMA sets done flag
```

Verified by:

```text
ram[5] == 0xDEADBEEF
dma_done == 1
```

---

# 16. Power And Activity Counter Verification

## Signals / Blocks

```text
sleep_debug
activity_counter_debug
cpu_active_cycles
aes_active_cycles
uart_active_cycles
dma_active_cycles
sensor_active_cycles
sleep_cycles
```

## Verification

The CPU writes to the power-management control register:

```text
0x0000_0800 -> POWER_CTRL
```

Expected behavior:

```text
Sleep control bit sets sleep_debug
Sleep counter increments during sleep mode
Activity debug output is observable
Counters can be cleared
```

Verified by:

```text
sleep_debug == 1
sleep_cycles > 0
activity_counter_debug matches power block output
```

---

# 17. Custom Security ISA Verification

## Signals / Blocks

```text
custom opcode decode
custom command/funct3
custom operands
custom result
AES custom control path
register writeback
```

## Custom Instructions Verified

```text
CSEC_XOR
CSEC_AES_STATUS
CSEC_AES_START
CSEC_AES_CT0
CSEC_AES_CLEAR
```

## Verification

The testbench encodes custom instructions using the custom-0 opcode:

```text
opcode = 7'b0001011
```

Expected behavior:

```text
CSEC_XOR writes rs1 XOR rs2 to rd
CSEC_AES_STATUS returns AES busy/done/mode bits
CSEC_AES_START starts AES-CTR operation
CSEC_AES_CT0 reads ciphertext word 0
CSEC_AES_CLEAR clears AES done flag
```

Verified by:

```text
Register result checks
AES mode bit check
AES done/status check
Ciphertext word check
Clear behavior check
```

---

# 18. Debug Output Verification

## Signals

```text
current_pc_debug
aes_done_debug
aes_ciphertext_debug
uart_tx
irq_debug
sleep_debug
activity_counter_debug
```

## Verification

These outputs are connected at the top level so they remain observable in FPGA
and simulation.

Expected behavior:

```text
current_pc_debug changes as instructions execute
aes_done_debug asserts when AES completes
aes_ciphertext_debug shows ciphertext word/output
uart_tx toggles during UART transmission
irq_debug asserts for enabled interrupt
sleep_debug asserts when sleep bit is set
activity_counter_debug changes with activity counter value
```

Verified by:

```text
Directed checks in testbench
Waveform observation
Quartus synthesis preserving observable outputs
```

---

# 19. Waveform Verification

The Questa simulation generates waveform data. The waveform PDF report was
generated using:

```text
tools/generate_instruction_waveform_pdf.py
```

The report separates waveforms by:

```text
R-type instructions
I-type instructions
Load/store instructions
Branch instructions
U/J instructions
AES ECB
AES CTR
Sensor MMIO
SPI IP
UART
Interrupt controller
DMA-lite
Power/activity counters
Custom security ISA
```

Waveforms help visually confirm:

```text
reset behavior
PC movement
instruction execution
register writeback
MMIO selection
AES busy/done
UART busy/done
SPI serial clock activity
IRQ assertion
DMA completion
sleep/activity counter behavior
```

---

# 20. Final Verification Summary

The project functionality was verified at three levels:

## 1. Processor Instruction Level

Verified through:

```text
R-type
I-type
Load/store
Branch
U/J
System/fence/pseudo
```

## 2. Peripheral And SoC Level

Verified through:

```text
AES ECB
AES CTR
Sensor MMIO
SPI IP
UART
Interrupt controller
DMA-lite
Power/activity counters
```

## 3. Custom ISA Level

Verified through:

```text
CSEC_XOR
CSEC_AES_STATUS
CSEC_AES_START
CSEC_AES_CT0
CSEC_AES_CLEAR
```

Expected final result:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

Speaker summary:

```text
All important functionality was verified using directed simulation tests. The
testbench checks final register values, memory contents, peripheral status
registers, interrupt pending behavior, DMA transfer completion, activity
counters, custom instruction results, and waveform activity. This confirms that
the original RISC-V pipeline still works correctly and that AES, UART, SPI,
sensor, interrupt, DMA, power, and custom ISA functionality are integrated
properly.
```

