# One-Day Overprepared Thesis-Defense Plan

## Project Title

**Design and Verification of a Lightweight RISC-V-Based IoT Security Processor with Iterative Hardware-Reusable AES 128**

This plan is designed for one serious preparation day. It does not ask you to memorize every RTL line. It teaches you the project in the order an examiner is likely to question it:

```text
Problem -> design choice -> RTL implementation -> verification -> results -> limitations
```

The target is not to sound as if you memorized a report. The target is to understand the flow well enough to answer:

```text
What did you build?
Why did you build it this way?
How is it implemented?
How did you verify it?
Which result proves each claim?
What is still missing?
```

---

# 1. Files to Keep Open During the Day

## Main presentation

[`presentation/RISC_V_AES_Thesis_Presentation_30_Minutes_Formal_White.pptx`](presentation/RISC_V_AES_Thesis_Presentation_30_Minutes_Formal_White.pptx)

## Easy-English speaker script

[`presentation/RISC_V_AES_Thesis_Presentation_30_Minute_Script_Easy_English.md`](presentation/RISC_V_AES_Thesis_Presentation_30_Minute_Script_Easy_English.md)

## Verified result sheet

[`thesis_report_autonomous_vehicle_fresh/submission_final/RESULT_AND_WAVEFORM_AUDIT_2026-06-27.md`](thesis_report_autonomous_vehicle_fresh/submission_final/RESULT_AND_WAVEFORM_AUDIT_2026-06-27.md)

## 32-bit CPU to 128-bit AES explanation

[`32bit_cpu_128bit_aes_code_walkthrough.md`](32bit_cpu_128bit_aes_code_walkthrough.md)

## Interrupt and power explanation

[`interrupt_and_power_management_code_walkthrough.md`](interrupt_and_power_management_code_walkthrough.md)

## Full question banks for extra drilling

- [`thesis_report_autonomous_vehicle_fresh/VIVA_500_CROSS_QUESTIONS.md`](thesis_report_autonomous_vehicle_fresh/VIVA_500_CROSS_QUESTIONS.md)
- [`thesis_report_autonomous_vehicle_fresh/RESULTS_NUMBERS_300_CROSS_QUESTIONS.md`](thesis_report_autonomous_vehicle_fresh/RESULTS_NUMBERS_300_CROSS_QUESTIONS.md)

Do not begin by reading the 500 questions. Use the selected hard questions in this plan first. Use the larger banks only after the main preparation is complete.

---

# 2. One-Day Timetable

| Time | Activity | Output you must produce |
|---|---|---|
| 06:30-07:00 | Set up files, water, notebook and timer | One clean workspace and a handwritten result sheet |
| 07:00-08:00 | Learn the project story and presentation opening | Deliver a 90-second explanation without reading |
| 08:00-10:00 | Study top-level architecture and processor pipeline | Draw the complete block diagram from memory |
| 10:00-10:20 | Break | No screen |
| 10:20-12:15 | Study AES, CTR, MMIO, 32-to-128-bit path and custom ISA | Explain one complete AES transaction from code |
| 12:15-13:00 | Lunch and short walk | No technical study |
| 13:00-14:15 | Study UART, sensor/SPI, DMA, interrupts and power | Explain why every peripheral exists |
| 14:15-15:45 | Study directed testbench, UVM, C model and coverage | Draw the verification architecture from memory |
| 15:45-16:05 | Break | No screen |
| 16:05-17:45 | Waveform clinic in Questa | Explain five waveform groups without notes |
| 17:45-19:00 | Netlist, timing, area and power clinic | Explain Quartus and Genus evidence separately |
| 19:00-19:40 | Dinner | Stop technical discussion |
| 19:40-21:00 | Tough cross-question drill | Answer 50 selected questions aloud |
| 21:00-21:35 | Full 30-minute presentation rehearsal | Record one complete attempt |
| 21:35-22:00 | Review recording and repair weak points | Write only five corrections |
| 22:00-22:35 | Hostile mock viva | Answer fast, including limitations |
| 22:35-23:00 | Final compressed rehearsal | Opening, architecture, results and conclusion |
| 23:00-23:20 | Prepare files and backup | PPT, PDF, logs and report available offline |
| 23:20 | Stop | Sleep; do not continue reading randomly |

Use a timer. When a block ends, move to the next block even if you have not read every line.

---

# 3. The Answer Method for Every Question

Use this four-part structure:

```text
1. WHAT: Give the direct definition.
2. WHY: State why the project needs it.
3. HOW: Point to the RTL or verification mechanism.
4. LIMIT: State the current limitation honestly.
```

Example question: Why is the interrupt controller present?

```text
WHAT: It collects AES, UART, sensor and DMA events.
WHY: It prevents short completion events from being missed and reduces polling.
HOW: Sticky pending bits are ANDed with enable bits to create irq_o.
LIMIT: The CPU does not yet implement full CSR and trap handling, so irq_o is
       currently verified as a debug and event output.
```

This structure works for almost every design and verification question.

---

# 4. Project Story You Must Know Before Opening RTL

Memorize these ten statements:

1. The work began with a standalone iterative AES-128 architecture.
2. One AES datapath is reused instead of implementing ten parallel round units.
3. The standalone comparison proves the AES area and estimated-power benefit.
4. The reusable AES is integrated with a five-stage RV32I-style processor.
5. The CPU controls peripherals mainly through MMIO in the MEM stage.
6. AES-CTR protects sensor records; ECB remains only for NIST primitive testing.
7. Custom instructions provide a compact additional AES-control path.
8. Sensor/SPI, DMA, UART, interrupts and activity counters form the application path.
9. Verification grows from AES KAT to CPU, peripherals, random, UVM and Full-SoC.
10. This is an RTL/FPGA research prototype, not an automotive-qualified product.

## 90-second opening practice

> Good morning. My work is a lightweight RISC-V-based IoT security processor. The main hardware contribution is an iterative AES-128 accelerator that reuses one datapath across the AES rounds, reducing duplicated hardware and switching activity. I integrated this accelerator with a five-stage RV32I-style processor through MMIO and a small custom security ISA. The system reads modeled sensor or SPI data, moves data using DMA-lite, encrypts a 128-bit record in AES-CTR mode, sends ciphertext through UART, records completion events through an interrupt controller and measures activity and sleep cycles. I verified the design using NIST known-answer testing, directed CPU and peripheral tests, deterministic random tests, a UVM environment with an independent C-DPI reference, portable functional coverage and a complete sensor-to-UART scenario. Quartus and Genus results are reported separately because they use different technologies and scopes.

Practice this until you can say it naturally without looking down.

---

# 5. Exact RTL Learning Sequence

Do not open files alphabetically. Use this order.

## Priority A: Must understand deeply

| Order | File | What to learn | Examiner may ask |
|---:|---|---|---|
| 1 | [`riscv_aes_advancements.sv`](riscv_aes_advancements.sv) | Top-level pipeline and debug connections | Where is the complete system connected? |
| 2 | [`mem_stage.sv`](mem_stage.sv) | MMIO decode and peripheral integration | Why is MEM the interconnect? |
| 3 | [`aes_mmio.sv`](aes_mmio.sv) | 32-bit word assembly, CTR, status and result | How does a 32-bit CPU control 128-bit AES? |
| 4 | [`aes128_lowpower.sv`](aes128_lowpower.sv) | Stable wrapper around publication AES core | Why is a wrapper used? |
| 5 | [`rtl/aes128_reusable/00_aes128_top.sv`](rtl/aes128_reusable/00_aes128_top.sv) | AES FSM and reusable datapath | How is hardware reused? |
| 6 | [`control_unit.sv`](control_unit.sv) | Standard and custom opcode decode | Where is custom-0 recognized? |
| 7 | [`id_stage.sv`](id_stage.sv) | Instruction fields and custom command | Is AES executed in ID? |
| 8 | [`ex_stage.sv`](ex_stage.sv) | Operand forwarding and custom operand path | What happens in EX? |
| 9 | [`riscv_core_tb.sv`](riscv_core_tb.sv) | Directed and Full-SoC tests | How was the complete CPU verified? |

## Priority B: Understand purpose and interfaces

| Order | File | Main point |
|---:|---|---|
| 10 | [`pc_reg.sv`](pc_reg.sv) | Stores the program counter. |
| 11 | [`if_stage.sv`](if_stage.sv) | Fetches instruction and selects next PC. |
| 12 | [`instr_mem.sv`](instr_mem.sv) | Stores program; simulation ROM is loaded by testbench. |
| 13 | [`reg_file.sv`](reg_file.sv) | Two 32-bit reads and one 32-bit write; x0 is zero. |
| 14 | [`imm_gen.sv`](imm_gen.sv) | Builds I, S, B, U and J immediates. |
| 15 | [`hazard_unit.sv`](hazard_unit.sv) | Stalls load-use dependencies and controls flushes. |
| 16 | [`forwarding_unit.sv`](forwarding_unit.sv) | Forwards MEM/WB results to EX. |
| 17 | [`alu.sv`](alu.sv) | Implements arithmetic, logic, shifts and comparisons. |
| 18 | [`load_store_unit.sv`](load_store_unit.sv) | Formats byte, half-word and word accesses. |
| 19 | [`data_mem.sv`](data_mem.sv) | Normal RAM plus DMA port. |
| 20 | [`wb_stage.sv`](wb_stage.sv) | Selects ALU or memory/custom result for register writeback. |

## Priority C: Peripheral files

| File | One-line explanation |
|---|---|
| [`sensor_spi_mmio.sv`](sensor_spi_mmio.sv) | CPU-visible sensor/SPI registers and ready event. |
| [`ip/sensor_spi_ip/sensor_spi_ip.v`](ip/sensor_spi_ip/sensor_spi_ip.v) | SPI IP used for practical serial sensor access. |
| [`uart_mmio.sv`](uart_mmio.sv) | CPU-visible UART registers and sticky completion. |
| [`uart_tx.sv`](uart_tx.sv) | Sends one byte as start, eight data and stop bits. |
| [`dma_lite.sv`](dma_lite.sv) | Copies 32-bit words through a simple programmed transfer. |
| [`simple_intc.sv`](simple_intc.sv) | Stores peripheral events in sticky pending bits. |
| [`power_mgmt_mmio.sv`](power_mgmt_mmio.sv) | Sleep request and activity-cycle counters. |

---

# 6. Architecture Study: 08:00-10:00

## Step 1: Draw the five-stage pipeline

```text
PC -> IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
```

Add these side blocks:

```text
ID: register file, immediate generator, control unit
EX: ALU and forwarding
Pipeline control: hazard and forwarding units
MEM: RAM, MMIO decoder and all peripherals
WB: ALU result or memory/custom result
```

## Step 2: Explain why the MEM stage is the peripheral interconnect

Loads and stores already produce:

```text
effective address
write data
read/write control
```

`mem_stage.sv` checks the address page:

| Address | Peripheral |
|---:|---|
| `0x0000_0300` | AES and AES-CTR |
| `0x0000_0400` | Sensor and SPI |
| `0x0000_0500` | UART |
| `0x0000_0600` | Interrupt controller |
| `0x0000_0700` | DMA-lite |
| `0x0000_0800` | Power and activity control |

One read multiplexer returns either RAM or one selected peripheral. This prevents multiple read-data drivers.

## Step 3: Explain one normal instruction

Example: `ADD x3, x1, x2`

```text
IF:  fetch instruction
ID:  decode ADD and read x1/x2
EX:  ALU adds operands
MEM: pass result; no memory access
WB:  write result into x3
```

## Step 4: Explain one load

Example: `LW x3, 0(x1)`

```text
IF:  fetch
ID:  decode load, read base x1 and form immediate
EX:  calculate address x1 + 0
MEM: read RAM or MMIO
WB:  write 32-bit read data into x3
```

## Step 5: Explain a load-use hazard

```text
LW   x1, 0(x2)
ADDI x3, x1, 1
```

The second instruction needs data that is not ready in EX. The hazard unit stalls the front of the pipeline and inserts a bubble. Forwarding handles results that are already available from MEM or WB.

## Architecture checkpoint

Without notes, answer:

1. Why is it called a five-stage processor?
2. Where are branch decisions produced?
3. Where are peripherals decoded?
4. What is the difference between a stall and a flush?
5. Why is forwarding still required when a register file exists?

Do not continue until you can answer all five in under two minutes.

---

# 7. AES, CTR, MMIO and Custom ISA: 10:20-12:15

## AES primitive

AES-128 processes:

```text
128-bit plaintext
128-bit key
10 rounds
128-bit ciphertext
```

The transformations are:

```text
Initial: AddRoundKey
Rounds 1-9: SubBytes -> ShiftRows -> MixColumns -> AddRoundKey
Round 10: SubBytes -> ShiftRows -> AddRoundKey
```

The proposed architecture reuses the same SubBytes, MixColumns and key-expansion helpers across rounds.

## Why iterative reuse?

```text
Benefit: less duplicated logic and less switched capacitance.
Cost: more clock cycles per block.
Target: moderate-rate, area- and energy-constrained sensor systems.
```

## Correct current latency

Do not say that the current integrated core completes in 40 cycles.

The retained VCD confirms:

```text
Primitive latency: 295 cycles at a 10 ns simulation clock = 2.950 us
MMIO-visible latency: 296 cycles = 2.960 us
Projected primitive latency at 50 MHz: 5.90 us
Projected primitive throughput at 50 MHz: 21.69 Mbit/s
```

The 50 MHz values are projections from measured cycle count. They are not board measurements.

## CTR mode

For block `i`:

```text
X_i = nonce || counter_i
K_i = AES_encrypt(key, X_i)
C_i = P_i XOR K_i
```

Decryption is:

```text
P_i = C_i XOR K_i
```

The same AES encryption primitive is used in both directions.

## Why CTR?

- No padding is required.
- The same encryption primitive performs encryption and decryption.
- Blocks can be handled independently when counters are known.
- It suits fixed or streaming sensor records.

## CTR limitation

- CTR gives confidentiality, not authentication.
- Reusing the same key and nonce-counter value repeats the keystream.
- A production design needs authenticated encryption such as GCM or CTR plus a MAC.

## How a 32-bit CPU handles 128-bit AES

The CPU sends four words:

```text
KEY0 + KEY1 + KEY2 + KEY3 -> 128-bit key_reg
PT0  + PT1  + PT2  + PT3  -> 128-bit pt_reg
```

For the NIST plaintext:

```text
PT0 = CCDDEEFF
PT1 = 8899AABB
PT2 = 44556677
PT3 = 00112233
```

The AES wrapper assembles:

```text
pt_reg = {PT3, PT2, PT1, PT0}
```

The dedicated AES core performs the 128-bit operation. The CPU later reads `CT0` to `CT3` as four 32-bit words.

## Custom instruction path

Opcode:

```text
custom-0 = 0001011
```

Commands:

```text
CSEC_XOR
CSEC_AES_STATUS
CSEC_AES_START
CSEC_AES_CT0
CSEC_AES_CLEAR
```

Path:

```text
IF fetches custom instruction
ID recognizes custom-0 and funct3
EX forwards rs1 and rs2
MEM sends command to aes_mmio
WB returns a 32-bit result
```

AES is not performed in ID. ID only decodes the command.

## Custom instruction limitation

The current `CSEC_AES_START` has two 32-bit operands. It loads only the lower 64 plaintext bits and clears the upper 64 bits. Full 128-bit setup still uses MMIO. `CSEC_AES_CT0` directly returns only the lowest ciphertext word.

## Checkpoint drawing

Draw this from memory:

```text
Four CPU stores -> aes_mmio 128-bit registers -> reusable AES FSM
                                      |
                                      v
Four CPU loads  <- ciphertext register
```

---

# 8. Peripheral Study: 13:00-14:15

## Sensor/SPI

The simulated sensor provides a known data word. The SPI path shows how a real serial sensor interface can replace the simple model.

The sensor provides physical readings. It does not provide the AES key, nonce or counter.

## DMA-lite

Purpose:

```text
Move 32-bit words without making the CPU perform every copy operation.
```

Current limitation:

```text
It is a small staged transfer engine, not a full high-performance bus-master DMA.
```

## UART

UART frame:

```text
one low start bit
eight data bits, least-significant bit first
no parity
one high stop bit
```

This is called 8-N-1.

The RTL bit tick occurs every `baud_div + 1` clock cycles:

```text
baud rate = clock frequency / (baud_div + 1)
```

At 50 MHz for approximately 115200 baud:

```text
baud_div approximately 433
```

The testbench often uses a much smaller divisor, such as one, to make simulation faster. Do not claim the testbench waveform itself is a physical 115200-baud measurement.

## Interrupt controller

Inputs:

```text
bit 0 AES done
bit 1 UART done
bit 2 sensor ready
bit 3 DMA done
```

Registers:

```text
IRQ_PENDING
IRQ_ENABLE
IRQ_CLEAR
```

Sticky pending bits prevent short events from being lost.

Current limitation: the CPU does not yet have full CSR and trap handling. `irq_o` is an observed event line and future integration point.

## Power and activity

Counters:

```text
CPU active
AES active
UART active
DMA active
sensor active
sleep cycles
```

They measure cycles, not watts.

Current sleep behavior holds selected peripheral state through clock enables. It does not completely halt the CPU pipeline.

## Peripheral checkpoint

Explain the full path in one minute:

```text
Sensor -> CPU/RAM -> DMA -> AES-CTR -> UART -> interrupt/activity -> sleep
```

---

# 9. Verification Study: 14:15-15:45

## Main directed testbench

Start with [`riscv_core_tb.sv`](riscv_core_tb.sv).

Important tasks:

| Task | Current line | Purpose |
|---|---:|---|
| `run_rtype_tests` | 519 | R-type instructions |
| `run_itype_tests` | 559 | I-type instructions |
| `run_load_store_tests` | 593 | Loads and stores |
| `run_branch_tests` | 636 | Branch conditions and control flow |
| `run_u_jtype_tests` | 680 | LUI, AUIPC, JAL and JALR |
| `run_system_fence_pseudo_tests` | 711 | System, fence and pseudo behavior |
| `run_aes_nist_tests` | 766 | AES NIST known-answer test |
| `run_aes_ctr_tests` | 817 | CTR operation and counter behavior |
| `run_sensor_mmio_tests` | 860 | Sensor register access |
| `run_sensor_spi_ip_tests` | 875 | SPI activity |
| `run_uart_mmio_tests` | 898 | UART status and completion |
| `run_end_to_end_uart_aes_ctr_tests` | 915 | AES-CTR and UART transcript |
| `run_interrupt_tests` | 957 | Pending, enable and combined IRQ |
| `run_dma_lite_tests` | 974 | DMA word copy |
| `run_power_activity_tests` | 996 | Sleep and counters |
| `run_custom_isa_tests` | 1015 | Custom security commands |
| `run_signal_activity_tests` | 1064 | Stall, flush and MMIO activity |
| `run_random_coverage_tests` | 1100 | Deterministic random smoke |
| `run_full_soc_pipeline_integration_test` | 1176 | Complete sensor-to-output program |

The testbench is self-checking. `check_and_report` compares observed and expected values and increments pass or fail counters.

## UVM files in reading order

1. [`verification/uvm_e2e/uvm_e2e_if.sv`](verification/uvm_e2e/uvm_e2e_if.sv)
2. [`verification/uvm_e2e/uvm_e2e_pkg.sv`](verification/uvm_e2e/uvm_e2e_pkg.sv)
3. [`verification/uvm_e2e/uvm_e2e_tb_top.sv`](verification/uvm_e2e/uvm_e2e_tb_top.sv)
4. [`verification/uvm_e2e/aes_ctr_ref.c`](verification/uvm_e2e/aes_ctr_ref.c)

## UVM class sequence

```text
sequence item
    -> sequence
    -> sequencer
    -> driver
    -> AES-MMIO and UART DUT path
    -> UART monitor
    -> scoreboard
    -> coverage collector
```

Important package locations:

| Component | File location |
|---|---:|
| DPI-C AES reference import | `uvm_e2e_pkg.sv:18` |
| Random transaction item | `uvm_e2e_pkg.sv:30` |
| Sequence | `uvm_e2e_pkg.sv:74` |
| Driver | `uvm_e2e_pkg.sv:132` |
| Portable coverage | `uvm_e2e_pkg.sv:292` |
| UART monitor | `uvm_e2e_pkg.sv:451` |
| Scoreboard | `uvm_e2e_pkg.sv:498` |
| Environment | `uvm_e2e_pkg.sv:591` |
| Test | `uvm_e2e_pkg.sv:625` |

## What UVM actually verifies

The UVM DUT scope is the AES-MMIO plus UART component path. It does not run the full CPU pipeline.

It checks:

```text
RTL AES-CTR ciphertext equals the independent C model
C-model decryption equals the original plaintext
UART serial monitor reconstructs the expected output line
```

The directed and Full-SoC testbench verifies complete CPU and peripheral integration.

## Coverage wording

The installed Starter Edition did not provide the native `svverification` covergroup feature. The project therefore uses a portable SystemVerilog collector for the planned 114 bins.

Say:

```text
portable functional coverage reached 114/114 planned bins
```

Do not say:

```text
native simulator covergroup coverage was measured
```

---

# 10. Questa Waveform Clinic: 16:05-17:45

## How to launch each prepared view

From PowerShell:

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA\verification\questa_wave_capture"

powershell -ExecutionPolicy Bypass -File .\launch_capture.ps1 -Test 01
```

Test selectors:

| Selector | View |
|---:|---|
| `01` | AES known-answer test |
| `02` | Directed CPU |
| `03` | Directed peripherals and custom ISA |
| `04` | Deterministic random smoke |
| `05` | UVM and C-reference path |
| `06` | Functional coverage closure |
| `07` | Full-SoC application scenario |

## Universal waveform explanation method

For every waveform, explain five things:

```text
1. Objective: What is this test proving?
2. Input: Which values or instructions are applied?
3. Trigger: Which signal starts the operation?
4. Progress: Which signals change while it is running?
5. Completion: Which value proves PASS?
```

## Waveform 1: AES known-answer test

Inputs:

```text
Key       = 000102030405060708090A0B0C0D0E0F
Plaintext = 00112233445566778899AABBCCDDEEFF
Expected  = 69C4E0D86A7B0430D8CDB78070B4C55A
```

Read signals in this order:

```text
clk and reset
key and plaintext
start pulse
busy high
round and state progression
round-key progression
done high and busy low
final ciphertext
pass/fail log
```

The safest pass rule is:

```text
At done = 1, compare ciphertext with the expected NIST value.
```

Important detail: the screenshot window may stop before the software checks increment `pass_count`. The companion log confirms `6 PASS, 0 FAIL`.

This KAT is a wrapper-level test. It initializes AES wrapper registers hierarchically; it is not a CPU-issued MMIO sequence.

## Waveform 2: Directed CPU

Explain:

```text
PC fetches changing instructions
ID reads operands and control
EX produces ALU/address/branch result
MEM accesses RAM when required
WB writes register result
stall handles load-use dependency
flush removes wrong-path instruction after control transfer
```

Final evidence: `47 PASS, 0 FAIL`.

## Waveform 3: Directed peripherals

Break it into three captures:

1. AES-CTR, sensor and SPI activity.
2. UART, interrupt, DMA and power activity.
3. Custom instruction and AES interaction.

Final evidence: `25 PASS, 0 FAIL`.

## Waveform 4: Random smoke

Explain that the values change under a fixed seed, making the test random but reproducible.

Final evidence: `5 PASS, 0 FAIL`.

## Waveform 5: UVM end-to-end

Explain four parts:

```text
random plaintext/key/nonce/counter
RTL ciphertext versus C reference
UART transmission and monitor reconstruction
scoreboard match and coverage update
```

The readable waveform may show one representative transaction. Do not call that image the 25-transaction regression or the 100-transaction closure run.

## Waveform 6: Coverage closure

Final visible values:

```text
transaction_index = 100
coverage_bins = 114
coverage_percent_x100 = 10000
uart_matches = 100
uart_mismatches = 0
```

## Waveform 7: Full-SoC scenario

Explain in this order:

```text
CPU reads sensor word 12345678
CPU stores sample and DMA copies it
CPU programs AES-CTR
AES CT0 becomes 62809322
UART transmits low byte 22
AES/UART/sensor/DMA pending bits become visible
activity counters become nonzero
sleep request becomes one
```

Final evidence: `15 PASS, 0 FAIL`.

## Waveform examiner traps

| Trap question | Correct answer |
|---|---|
| Why is `pass_count` zero in the KAT screenshot? | Cursor/window is before the software report update; log confirms six passes. |
| Is every green transition correct? | Color alone does not prove correctness; compare trigger, completion and expected values. |
| Why is the waveform digital and clean? | RTL simulation models logic values and timing, not analog noise or supply spikes. |
| Is 10 ns the FPGA clock? | It is the testbench simulation period. Quartus uses the separate 20 ns, 50 MHz constraint. |
| Does one UVM screenshot prove 100 transactions? | No. The 100-transaction log and coverage waveform prove closure. |

---

# 11. Netlist and Results Clinic: 17:45-19:00

## Quartus netlist files

- [`netlist.JPG`](netlist.JPG): complete Quartus RTL/netlist view.
- [`thesis_report_autonomous_vehicle_fresh/assets/mem_netlist.JPG`](thesis_report_autonomous_vehicle_fresh/assets/mem_netlist.JPG): MEM-stage integration.
- [`thesis_report_autonomous_vehicle_fresh/assets/ex_netlist.JPG`](thesis_report_autonomous_vehicle_fresh/assets/ex_netlist.JPG): EX-stage logic.

## Genus schematic

- [`risc_aes_finalReports/gui_schematic_png.png`](risc_aes_finalReports/gui_schematic_png.png)
- [`risc_aes_finalReports/outputs/riscv_aes_advancements_netlist.sv`](risc_aes_finalReports/outputs/riscv_aes_advancements_netlist.sv)

## How to explain a netlist

Use this sequence:

```text
1. Name the synthesis tool and design scope.
2. Identify the top-level hierarchy.
3. Trace one important data path.
4. Trace one control path.
5. State what the image proves.
6. State what it does not prove.
```

## Quartus complete view

Say:

> This RTL Viewer image shows that the five pipeline stages and peripheral hierarchy were elaborated together. It is structural evidence that the modules are connected and retained after synthesis. Functional correctness comes from simulation, not from the netlist image alone.

## MEM-stage view

Trace:

```text
EX address
 -> MMIO page decoder
 -> RAM or selected peripheral
 -> read-data multiplexer
 -> MEM/WB register
```

Point out AES, sensor/SPI, UART, INTC, DMA and power branches.

## EX-stage view

Trace:

```text
register operands
 -> forwarding multiplexers
 -> ALU
 -> branch/address result
 -> EX/MEM register
```

## Genus mapped schematic

Say:

> This is a technology-mapped standard-cell schematic of the complete SoC using GPDK045 HVT cells. Its density reflects approximately 50,968 mapped leaf cells and wide processor buses. It proves synthesis and library mapping, but it is not a placed-and-routed physical layout.

## What a netlist does not show

- Final physical placement.
- Routed wire length and parasitics.
- Clock-tree implementation.
- IR drop, supply noise or electromagnetic effects.
- Functional correctness for all tests.
- Automotive qualification.

---

# 12. Numbers You Must Memorize

## Verification

| Layer | Result |
|---|---:|
| AES known-answer | 6 PASS, 0 FAIL |
| Directed CPU | 47 PASS, 0 FAIL |
| Directed peripherals/custom ISA | 25 PASS, 0 FAIL |
| Random smoke | 5 PASS, 0 FAIL |
| UVM regression | 25 matches, 0 mismatches, 96/114 bins |
| Coverage closure | 100 matches, 0 mismatches, 114/114 bins |
| Full-SoC scenario | 15 PASS, 0 FAIL |
| Combined directed regression | 107 PASS, 0 FAIL |

## Standalone AES comparison, Cadence Genus TSMC 55 nm RVT

| Metric | Baseline | Reusable |
|---|---:|---:|
| Cells | 83,352 | 2,694 |
| Area | 202,949.64 um2 | 11,841.480 um2 |
| Total power | 21.9 mW | 0.853125 mW |
| Reduction | 96.77% cells | 94.17% area, 96.10% power |

Reusable AES timing:

```text
data path = 3.102 ns
setup slack at 10 ns = +6.806 ns
```

## Quartus complete FPGA SoC

```text
Tool: Quartus Prime 23.1std.1 Build 993
Device: Cyclone V 5CGXFC7C7F23C8
ALMs: 13,257 / 56,480 = 23%
Registers: 11,154
Pins: 106 / 268 = 40%
Setup slack: +2.577 ns
Hold slack: +0.371 ns
Constraint-equivalent Fmax: approximately 57.40 MHz
Total power estimate: 519.72 mW
Static / dynamic / I/O: 350.49 / 147.14 / 22.09 mW
Power confidence: low, vectorless
```

## Genus complete SoC, GPDK045 HVT

```text
Leaf cells: 50,968
Combinational / sequential: 40,120 / 10,848
Mapped area: 135,947.599 um2
Worst data path: 17.169 ns
Setup / uncertainty / slack: 0.316 / 0.200 / +2.315 ns
TNS and violating paths: 0 / 0
Constraint-equivalent Fmax: 56.55 MHz
Total power: 1.43753 mW
Internal / switching / leakage: 1.29801 / 0.13743 / 0.002084 mW
```

## The one rule for results

Never compare these three groups directly:

```text
standalone AES at TSMC 55 nm
complete FPGA SoC on Cyclone V
complete HVT SoC on GPDK045
```

They have different scopes, technologies, libraries and power assumptions.

---

# 13. Fifty Tough Cross Questions with Convincing Answers

Practice aloud. Keep the first sentence direct.

## A. Motivation and novelty

### 1. What is the main novelty?

The core hardware novelty is reuse of one AES datapath across the AES rounds. The thesis contribution is integrating that accelerator into a verified RISC-V sensor-security SoC with MMIO, custom commands and layered verification.

### 2. Why is this not just another AES implementation?

The work connects the standalone reusable AES result to a complete processor-controlled application and verifies the path through sensor, DMA, AES-CTR, UART, interrupts and activity counters.

### 3. Why use RISC-V?

RISC-V is open, modular and provides reserved custom opcode spaces. It allows processor-accelerator research without a proprietary ISA license.

### 4. Why is the target called lightweight?

The AES datapath is reused, peripherals are simple, DMA is word-oriented and control uses MMIO. Lightweight refers to architectural simplicity and moderate resource use, not to a formal lightweight-cryptography standard.

### 5. Why choose an autonomous-vehicle scenario?

Vehicle sensor nodes produce continuous telemetry and have strict resource, latency and security constraints. It is a demanding example that exposes both the value and limitations of the prototype.

## B. AES and cryptography

### 6. Why AES-128 instead of AES-256?

AES-128 provides a standardized 128-bit security level with fewer rounds and lower hardware cost. AES-256 is a possible future extension but needs fourteen rounds and a different key schedule.

### 7. Why not use a lightweight cipher?

AES has broad standardization, tool support and deployment familiarity. The research goal was to make standard AES hardware more resource efficient through reuse.

### 8. Why CTR instead of ECB?

ECB leaks repeated-block patterns. CTR creates a changing keystream, requires no padding and uses the same AES encryption primitive for encryption and decryption.

### 9. Why not use CBC?

CBC has block-to-block dependency and needs padding for incomplete blocks. CTR is simpler for independent sensor records.

### 10. Why not use GCM now?

GCM adds authentication and is better for production, but it also requires GHASH, tag handling and a larger verification scope. CTR was selected to demonstrate confidentiality using the existing AES primitive.

### 11. What happens if the nonce-counter repeats?

The keystream repeats. XORing two ciphertexts then reveals the XOR of the plaintexts, so the same key and nonce-counter combination must never be reused.

### 12. Does CTR prevent modification?

No. CTR is malleable and provides confidentiality only. Authentication must be added for production.

### 13. Where does the key come from?

In the prototype the key is written into MMIO registers by trusted software or the testbench. Secure provisioning and protected key storage are future work.

### 14. How is decryption performed?

The receiver encrypts the same nonce-counter value to regenerate the keystream and XORs it with ciphertext.

### 15. Why does round 10 skip MixColumns?

The AES standard defines the final round as SubBytes, ShiftRows and AddRoundKey without MixColumns.

### 16. Why does the current AES take 295 cycles?

The architecture reuses sequential helper blocks, including byte-serial substitution and staged MixColumns/key expansion. The long latency is the cost of low hardware duplication.

### 17. Is 21.69 Mbit/s measured on a board?

No. It is projected at 50 MHz from the measured 295-cycle primitive latency.

## C. Processor and custom ISA

### 18. How does a 32-bit CPU handle a 128-bit key?

It performs four 32-bit stores into KEY0 to KEY3. The AES wrapper assembles them into one 128-bit `key_reg`.

### 19. Is AES performed in the ID stage?

No. ID only decodes the custom opcode. The command passes through EX and reaches `aes_mmio` in MEM, where the accelerator starts.

### 20. Why execute the custom command in MEM?

MEM already owns accelerator and MMIO access, so it provides one consistent integration point and preserves the standard pipeline structure.

### 21. Why does the custom instruction use the memory-to-register path?

Custom status or ciphertext data is returned through MEM and WB like a lightweight accelerator load. This also makes dependency handling conservative.

### 22. Does `CSEC_AES_START` load all 128 plaintext bits?

No. It directly loads two 32-bit operands into the lower 64 bits and clears the upper 64 bits. Full-width data loading still uses MMIO.

### 23. Why keep MMIO after adding custom instructions?

MMIO is complete, modular and portable. It programs every key, plaintext, nonce and counter word. The custom ISA is an additional shortcut and research comparison.

### 24. Is this a complete RV32I processor?

It is an RV32I-style educational pipeline verified for the implemented instruction groups. It does not claim full privileged architecture or compliance certification.

### 25. How are hazards handled?

The hazard unit stalls load-use dependencies, while the forwarding unit selects MEM or WB values for EX operands. Flush signals remove wrong-path instructions after control transfers.

### 26. Why are SYSTEM and FENCE tests passing if full privileged logic is absent?

The current design treats them as supported non-destructive behavior for the directed environment. It does not implement full trap, CSR or memory-ordering machinery.

## D. MMIO and peripherals

### 27. Why use address pages rather than a standard bus?

The small SoC needs only a simple internal interconnect. Page-based decode is synthesizable and easy to verify. AXI or Avalon would be appropriate for a larger system.

### 28. Can two peripherals drive read data together?

No. Address-page decode selects at most one peripheral, and one combinational multiplexer returns the selected value.

### 29. Why add DMA if it transfers only words?

It demonstrates autonomous data movement and creates a clear extension point without introducing a full bus-master protocol.

### 30. Why use UART in an automotive project?

UART is a simple, observable prototype output. Production would replace it with CAN-FD or Automotive Ethernet.

### 31. What does the baud divisor mean?

One UART bit lasts `baud_div + 1` clock cycles. At 50 MHz, a divisor near 433 gives approximately 115200 baud.

### 32. Why is the interrupt controller needed?

It stores short AES, UART, sensor and DMA events in sticky pending bits and provides one enabled combined event line.

### 33. Does the CPU execute a real interrupt service routine?

Not yet. Full CSR and trap handling is future work, so the current IRQ is verified as an event and debug output.

### 34. Does sleep stop the CPU clock?

No. The current sleep request holds selected peripherals through clock enables and counts sleep cycles. Full CPU halt and wake-up are future work.

### 35. Do activity counters measure power?

No. They measure active clock cycles. Power still requires activity, voltage, capacitance and tool or physical analysis.

## E. Verification

### 36. Why use both directed and UVM tests?

Directed tests prove exact instruction and register behavior. UVM explores randomized data and checks end-to-end results against an independent model.

### 37. Why is the C model independent?

It computes AES-CTR outside the SystemVerilog RTL implementation. Agreement reduces the chance that the same RTL error exists in both expected and observed paths.

### 38. What does the UART monitor add?

It reconstructs bytes from the serial TX line rather than trusting an internal transmit register, so it verifies framing and the physical RTL output path.

### 39. Is UVM testing the full processor?

No. It deeply verifies AES-MMIO plus UART. Complete CPU participation is covered by directed and Full-SoC tests.

### 40. Why are there 25 and 100 transaction results?

The 25-transaction regression demonstrates repeated end-to-end matches and reaches 96/114 bins. The separate 100-transaction run closes all 114 bins.

### 41. Is the coverage native SystemVerilog covergroup coverage?

No. It is an equivalent portable collector because the Starter Edition lacks the required covergroup license feature.

### 42. How do you know the random test is repeatable?

The seed is recorded. The same seed reproduces the same randomized sequence.

### 43. What does 107 PASS mean?

It is the combined integrated directed regression. It is separate from UVM match counts and coverage bins.

### 44. Why does the KAT screenshot show zero passes?

The displayed cursor is before the self-check report update. The companion log confirms six passed checks and zero failures.

## F. Synthesis and results

### 45. Which result proves the reusable AES improvement?

The controlled baseline-versus-reusable AES comparison under the same TSMC 55 nm Genus setup.

### 46. Why not compare FPGA ALMs with ASIC cells?

An FPGA ALM and an ASIC standard cell are different resources in different technologies. Direct numerical comparison is invalid.

### 47. Is Quartus power measured power?

No. It is a low-confidence vectorless estimate, not a board measurement.

### 48. Is the Genus schematic a physical layout?

No. It is a technology-mapped synthesis schematic. Placement, routing, clock tree and parasitic extraction are not included.

### 49. Why use HVT cells?

High-threshold cells reduce leakage but are slower. The mapped SoC still meets the 50 MHz synthesis constraint at the reported corner.

### 50. Why are there no noise spikes in the waveform?

RTL simulation models digital logic values. Analog noise, supply droop, glitches below simulation resolution and electromagnetic effects require gate-level, mixed-signal or physical analysis.

---

# 14. Ten Additional Hostile Questions

## 51. Your power reduction is very large. Is it believable?

The percentage belongs only to the controlled standalone AES comparison. The baseline is a much larger architecture, while the proposed design is strongly serialized. The result should not be generalized to the full SoC or another technology.

## 52. Could synthesis have optimized away logic and made the comparison unfair?

Both standalone architectures must be synthesized under the same constraints and library, with functional outputs and required hierarchy retained. The retained reports and functional verification support the comparison, but a final publication should document identical constraints clearly.

## 53. Why does the FPGA use zero block RAM?

The current behavioral memory structures and verification-oriented access patterns were implemented in logic. A production FPGA version should restructure memories for block-RAM inference.

## 54. Why are there 106 pins?

Wide debug outputs preserve internal observability for the thesis build. A real board top-level would expose only required interfaces and use internal debugging tools.

## 55. Could an attacker change CTR ciphertext predictably?

Yes. That is why CTR alone is not sufficient for production. A MAC or authenticated mode is required.

## 56. What happens if software starts AES while busy?

The wrapper accepts start only when `busy_reg` is zero. A second start is rejected until the current transaction completes.

## 57. What happens to the counter after CTR completion?

The wrapper increments the 64-bit counter automatically after a completed block.

## 58. Is the custom ISA standard RISC-V crypto?

No. It uses the reserved custom-0 opcode for a project-specific security extension. It is not the standardized RISC-V cryptography extension.

## 59. What is the biggest current technical weakness?

Security is confidentiality-only, key storage is register based and the CPU lacks full trap/wake support. These are more important limitations than adding another performance feature.

## 60. If you had one month more, what would you implement first?

Authenticated encryption with disciplined nonce management and secure key storage, followed by CSR/trap support and an automotive communication interface.

---

# 15. Whiteboard Diagrams to Practice

Draw each in less than 60 seconds.

## Diagram 1: System

```text
Sensor/SPI -> RISC-V -> AES-CTR -> UART -> Gateway
                 |        |          |
                DMA     INTC       activity
                          |
                        power
```

## Diagram 2: Pipeline

```text
IF -> ID -> EX -> MEM -> WB
       |      |      |
     decode  ALU   RAM/MMIO
```

## Diagram 3: 32 to 128 bits

```text
PT3 | PT2 | PT1 | PT0 = one 128-bit plaintext
```

## Diagram 4: CTR

```text
nonce || counter -> AES(key) -> keystream
plaintext XOR keystream -> ciphertext
```

## Diagram 5: UVM

```text
sequence -> driver -> DUT -> UART monitor -> scoreboard
              |                         ^
              +---- C-DPI reference ----+
```

## Diagram 6: Result domains

```text
AES-only Genus -> reuse benefit
Quartus SoC    -> FPGA fit/timing
Genus HVT SoC -> standard-cell mapping
```

---

# 16. Full Presentation Rehearsal Rubric

After recording yourself, score each item from zero to two.

| Item | 0 | 1 | 2 |
|---|---|---|---|
| Opening | Confused | Understandable | Clear purpose and contribution |
| Slide flow | Reads slides | Some transitions | Natural story |
| AES explanation | Incorrect | Basic | Correct rounds, reuse and CTR |
| CPU integration | Vague | Names stages | Explains MEM/MMIO/custom path |
| Verification | Lists tests | Some scope | Correct scope and evidence |
| Waveforms | Reads colors | Names signals | Trigger-progress-result explanation |
| Netlists | Calls it layout | Basic structure | States proof and limitation |
| Results | Mixes domains | Mostly correct | Exact and separated |
| Limitations | Avoids them | Mentions one | Honest production gap |
| Timing | Over 35 min | 30-35 min | 27-30 min plus questions |

Target score: at least 17 out of 20.

---

# 17. Statements You Must Never Make

Do not say:

```text
The current AES completes in 40 cycles.
The UVM test executes the full CPU pipeline.
CTR provides integrity.
The key comes from the sensor.
The sleep signal completely stops the CPU.
The interrupt controller already executes a trap handler.
The Quartus power is measured board power.
The Genus schematic is a physical layout.
The 100-transaction result is visible in the one-transaction waveform.
FPGA ALMs and ASIC cells can be directly compared.
The design is automotive certified.
```

Use these corrected statements:

```text
The current primitive latency is 295 measured simulation cycles.
UVM checks AES-MMIO plus UART; Full-SoC checks CPU integration.
CTR provides confidentiality; authentication is future work.
The sensor supplies readings; trusted software supplies security parameters.
Sleep currently controls selected peripheral activity.
IRQ pending behavior is implemented; CSR/trap handling is future work.
Power values are tool estimates with stated confidence and scope.
The Genus image is a mapped synthesis schematic.
Coverage closure is proven by the 100-transaction evidence.
Each technology result is interpreted only within its own domain.
This is an RTL/FPGA proof of concept.
```

---

# 18. Final 20-Minute Night Review

Do only these items:

1. Say the 90-second opening.
2. Draw the system and pipeline.
3. Explain CTR.
4. Explain how four 32-bit words form one AES block.
5. Explain one AES waveform.
6. Explain the MEM-stage netlist.
7. Recite the verification result table.
8. Recite the three synthesis domains.
9. State five limitations.
10. Say the conclusion in one minute.

Then stop.

---

# 19. Presentation-Day Folder Checklist

Keep these locally available:

```text
Formal white PPT
PDF export of PPT
Easy-English speaker script
Thesis PDF
Result audit
AES KAT waveform screenshot and log
Full-SoC waveform screenshots and log
Quartus netlist image
MEM and EX netlist images
Genus mapped schematic
Quartus and Genus result reports
```

Do not perform a long Quartus or Genus compile immediately before the defense unless specifically asked. Use retained reports and rerun only the short Questa demonstration if needed.

---

# 20. Emergency Answers When You Do Not Know

Do not guess. Use one of these forms:

> That behavior is outside the current prototype. The implemented part is ..., and the correct next step would be ...

> I have not measured that physically. The value in the report is a vectorless synthesis estimate under the stated tool conditions.

> I would separate those results because they use different technologies and design scopes.

> The waveform proves the digital RTL behavior. Analog noise and silicon-level effects require a different analysis stage.

> I would verify that detail from the source report rather than giving an uncertain number.

An honest scoped answer is stronger than a confident incorrect answer.

---

# Final Readiness Test

You are ready when you can do all of the following without opening the report:

- Explain the project in 90 seconds.
- Draw the full architecture.
- Explain every pipeline stage.
- Explain AES rounds, reuse and CTR.
- Explain 32-bit to 128-bit packing.
- Explain MMIO and custom ISA paths.
- Explain why UART, DMA, INTC and power blocks exist.
- Explain directed, UVM, C-model, coverage and Full-SoC verification.
- Read one waveform from trigger to PASS.
- Explain Quartus and Genus netlists without calling them layouts.
- Recite the essential result numbers.
- State security and implementation limitations clearly.
- Complete the presentation in 27-30 minutes.

The aim is not to know every line. The aim is to know exactly where each claim comes from and what evidence supports it.
