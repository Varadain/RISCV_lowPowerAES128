# Lightweight IoT Security Processor

A compact **RISC-V based IoT security processor** that reads sensor data, encrypts it using a hardware AES accelerator, and sends encrypted output through UART.

Built using:

* 5-stage RV32I-style pipelined processor
* Low-power AES-128 accelerator
* AES-ECB and AES-CTR modes
* Sensor MMIO interface
* Intel Avalon SPI sensor IP
* UART transmitter
* Interrupt controller
* DMA-lite engine
* Power/activity counters

In one line:

> A tiny RISC-V SoC that can sense, encrypt, transmit, and measure activity like a lightweight IoT security node.

---

## Why This Project Exists

Small IoT devices often need encryption, but running AES fully in software costs CPU cycles and power.

This project moves AES into hardware.

Instead of this:

```text
Sensor -> CPU does everything -> slow encrypted output
```

this design does this:

```text
Sensor -> RISC-V control -> AES hardware -> UART encrypted output
```

The CPU controls the system.
The AES hardware does the heavy crypto work.
The UART sends the encrypted data.
The activity counters help measure low-power behavior.

---

## Architecture

```text
+----------------------+
| Sensor MMIO / SPI IP |
+----------+-----------+
           |
           v
+----------------------+
| 5-stage RISC-V CPU   |
| IF ID EX MEM WB      |
+----------+-----------+
           |
           v
+----------------------+
| AES-128 / AES-CTR    |
| MMIO Accelerator     |
+----------+-----------+
           |
           v
+----------------------+
| UART MMIO TX         |
+----------+-----------+
           |
           v
   Encrypted Serial Output
```

---

## Main Features

* 5-stage pipelined RV32I-style processor
* Forwarding, load-use stall, and branch flush support
* Memory-mapped AES-128 hardware accelerator
* AES-ECB mode for compatibility
* AES-CTR mode for sensor-stream encryption
* Sensor MMIO registers for simple testing
* Intel Avalon SPI IP for realistic sensor I/O
* UART transmitter for encrypted output
* Simple interrupt controller
* DMA-lite memory copy engine
* Sleep request and activity counters
* FPGA-visible debug outputs
* Questa simulation verified

---

## Pipeline

The processor uses the classic five-stage pipeline:

```text
IF -> ID -> EX -> MEM -> WB
```

New IoT/security features are added around the memory/MMIO path, so the stable CPU pipeline does not need to be rewritten.

---

## Supported Instructions

The design supports many RV32I-style instructions:

```text
ADD, SUB, AND, OR, XOR
SLL, SRL, SRA
SLT, SLTU
ADDI, ANDI, ORI, XORI
SLTI, SLTIU
SLLI, SRLI, SRAI
LB, LH, LW, LBU, LHU
SB, SH, SW
BEQ, BNE, BLT, BGE, BLTU, BGEU
LUI, AUIPC
JAL, JALR
NOP, MV, LI, J
ECALL, EBREAK, FENCE, FENCE.I
```

---

## AES Accelerator

The AES core is implemented in:

```text
aes128_lowpower.sv
```

It supports AES-128 encryption using an iterative low-power architecture.

AES flow:

```text
Initial AddRoundKey
Rounds 1-9: SubBytes -> ShiftRows -> MixColumns -> AddRoundKey
Final Round: SubBytes -> ShiftRows -> AddRoundKey
```

The AES block is controlled by software through normal RISC-V load/store instructions.

---

## AES Modes

### AES-ECB

AES-ECB is used for basic block encryption and NIST test-vector compatibility.

### AES-CTR

AES-CTR is used for IoT sensor-stream encryption.

```text
ciphertext = plaintext XOR AES_encrypt(nonce || counter)
```

CTR mode uses:

```text
64-bit nonce + 64-bit counter
```

The counter auto-increments after each block.

---

## Memory Map

| Address       | Peripheral              |
| ------------- | ----------------------- |
| `0x0000_0300` | AES / AES-CTR           |
| `0x0000_0400` | Sensor MMIO / SPI       |
| `0x0000_0500` | UART                    |
| `0x0000_0600` | Interrupt controller    |
| `0x0000_0700` | DMA-lite                |
| `0x0000_0800` | Power/activity counters |

---

## AES Register Map

| Offset          | Register                    | Description                 |
| --------------- | --------------------------- | --------------------------- |
| `0x00`          | `AES_CTRL`                  | Start, clear done, CTR mode |
| `0x04`          | `AES_STATUS`                | Busy, done, mode status     |
| `0x08` - `0x14` | `AES_KEY0` - `AES_KEY3`     | 128-bit key                 |
| `0x18` - `0x24` | `AES_PT0` - `AES_PT3`       | Plaintext                   |
| `0x28` - `0x34` | `AES_CT0` - `AES_CT3`       | Ciphertext                  |
| `0x38` - `0x3C` | `AES_NONCE0` - `AES_NONCE1` | 64-bit nonce                |
| `0x40` - `0x44` | `AES_COUNT0` - `AES_COUNT1` | 64-bit counter              |

---

## Sensor / SPI Registers

Base address:

```text
0x0000_0400
```

Provides:

* Sensor data register
* Sensor status register
* Sensor control register
* SPI RX/TX register access
* SPI status/control access
* SPI slave-select access

---

## UART Registers

Base address:

```text
0x0000_0500
```

Provides:

* TX data register
* TX status register
* UART control register
* Baud divisor register

UART mode:

```text
8 data bits, no parity, 1 stop bit
```

---

## Interrupt Controller

Base address:

```text
0x0000_0600
```

Interrupt sources:

| Bit | Source       |
| --- | ------------ |
| 0   | AES done     |
| 1   | UART done    |
| 2   | Sensor ready |
| 3   | DMA done     |

Registers:

* `IRQ_PENDING`
* `IRQ_ENABLE`
* `IRQ_CLEAR`

---

## DMA-lite

Base address:

```text
0x0000_0700
```

Used for simple internal word-copy experiments.

Registers:

* Source address
* Destination address
* Length
* Control
* Status

---

## Power / Activity Counters

Base address:

```text
0x0000_0800
```

Counters:

* CPU active cycles
* AES active cycles
* UART active cycles
* DMA active cycles
* Sensor active cycles
* Sleep cycles

These counters help compare active and idle behavior for low-power analysis.

---

## Important RTL Files

| File                        | Purpose                |
| --------------------------- | ---------------------- |
| `riscv_aes_advancements.sv` | Top-level SoC          |
| `pc_reg.sv`                 | Program counter        |
| `if_stage.sv`               | Instruction fetch      |
| `id_stage.sv`               | Instruction decode     |
| `ex_stage.sv`               | Execute stage          |
| `mem_stage.sv`              | Memory and MMIO access |
| `wb_stage.sv`               | Writeback              |
| `reg_file.sv`               | Register file          |
| `alu.sv`                    | ALU                    |
| `control_unit.sv`           | Control logic          |
| `hazard_unit.sv`            | Load-use stall logic   |
| `forwarding_unit.sv`        | Forwarding logic       |
| `data_mem.sv`               | Data memory            |
| `instr_mem.sv`              | Instruction memory     |
| `aes128_lowpower.sv`        | AES primitive          |
| `aes_mmio.sv`               | AES MMIO wrapper       |
| `sensor_mmio.sv`            | Simple sensor MMIO     |
| `sensor_spi_mmio.sv`        | Sensor + SPI wrapper   |
| `uart_tx.sv`                | UART transmitter       |
| `uart_mmio.sv`              | UART MMIO wrapper      |
| `simple_intc.sv`            | Interrupt controller   |
| `dma_lite.sv`               | DMA-lite engine        |
| `power_mgmt_mmio.sv`        | Power/activity block   |
| `riscv_core_tb.sv`          | Testbench              |

---

## Verification Result

Simulation tool:

```text
Questa Intel Starter FPGA Edition 2023.3
```

Final result:

```text
RV32I-style directed verification summary: PASS=77 FAIL=0
Lightweight IoT Security Processor verification summary: PASS=77 FAIL=0

ALL TESTS PASSED
Errors: 0
Warnings: 1
```

The single warning is from using `+acc` for waveform visibility:

```text
Some optimizations are turned off because the +acc switch is in effect.
```

That warning is expected and does not indicate a design failure.

---

## Verified Blocks

The testbench verifies:

* R-type instructions
* I-type instructions
* Load/store instructions
* Branch instructions
* Jump instructions
* U-type instructions
* System/fence/pseudo behavior
* Pipeline stall signal
* Pipeline flush signal
* AES MMIO read/write/select
* AES-128 ECB
* AES-CTR
* CTR counter auto-increment
* Sensor MMIO
* Intel SPI IP clock/select activity
* UART MMIO transmit
* Interrupt pending and combined IRQ
* DMA-lite copy
* Sleep control
* Activity debug output

---

## AES Test Vector

The AES-128 test uses the standard NIST vector:

```text
Key        = 000102030405060708090A0B0C0D0E0F
Plaintext  = 00112233445566778899AABBCCDDEEFF
Ciphertext = 69C4E0D86A7B0430D8CDB78070B4C55A
```

The design output:

```text
CT0 = 70B4C55A
CT1 = D8CDB780
CT2 = 6A7B0430
CT3 = 69C4E0D8
```

Combined:

```text
69C4E0D86A7B0430D8CDB78070B4C55A
```

Result:

```text
PASS
```

---

## AES-CTR Test

CTR mode was tested using zero plaintext.

Since:

```text
ciphertext = 0 XOR AES_encrypt(nonce || counter)
```

the ciphertext should match the AES keystream.

Result:

```text
CT0 = 70B4C55A
CT1 = D8CDB780
CT2 = 6A7B0430
CT3 = 69C4E0D8
Counter auto-increment = PASS
```

---

## Example IoT Demo Flow

A simple firmware/demo program can do this:

```text
1. Configure UART
2. Enable sensor
3. Read sensor sample
4. Load AES key
5. Load nonce and counter
6. Start AES-CTR encryption
7. Wait for AES done
8. Read ciphertext
9. Send ciphertext through UART
10. Enter sleep
11. Read activity counters
```

In short:

```text
sense -> encrypt -> transmit -> sleep -> measure
```

---

## Why It Is Useful

This project is useful for studying:

* Hardware AES vs software AES
* Low-power IoT encryption
* RISC-V based secure embedded design
* MMIO peripheral integration
* AES-CTR streaming encryption
* Sensor-to-UART encrypted data flow
* Activity-counter based power analysis
* FPGA resource usage

---

## FPGA Note

If the top-level exposes only:

```text
clk
rst_n
```

Quartus may optimize away most of the design.

To avoid that, this design exposes debug outputs such as:

* Current PC
* AES done
* AES ciphertext
* UART TX
* SPI clock
* SPI MOSI
* SPI slave select
* IRQ debug
* Sleep debug
* Activity counter debug

So the FPGA tools can actually see useful logic.

Because invisible hardware tends to disappear.

---

## Thesis Title

Suggested title:

```text
Lightweight Low-Power RISC-V IoT Security Processor with AES-CTR Acceleration and MMIO Peripheral Integration
```

Shorter version:

```text
Lightweight RISC-V IoT Security Processor with Hardware AES-CTR Encryption
```

---

## Project Contribution

This work converts a basic RISC-V processor with AES into a small IoT security SoC.

Main contributions:

* Processor + AES hardware integration
* AES-CTR support for streaming encryption
* Sensor and SPI input path
* UART encrypted output path
* Interrupt/event aggregation
* DMA-lite data movement
* Activity counters for low-power study
* Verified processor and peripheral behavior
* FPGA-observable top-level outputs

---

## Comparison With Older Approaches

| Approach            | Problem              | This Project            |
| ------------------- | -------------------- | ----------------------- |
| Software AES on MCU | Uses many CPU cycles | AES runs in hardware    |
| Standalone AES core | Not a full system    | Integrated with RISC-V  |
| Basic RISC-V + AES  | Only crypto demo     | Full IoT data path      |
| Vendor MCU crypto   | Less modifiable      | Open RTL design         |
| Large SoC           | More complex         | Lightweight and focused |

---

## Current Limitations

This is a research processor, not a production security chip.

Current limitations:

* AES gives confidentiality, not full authentication
* No SHA/HMAC block yet
* No secure key storage yet
* No side-channel protection yet
* DMA-lite is simple by design
* UART is transmit-focused

These are good future-work directions.

---

## Future Work

Possible upgrades:

* SHA-256 accelerator
* HMAC support
* AES-GCM mode
* Secure boot
* Key zeroization
* Write-only key registers
* OTP/eFuse/PUF key storage
* I2C sensor interface
* AXI4-Lite wrapper
* CSR-based interrupt handling
* Side-channel countermeasures
* FPGA board demo with real sensor

---

## Final Status

```text
Processor:        Working
AES-ECB:          Working
AES-CTR:          Working
Sensor MMIO:      Working
SPI IP Activity:  Working
UART TX:          Working
Interrupt block:  Working
DMA-lite:         Working
Power counters:   Working
Verification:     PASS=77 FAIL=0
```

---

## One-Line Summary

A verified 5-stage RV32I-style RISC-V processor with low-power AES-128 ECB/CTR acceleration, sensor/SPI input, UART encrypted output, DMA-lite, interrupt aggregation, and activity counters for lightweight IoT security research.
