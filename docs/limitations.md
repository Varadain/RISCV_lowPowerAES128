# What this prototype does not establish

[Home](../README.md) · [Verification](04-verification.md) · [Results](05-results.md)

These boundaries are useful when reading the papers, presenting the project or adapting the code.

## Security

AES-CTR encrypts data but does not authenticate it. There is no integrated authentication tag, replay defence, protected nonce persistence or secure key provisioning. Reusing a nonce/counter block under one key exposes relationships between plaintexts. Key registers are software-programmable and are not an isolated secure enclave.

No side-channel resistance, fault-injection resistance, constant-time system behaviour or secure boot claim is established by the functional tests. Test transcripts deliberately show synthetic keys; production diagnostics must not do this.

## Processor and interrupts

The core is RV32I-style, not claimed to be a fully compliant privileged RISC-V implementation. The interrupt controller exposes pending/enabled status and an IRQ line, but the CPU has no complete CSR/trap/ISR path. The project-specific custom-0 commands are not standardized scalar cryptography instructions.

The simulation ROM is writable by the testbench. The synthesis ROM contains a small fixed example, not the complete simulated secure-sensor application. There is no supplied operating system or deployable firmware toolchain.

## Memory and peripherals

RAM is small, aliased and unprotected. DMA uses a direct second RAM port, not a general interconnect; software must avoid conflicts and invalid destinations. The SPI wrapper includes synthetic sensor behaviour. UART is a simple transmitter, not a qualified automotive or network security interface.

Sleep controls selected peripheral updates, not a verified system-wide clock/power-gating and interrupt-wake scheme. Do not sleep an unfinished transaction and assume it remains functional.

## Evidence

Known-answer tests and finite regressions check selected behaviour. 114/114 bins refers to one portable coverage model. The UVM top does not contain the full processor.

The ASIC reports are pre-layout mapped estimates. FPGA reports are from an archived fit with its recorded device and constraints. Neither is a measured energy-per-transaction experiment. Baseline comparison reports and complete-SoC ASIC reports are not included in this snapshot.

Useful future work would add authenticated encryption, nonce/key lifecycle management, broader ISA and formal checks, reset/concurrency tests, a complete interrupt path, activity-based power analysis and a board-specific constrained hardware demonstration. Those are future directions, not features silently implied by the current project.
