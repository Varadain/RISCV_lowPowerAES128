# Thesis Contribution

## Proposed Title

Lightweight Low-Power RISC-V IoT Security Processor with AES-CTR Acceleration and MMIO Peripheral Integration

## Core Contribution

This work converts a simple pipelined RV32I-style processor into a compact IoT security SoC. The design demonstrates how a small embedded processor can securely collect sensor data, encrypt it in hardware, and transmit encrypted data through a communication peripheral.

## Technical Contributions

- A modular 5-stage RISC-V processor with hazard handling and forwarding.
- A low-power iterative AES-128 accelerator reused as a cryptographic primitive.
- AES-CTR support through an MMIO wrapper without breaking AES-ECB compatibility.
- A memory-mapped sensor interface suitable for replacement by SPI or I2C.
- A UART transmit peripheral for encrypted data output.
- A simple interrupt controller for peripheral event aggregation.
- A DMA-lite memory-copy engine for low-overhead data movement experiments.
- Clock-enable based low-power control, avoiding unsafe clock gating.
- Activity counters for thesis-level power and duty-cycle analysis.
- FPGA-observable debug outputs to prevent synthesis from optimizing away the SoC.
- Directed verification covering CPU, crypto, MMIO, interrupt, DMA, UART, and power features.

## Research Value

The architecture is intentionally lightweight and modular. It is suitable for comparing software-only encryption against hardware-accelerated AES, studying peripheral-driven IoT security flows, and measuring activity reduction through idle/sleep behavior.

## Possible Evaluation Metrics

- AES encryption latency in cycles.
- CPU cycles saved by AES hardware versus software AES.
- UART throughput for encrypted blocks.
- DMA copy latency versus CPU copy loops.
- Active versus sleep cycle ratio.
- FPGA resource utilization with debug outputs enabled.
- Energy/security tradeoff for sensor-to-UART encrypted transmission.
