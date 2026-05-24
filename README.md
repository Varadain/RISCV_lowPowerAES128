# Lightweight IoT Security Processor with Custom Security ISA

This project implements a lightweight RISC-V based IoT security processor for
FPGA and RTL simulation study. It extends a 5-stage RV32I-style pipelined
processor with an AES-128 hardware accelerator, AES-CTR mode support, sensor
input registers, UART transmission, an interrupt controller, DMA-lite data
movement, low-power activity counters, and a small custom security instruction
set.

The design target is an IoT edge/security use case:

```text
Sensor input / SPI / MMIO
        ->
5-stage RISC-V processor
        ->
AES-128 ECB / CTR accelerator
        ->
UART transmitter
        ->
Encrypted data output
```

## Main Features

- 5-stage pipelined RV32I-style processor
- AES-128 low-power iterative encryption block
- AES MMIO peripheral with preserved ECB behavior
- AES-CTR mode for encrypted sensor data streams
- UART transmitter peripheral
- Sensor MMIO interface with optional SPI IP wrapper
- Simple interrupt controller
- DMA-lite word transfer engine
- Sleep control and activity counters
- Custom RISC-V security instructions using the `custom-0` opcode
- Quartus project files for Intel FPGA compilation
- Questa simulation flow with waveform visibility
- Python waveform PDF report generator

## Directory Highlights

| Path | Purpose |
| --- | --- |
| `riscv_aes_advancements.sv` | Top-level processor/SoC module |
| `riscv_core_tb.sv` | Directed verification testbench |
| `aes_mmio.sv` | AES ECB/CTR MMIO wrapper |
| `aes128_lowpower.sv` | AES-128 encryption primitive |
| `uart_mmio.sv`, `uart_tx.sv` | UART peripheral |
| `sensor_mmio.sv`, `sensor_spi_mmio.sv` | Sensor/SPI interface |
| `simple_intc.sv` | Interrupt controller |
| `dma_lite.sv` | DMA-lite engine |
| `power_mgmt_mmio.sv` | Sleep and activity counter registers |
| `custom_isa_extension.md` | Custom instruction documentation |
| `memory_map.md` | Full MMIO address map |
| `verification_plan.md` | Verification plan |
| `iot_security_processor_architecture.md` | Architecture explanation |
| `thesis_contribution.md` | Thesis contribution summary |
| `tools/generate_instruction_waveform_pdf.py` | Waveform PDF/HTML generator |

## Memory Map

| Base Address | Peripheral |
| --- | --- |
| `0x0000_0300` | AES / AES-CTR |
| `0x0000_0400` | Sensor MMIO + SPI |
| `0x0000_0500` | UART MMIO |
| `0x0000_0600` | Interrupt controller |
| `0x0000_0700` | DMA-lite |
| `0x0000_0800` | Power/activity control |

See `memory_map.md` for register-level details.

## Custom Security ISA

The custom instructions use the RISC-V `custom-0` opcode:

```text
opcode = 7'b0001011
```

Implemented commands:

| Mnemonic | Function |
| --- | --- |
| `CSEC_XOR` | Custom XOR operation |
| `CSEC_AES_STATUS` | Read AES busy/done/mode status |
| `CSEC_AES_START` | Start AES-CTR operation |
| `CSEC_AES_CT0` | Read ciphertext word 0 |
| `CSEC_AES_CLEAR` | Clear AES done flag |

See `custom_isa_extension.md` and `custom_isa_demo.S` for details.

## Requirements

Tested with:

- Quartus Prime Lite / Standard for FPGA compilation
- Questa Intel FPGA Edition for RTL simulation
- Python 3 for waveform PDF generation
- Microsoft Edge or another Chromium browser for HTML-to-PDF printing

The Python generator does not require a large external package stack.

## Quartus Compile

Open the project:

```text
riscv_aes_advancements.qpf
```

Fast compile / synthesis-oriented check:

```powershell
.\compile_light.ps1
```

Full low-power compile flow:

```powershell
.\compile_full_low_power.ps1
```

The timing constraints are in:

```text
riscv_aes_advancements.sdc
```

## Questa Simulation

Run the automated regression from PowerShell:

```powershell
.\run_questa_regression.ps1
```

Or run the GUI waveform script from Questa Transcript:

```tcl
cd {D:/mtech/sem 4/midesm presetation/riscv_aes_advancements/risc_aes_custom_ISA/simulation/questa}
do riscv_aes_advancements_run_msim_rtl_verilog.do
```

The simulation script compiles with:

```text
+define+SIMULATION
```

This preserves testbench-visible internal simulation objects such as the
instruction ROM hierarchy.

Expected regression result:

```text
ALL TESTS PASSED
PASS=83 FAIL=0
```

## Waveform PDF Report

After running Questa and generating a VCD, create the submission waveform report:

```powershell
python .\tools\generate_instruction_waveform_pdf.py
```

If Python is not on PATH, use the full Python executable path.

Generated files:

```text
reports/waveforms/custom_isa_instruction_waveforms.html
reports/waveforms/custom_isa_instruction_waveforms.pdf
```

The PDF is organized as submission pages:

- R-type instructions
- I-type instructions
- Load/store instructions
- Branch instructions
- U-type and jump instructions
- System/fence/pseudo instructions
- AES-128 ECB MMIO
- AES-CTR mode
- Sensor MMIO
- SPI IP interface
- UART transmitter
- Interrupt controller
- DMA-lite
- Power/activity counters
- Custom security ISA
- Beginner guide for reading waveforms

## Verification Coverage

The directed testbench verifies:

- RV32I-style arithmetic and logical instructions
- Immediate instructions
- Load/store behavior
- Branch and jump behavior
- System/fence/pseudo behavior
- AES-128 ECB NIST-compatible result
- AES-CTR encryption behavior
- Sensor MMIO reads
- SPI wrapper visibility
- UART MMIO write and status behavior
- Interrupt pending/enable/clear behavior
- DMA-lite completion
- Power and activity counters
- Custom security ISA operations

## Thesis Application

This design is suitable for a thesis project on low-power IoT security
processing. It demonstrates how a compact RISC-V processor can offload
cryptographic work to a hardware accelerator, encrypt sensor data using
AES-CTR, transmit encrypted output through a communication interface, and
measure activity for low-power evaluation.

The custom security ISA path also enables comparison between conventional MMIO
accelerator control and custom instruction based accelerator control.

