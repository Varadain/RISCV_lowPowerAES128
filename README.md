# RISC-V RV32I Core with Low-Power AES Integration

## Overview
This project implements a 32-bit RISC-V (RV32I) pipelined processor with an integrated low-power AES-128 hardware accelerator. The design is written in Verilog and verified using Verilator.

It combines:
- A standard RISC-V CPU core
- A hardware AES encryption engine
- A memory-mapped interface (MMIO) for CPU–AES communication

This can be viewed as a small CPU with a built-in encryption co-processor optimized for low power.

---

## High-Level Architecture

          +----------------------+
          |   RISC-V CPU Core    |
          | (5-stage pipeline)   |
          +----------+-----------+
                     |
                     | Memory-Mapped Interface (MMIO)
                     |
      +--------------v--------------+
      |     AES-128 Accelerator     |
      |    (Low-Power Design)      |
      +--------------+--------------+
                     |
              +------v------+
              |   Memory    |
              | (Instr/Data)|
              +-------------+

### Description
- The CPU executes instructions normally
- AES is accessed through memory-mapped registers
- Encryption is offloaded to dedicated hardware
- Results are read back by the CPU

---

## Pipeline Architecture

The processor uses a standard 5-stage pipeline:


[IF] → [ID] → [EX] → [MEM] → [WB]


| Stage | Description |
|------|-------------|
| IF   | Instruction Fetch |
| ID   | Decode + Register Read |
| EX   | Execute (ALU operations) |
| MEM  | Memory access |
| WB   | Write result back |

### Key Idea
Multiple instructions are processed in parallel, each in a different stage.

---

## Pipeline Stall (Hazard Handling)

A pipeline stall occurs when an instruction depends on a result that is not yet available.

Example:

lw x1, 0(x0)
add x2, x1, x1


- `add` depends on `lw`
- `lw` has not completed
- Pipeline inserts a stall cycle

### Observable Behavior
- Program counter (PC) stops advancing temporarily
- Pipeline registers hold values
- Ensures correct execution

---

## AES Accelerator

AES is a standard encryption algorithm. Instead of software implementation, this design uses a hardware AES module.

Advantages:
- Faster execution
- Lower power consumption (due to reduced switching activity)

---

## MMIO Interface (CPU ↔ AES)

The CPU interacts with AES using memory-mapped registers.

### Flow

CPU:
Write KEY
Write PLAINTEXT
Set START = 1

AES:
Processes data
Sets DONE = 1

CPU:
Reads CIPHERTEXT


### Control Signals
- `start` : begin encryption  
- `busy`  : AES is processing  
- `done`  : encryption complete  

---

## Low-Power Design Strategy

Power consumption in digital circuits is largely due to signal switching.

This design reduces power by:
- Activating AES only when required
- Avoiding unnecessary toggling
- Using enable-controlled logic instead of always-active blocks

---

## Repository Structure


rtl/ → Processor and AES RTL (Verilog)
testbench/ → Simulation environment and directed tests
results/ → Simulation logs and waveform outputs


---

## Verification

### Tool
- Verilator

### Coverage
- Full RV32I instruction set
- Load/store operations
- Branch instructions
- System instructions
- AES-128 (NIST test vectors)

### Results

PASS = 53
FAIL = 0


Detailed simulation log is available in the `results/` directory.

---


### Key Signals to Observe
- Program Counter (PC)
- Pipeline stage registers
- Register write-back
- AES control signals (`start`, `busy`, `done`)

---

## Key Highlights

- RV32I pipelined processor
- Low-power AES-128 integration
- MMIO-based hardware interface
- Directed verification (53/53 tests passed)
- Waveform-based validation
---

## Summary

This project demonstrates:
- Integration of a hardware accelerator with a CPU
- Efficient pipeline-based execution
- Practical low-power design techniques
- Complete functional verification
