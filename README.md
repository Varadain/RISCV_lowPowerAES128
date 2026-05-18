# Iterative Low-Power AES-128 Accelerator with DFT Support and Advanced UVM Verification

## Overview

This project presents a **low-power iterative AES-128 hardware accelerator** optimized for FPGA and embedded IoT applications using:

- datapath reuse
- activity-aware sequential architecture
- ASIC-style clock gating
- DFT-aware RTL design
- advanced UVM-based verification
- assertion-based verification
- functional coverage
- low-power verification methodology

The architecture minimizes switching activity by reusing a single AES round datapath across multiple encryption rounds instead of using fully parallel hardware.

The project is implemented using:

- SystemVerilog RTL
- UVM 1.1d
- QuestaSim
- Quartus Prime
- Cadence Genus

---

# Key Features

## RTL Architecture

- Iterative AES-128 encryption engine
- Hardware-reusable datapath
- FSM-controlled round execution
- Sequential AES round processing
- Reduced switching activity
- Low-power architecture
- FPGA-friendly implementation
- ASIC-style clock gating model
- DFT-aware scan support

---

## Low-Power Optimizations

- Clock gating support
- Controlled datapath activation
- Sequential hardware reuse
- Reduced combinational switching
- Runtime toggle monitoring
- Activity-aware encryption flow
- Reduced dynamic power consumption

---

## DFT Features

The design includes RTL-level DFT-aware enhancements for improving controllability and observability.

Implemented DFT features:

- `test_mode`
- `scan_enable`
- `scan_in`
- `scan_out`
- scan-chain mux path
- clock-gating bypass during test mode
- scan-friendly RTL structure

Current DFT verification includes:

- scan mode activation
- gated-clock bypass validation
- scan-enable verification
- scan-path observability checks
- RTL-level scan behavior validation

> Note: Full industrial ATPG signoff using Tessent/Modus/TetraMAX was not performed.  
> The current implementation focuses on RTL-level DFT-aware architecture and verification.

---

# Advanced UVM Verification

The project uses a modular split-file UVM verification environment.

Verification features include:

- dedicated driver, monitor, sequencer, agent, environment
- reference model
- scoreboard-based checking
- assertion-based verification
- functional coverage
- stress testing
- glitch verification
- low-power verification
- DFT-aware verification

---

# Architecture Concept

Instead of implementing:

```text
10 parallel AES round units
```

the proposed architecture reuses:

```text
1 reusable AES round datapath
```

across all AES rounds using FSM-controlled sequential execution.

This approach:

- reduces switching activity
- reduces dynamic power
- reduces logic duplication
- reduces silicon area
- improves resource efficiency

---

# Dynamic Power Principle

Dynamic power in CMOS circuits is:

```math
P_{dyn} = \alpha C_L V^2 f
```

Where:

| Parameter | Description |
|---|---|
| α | Switching activity |
| C_L | Load capacitance |
| V | Supply voltage |
| f | Clock frequency |

The proposed architecture minimizes:

```text
switching activity (α)
```

using iterative datapath reuse and selective hardware activation.

---

# AES Encryption Flow

```text
Plaintext
    ↓
AddRoundKey
    ↓
Rounds 1–9:
    SubBytes
    ShiftRows
    MixColumns
    AddRoundKey
    ↓
Final Round:
    SubBytes
    ShiftRows
    AddRoundKey
    ↓
Ciphertext
```

---

# Project Directory Structure

```text
AES128_lowPower/
│
├── AES128_lowPower.sv
├── aes_sbox.sv
├── sub_bytes.sv
├── shift_rows.sv
├── mix_columns.sv
├── key_expand.sv
│
├── uvm_tb/
│   ├── agent/
│   ├── assertions/
│   ├── coverage/
│   ├── driver/
│   ├── env/
│   ├── interfaces/
│   ├── logs/
│   ├── monitor/
│   ├── power_monitor/
│   ├── reference_model/
│   ├── scoreboard/
│   ├── scripts/
│   ├── seq_items/
│   ├── sequences/
│   ├── tests/
│   ├── aes_tb_top.sv
│   └── aes_uvm_pkg.sv
│
└── simulation/
```

---

# UVM Verification Architecture

```text
                +----------------+
                |     TEST       |
                +----------------+
                         |
                         v
                +----------------+
                |      ENV       |
                +----------------+
                   /          \
                  v            v
         +---------------+ +---------------+
         |     AGENT     | |  SCOREBOARD   |
         +---------------+ +---------------+
              /     \
             v       v
      +-----------+ +-----------+
      |  DRIVER   | |  MONITOR  |
      +-----------+ +-----------+
             |
             v
      +----------------+
      |    AES DUT     |
      +----------------+
```

---

# Verification Features

## Functional Verification

- AES encryption correctness
- NIST AES-128 test vector validation
- FSM integrity verification
- Ciphertext correctness checks
- Round-transition verification

---

## Clock Gating Verification

Dedicated tests validate:

- glitch detection
- double pulse detection
- missing pulse detection
- gated-clock correctness
- idle-to-active recovery
- reset collision behavior
- illegal enable timing
- metastability-like behavior

---

## DFT Verification

Implemented RTL-level DFT validation includes:

- scan enable verification
- test mode verification
- scan bypass verification
- scan-path validation
- gated-clock bypass validation

---

## Assertion-Based Verification

Assertions verify:

- no illegal clock pulse
- no glitch propagation
- valid FSM transitions
- proper reset behavior
- valid ciphertext timing
- final-round correctness
- gated-clock behavior

---

# Implemented UVM Tests

| Test Name | Description |
|---|---|
| aes_base_test | Basic AES functionality |
| aes_power_test | Low-power validation |
| aes_glitch_test | Clock-gating verification |
| aes_scan_test | DFT and scan-mode validation |
| aes_stress_test | Randomized stress verification |

---

# Example Verification Dashboard

```text
=========================================================
AES LOW POWER VERIFICATION DASHBOARD
=========================================================

Total Transactions         : 8
Passed Transactions        : 8
Failed Transactions        : 0

Ciphertext Integrity       : PASS
FSM Integrity Status       : PASS

Glitch Events              : 0
Double Pulse Events        : 0
Missing Pulse Events       : 0

Clock Gating Status        : PASS
Assertion Status           : PASS

Average Latency            : 12.5 cycles
Throughput                 : 1.024 Gbps

=========================================================
```

---

# Power Analysis Summary

| Metric | Baseline AES | Proposed AES |
|---|---|---|
| Leakage Power | 6.99e−6 W | 4.52e−7 W |
| Internal Power | 1.29e−2 W | 6.97e−4 W |
| Switching Power | 8.97e−3 W | 1.56e−4 W |
| Total Power | 2.19e−2 W | 8.53e−4 W |

---

# Area Analysis Summary

| Metric | Baseline AES | Proposed AES |
|---|---|---|
| Total Cell Count | 83,352 | 2,694 |
| Total Area | 202,949.64 µm² | 11,841.48 µm² |

---

# Timing Results

| Timing Metric | Result |
|---|---|
| Clock Period | 10 ns |
| Critical Path Delay | 3.36 ns |
| Worst Negative Slack | +6.47 ns |
| Timing Status | MET |

---

# Simulation Tools

## RTL Simulation

- QuestaSim Intel FPGA Edition
- ModelSim

---

## Synthesis

- Cadence Genus

---

## FPGA Flow

- Intel Quartus Prime

---

# Running Simulation

## Compile and Run Advanced UVM Regression

```tcl
cd uvm_tb/scripts
do compile_advanced.do
```

---

## Run Specific UVM Test

```tcl
vsim work.aes_tb_top +UVM_TESTNAME=aes_stress_test
run -all
```

---

# Waveform Debug Signals

The waveform environment includes:

- gated clock
- scan mode
- FSM state
- round counter
- plaintext
- ciphertext
- round keys
- toggle counters
- assertion counters
- glitch counters

---

# Security Discussion

The architecture reduces simultaneous switching activity using iterative datapath reuse and controlled hardware activation.

This may help stabilize instantaneous power behavior and reduce side-channel leakage characteristics compared to fully parallel AES architectures.

---

# Current Status

## Completed

- RTL implementation
- Iterative AES architecture
- Hardware reuse
- Low-power optimization
- Clock gating
- DFT-aware RTL support
- Split-file UVM environment
- Assertions
- Functional coverage
- Stress testing
- Glitch verification
- FPGA synthesis
- Timing analysis

---

## Ongoing Work

- Enhanced DFT verification closure
- Scan-chain integrity automation
- Coverage closure improvement
- Runtime toggle analysis refinement

---

## Future Work

- RISC-V custom instruction integration
- AXI4-Lite interface
- UPF-based power intent
- Side-channel leakage evaluation
- CDC verification
- Formal verification
- FPGA hardware deployment

---

# Research Contribution

The key contribution of this work is:

> architectural-level switching activity reduction through iterative datapath reuse instead of localized block-level optimization.

The proposed architecture demonstrates that:

- sequential datapath reuse
- controlled hardware activation
- activity-aware design

can significantly improve:

- power efficiency
- silicon area
- embedded hardware suitability

while maintaining AES-128 functional correctness.
- low-power verification study
- cryptographic hardware education
- UVM methodology learning
