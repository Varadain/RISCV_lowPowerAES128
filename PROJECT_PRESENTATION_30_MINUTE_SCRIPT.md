# IEEE ISAIA 2026 Oral Presentation Read Aloud Script

## Paper details

**Title:** A Lightweight RISC-V Security Processor with AES-CTR Acceleration and Custom ISA Support for IoT Edge Nodes  
**Authors:** Varada Inamdar and Ashwini Kulkarni  
**Affiliation:** COEP Technological University, Pune, India  
**Target delivery time:** 10 minutes

Read the paragraphs below in order. The slide headings and timings are only for navigation and are not part of the spoken presentation.

---

## Slide 1 - Title  0:00 to 0:35

Good evening, respected session chairs, fellow researchers, and participants. We are Varada Inamdar and Ashwini Kulkarni from COEP Technological University, Pune, India. Today, we present a lightweight RISC-V security processor with AES-CTR acceleration and custom ISA support for IoT edge nodes. The objective is to protect sensor data locally while retaining a familiar embedded processor and software-control model. I will briefly cover the motivation, architecture, encryption data path, custom ISA, verification, and implementation results.

## Slide 2 - Edge-data protection  0:35 to 1:10

IoT nodes often capture data and transmit it immediately. If protection is delayed until the data reaches a gateway or cloud service, sensitive information can remain exposed at the edge. Software-only encryption also adds instruction cycles for block handling, data movement, and control. Our approach moves encryption closer to the sensor interface. Data is acquired through the edge node, protected by the local AES-CTR path, and then made available for secure telemetry.

## Slide 3 - Design objective  1:10 to 1:55

The design has three main elements. First, it retains an RV32I five-stage pipeline with fetch, decode, execute, memory access, and writeback. Second, it adds an iterative AES-128 accelerator operating in CTR mode, which suits a compact edge-device implementation. Third, it provides both memory-mapped registers and a compact custom instruction path for accelerator control. The security and peripheral functions connect at the MEM-stage interconnect, so the main processor pipeline remains stable.

## Slide 4 - Integrated security processor  1:55 to 3:00

This slide shows the integrated security processor. The top lane is the RV32I pipeline. Existing forwarding, load-use stall handling, and branch-flush behavior remain part of the processor control logic. The middle lane is the security path. A custom security instruction reaches the MEM-stage interconnect and drives the AES-128 CTR accelerator. The MMIO register block provides access to control, busy and done status, nonce, counter, and ciphertext data.

The lower lane contains the edge-node services. SPI supports sensor input, UART supports communication, DMA-lite supports data movement, and the activity-control block records system activity. The AES and CTR region begins at address 0x0000_0300, followed by sensor and SPI at 0x0000_0400, UART at 0x0000_0500, interrupts at 0x0000_0600, DMA-lite at 0x0000_0700, and power or activity control at 0x0000_0800.

## Slide 5 - AES-CTR encryption path  3:00 to 4:05

AES-128 uses a 128-bit key. In CTR mode, AES encrypts a counter block instead of encrypting plaintext directly. In this implementation, the counter block is formed from a 64-bit nonce and a 64-bit counter. Encrypting this block generates a 128-bit keystream. The plaintext is combined with that keystream through XOR, producing the ciphertext. When the transaction completes, the controller clears the busy state, asserts the done state, and increments the counter for the next block.

CTR mode supports independent counter blocks and does not require padding, which makes it suitable for stream-like sensor data. The key security requirement is that a nonce-counter value must never repeat with the same AES key.

## Slide 6 - Custom ISA and MMIO control interface  4:05 to 4:55

The custom extension uses the RISC-V custom-0 opcode, binary 0001011, with the funct3 field selecting the requested operation. The implemented security commands are CSEC_AES_START, CSEC_AES_STATUS, CSEC_AES_CT0, and CSEC_AES_CLEAR. The start command launches an AES-CTR transaction. The status command returns the busy, done, and mode bits. The CT0 command returns ciphertext word zero, and the clear command resets the done state.

The AES and CTR register window begins at 0x0000_0300. The custom instruction path reuses the same internal AES MMIO wrapper, so it shortens the control sequence without creating a separate cryptographic datapath.

## Slide 7 - RTL verification sequence  4:55 to 5:55

This waveform shows the AES control transaction. The processor issues a start command, the accelerator enters the busy state, the encryption completes, and the result can then be read or cleared. The directed Questa regression completed with 83 passing checks and no functional failures. It covered RV32I arithmetic, loads and stores, control hazards, AES-128 ECB known-answer testing, AES-CTR counter behavior, SPI, UART, interrupts, DMA-lite, activity counters, and custom security instructions. The observed AES ciphertext words matched the expected known-answer values, and the custom ciphertext read returned the expected result.

## Slide 8 - Implementation flow  5:55 to 6:35

The complete design was described in SystemVerilog RTL. It includes the RISC-V processor, iterative AES-CTR accelerator, custom control logic, and the SPI, UART, interrupt, DMA-lite, and activity-counter blocks. We synthesized the design with Intel Quartus Prime 23.1 for a Cyclone V FPGA target. The analysis-and-synthesis run completed with zero errors and zero warnings. The netlist view provides structural evidence that the processor, AES wrapper, and peripheral subsystem were integrated in the implementation flow.

## Slide 9 - Cyclone V implementation snapshot  6:35 to 7:25

For the Cyclone V analysis-and-synthesis run, the design uses 12,825 estimated ALMs, 10,461 dedicated registers, and 106 pins. The design uses a 20-nanosecond SDC clock constraint, corresponding to a 50 MHz target frequency. The largest resource share is in the MEM-stage security and peripheral subsystem because it contains the interconnect and AES MMIO wrapper. The AES-128 primitive itself accounts for 1,478 estimated ALMs and 389 registers.

These values should be interpreted as technology-mapped RTL resource estimates. They do not yet represent post-fit timing, board-level power, or a full firmware-level latency comparison. Those measurements are planned as the next evaluation stage.

## Slide 10 - System-level contribution  7:25 to 8:15

The contribution is the system-level integration of lightweight processing, local encryption, and explicit software control. The RV32I pipeline remains the compute foundation. The iterative AES-CTR block provides local data protection. The custom instruction path and MMIO registers expose accelerator control to software.

Importantly, the custom instruction does not bypass the verified AES peripheral. It reuses the same AES wrapper through the MEM stage. This keeps MMIO and custom-ISA behavior consistent while reducing the software control sequence for selected operations. The work uses standard AES-128 in CTR mode; the contribution is the processor and accelerator integration.

## Slide 11 - Conclusion and next steps  8:15 to 9:15

To conclude, this work demonstrates a compact RISC-V security processor for IoT edge nodes. It retains a five-stage RV32I core, integrates an iterative AES-128 CTR accelerator, provides MMIO and custom-0 ISA control, and supports SPI, UART, interrupts, DMA-lite, and activity observation. The Questa regression reported 83 passes with no failures, and the Cyclone V synthesis run completed without errors or warnings.

The next steps are post-fit FPGA timing closure, board-level power and throughput measurement, fault-resilience evaluation, and a firmware-level comparison between MMIO and custom-instruction AES control.

## Slide 12 - Questions  9:15 to 10:00

Thank you for your attention. The central message of this work is that lightweight RISC-V processing and local AES-CTR acceleration can be integrated through a clear hardware-software control model for IoT edge nodes. We welcome your questions.

---

## Q and A backup

### Why AES-CTR instead of AES-CBC

CTR mode creates a keystream by encrypting nonce-counter blocks. It supports independent blocks and does not require padding. The nonce-counter value must never repeat under the same AES key.

### What does the custom ISA add

It uses the RISC-V custom-0 opcode to start the accelerator, return status, read ciphertext word zero, and clear the done state. It reuses the verified AES MMIO wrapper, so it reduces control overhead without adding a second cryptographic datapath.

### Do the synthesis values prove power or performance

No. They are analysis-and-synthesis resource estimates under a 20-nanosecond constraint. Post-fit timing, board-level power, and firmware-level latency require separate measurement.

### How are AES keys protected

The work focuses on processor and accelerator integration. A deployed version should add protected key provisioning, secure key storage, access control, and a nonce-counter management policy.

### Is this a new AES algorithm

No. The design uses standard AES-128 in CTR mode. The contribution is its integration with the RV32I core, MEM-stage control path, custom ISA, MMIO interface, and IoT-edge peripherals.

---

## Technical sources

- NIST FIPS 197, Advanced Encryption Standard: https://csrc.nist.gov/pubs/fips/197/final
- RISC-V International: https://riscv.org/
- Project architecture, RTL verification, and synthesis results: authors' implementation and submitted manuscript.
