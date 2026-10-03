# IEEE ISAIA 2026 Oral Presentation Speaker Script

## Paper details

**Title:** A Lightweight RISC-V Security Processor with AES-CTR Acceleration and Custom ISA Support for IoT Edge Nodes  
**Authors:** Varada Inamdar and Ashwini Kulkarni  
**Affiliation:** COEP Technological University, Pune, India  
**Presentation format:** 10-minute oral presentation followed by 2 minutes for questions

This is a descriptive, speak-aloud script. Speak naturally rather than reading every word exactly. The timing leaves a small buffer before questions.

---

## Slide 1 - Title

**Time: 0:00 to 0:35**

Good evening, respected session chairs, fellow researchers, and participants. We are Varada Inamdar and Ashwini Kulkarni from COEP Technological University, Pune, India.

Today, we are presenting our work titled *A Lightweight RISC-V Security Processor with AES-CTR Acceleration and Custom ISA Support for IoT Edge Nodes*.

The main idea of this work is to protect IoT data close to where it is generated. We integrate AES-CTR encryption with a lightweight RISC-V processor and provide a small custom instruction and register interface for software control.

During this presentation, I will explain the motivation, the processor architecture, the AES-CTR data path, the verification approach, and the FPGA implementation results.

**Transition:** Let us first look at why protection at the edge is important.

---

## Slide 2 - Edge-data protection

**Time: 0:35 to 1:15**

IoT nodes often collect data in places where transmission happens immediately after sensing. If protection is delayed until the data reaches a gateway, cloud server, or larger processor, the data may remain exposed at the edge. Software-only encryption also consumes instruction cycles for data movement and control.

Our approach is to bring the encryption path closer to the source of the data. The sensor data enters the edge node, the processor controls encryption locally, and protected telemetry can then be transmitted through the available communication interface.

**Point to the flow:** raw sensor data, local encryption, then protected telemetry.

**Transition:** The design therefore makes three focused architectural choices.

---

## Slide 3 - Design objective

**Time: 1:15 to 2:00**

The first decision was to retain a familiar RV32I five-stage processor core. This gives the design a conventional instruction-processing structure with fetch, decode, execute, memory access, and writeback stages.

The second decision was to include an AES-128 accelerator operating in CTR mode. Rather than moving all encryption work into software, the processor can control a dedicated hardware block for the cryptographic operation.

The third decision was to expose the security path through a compact custom ISA and memory-mapped control interface. This means that software can explicitly start an operation, observe its status, read the result, and clear the interface when the transaction completes.

These choices add security support without replacing the embedded programming model.

**Transition:** The next slide shows how these elements connect in the complete system.

---

## Slide 4 - Integrated security processor

**Time: 2:00 to 3:05**

This slide presents the project architecture.

At the top, we have the RV32I five-stage pipeline. Instructions move from instruction fetch, or IF, through decode, execute, memory access, and writeback. This pipeline remains the main compute foundation of the system.

The middle lane shows the security path. The custom ISA control block receives the required command from the processor. It communicates with the AES-128 CTR accelerator, which performs the encryption operation. The MMIO registers then provide software-visible access to status and data.

The bottom lane contains the peripheral services needed by an IoT edge node. SPI supports sensor input, UART supports communication or telemetry, and the DMA-lite block supports data movement. The arrows are intentionally left to right, which makes the pipeline, control, and peripheral relationships easy to follow.

**Point in order:** pipeline, custom ISA to AES-CTR to MMIO, then SPI, UART, and DMA-lite.

**Transition:** Next, I will explain the AES-CTR data flow used by the accelerator.

---

## Slide 5 - AES-CTR encryption path

**Time: 3:05 to 4:20**

AES is a block cipher, and AES-128 uses a 128-bit key. In CTR mode, the input to AES is a counter value rather than the plaintext itself.

The processor or control logic supplies a counter. The AES-128 block encrypts that counter and produces a keystream. The keystream is then combined with the plaintext through an XOR operation. The result is the ciphertext that can be stored or transmitted.

CTR mode is useful in an edge-data setting because counter blocks can be processed independently and the data path does not require padding. This suits continuous or stream-like sensor data.

However, there is one important security requirement: the same counter value must never be reused with the same AES key. A deployed implementation needs a clear key-provisioning and counter-management policy to preserve the security properties of CTR mode.

**Point to the diagram:** Counter, AES-128, Keystream, XOR, Ciphertext. Then point to Plaintext entering the XOR stage from below.

**Transition:** The accelerator needs a simple software-visible way to control this operation.

---

## Slide 6 - Custom ISA and MMIO control interface

**Time: 4:20 to 5:10**

This slide shows the compact software control sequence.

AES_START launches an encryption transaction. AES_STATUS lets the processor observe whether the accelerator is still busy or whether it has completed. AES_READ allows software to fetch the result. Finally, AES_CLEAR returns the control interface to an idle state for the next transaction.

The AES and AES-CTR control window begins at address 0x0000_0300. This memory-mapped structure gives embedded software a predictable interface. The security operation remains explicit to the programmer rather than becoming an opaque peripheral action.

**Point to each command while naming it. Then point to the MMIO address.**

**Transition:** We then verified the command and status sequence at RTL level.

---

## Slide 7 - RTL verification sequence

**Time: 5:10 to 6:00**

This waveform provides verification evidence for the custom security control path.

The transaction begins when the driver issues a start command. The accelerator then enters a busy state while the AES operation is in progress. When the operation completes, the completion status becomes visible to the software. The processor can then read the result or clear the interface.

We used directed simulation to check the custom instruction transactions, AES control and status behavior, and the interaction of the control path with the surrounding interface logic. The important point is that we verify both the final result and the sequencing of the control signals.

**Use the bottom labels as a guide:** Start, Busy, Complete, and Read or Clear.

**Transition:** After RTL verification, we synthesized the design for the FPGA target.

---

## Slide 8 - Implementation flow

**Time: 6:00 to 6:45**

The design was described in SystemVerilog RTL. It includes the RISC-V processor, the AES-CTR accelerator, the custom control logic, and the supporting peripheral interfaces.

We used the Intel Quartus Prime synthesis flow and targeted a Cyclone V FPGA device. The netlist on the left is the synthesized implementation view. The flow on the right summarizes the progression from RTL to synthesis and then to resource and timing reports.

This slide provides implementation evidence. It does not claim final product-level power or throughput performance. Those measurements remain part of the next evaluation stage.

**Transition:** The next slide gives the resource snapshot from this synthesis run.

---

## Slide 9 - Cyclone V implementation snapshot

**Time: 6:45 to 7:25**

For the reported Cyclone V synthesis run, the design uses 12,825 estimated ALMs, 10,461 registers, and 106 pins.

These numbers describe the hardware footprint of the current prototype. They show that the design has progressed beyond an architectural concept to a synthesized implementation.

At the same time, these figures should be interpreted carefully. They are resource-report values. They are not direct measurements of encryption throughput, energy consumption, or comparative security strength. Those measurements need a separate benchmark and hardware-evaluation campaign.

**State each number once, pause, then state the limitation clearly.**

**Transition:** The contribution of this work is the system-level integration of these elements.

---

## Slide 10 - System-level contribution

**Time: 7:25 to 8:15**

The contribution can be understood through three connected aspects.

First, the RV32I pipeline provides a compact and recognizable compute foundation. Second, AES-CTR provides local protection near the source of sensor data. Third, the custom ISA and MMIO registers provide explicit software control over the security operation.

Together, these elements connect computation, encryption, and edge I/O in a single processor architecture. The work is not proposing a new AES algorithm. Instead, it demonstrates a practical integration path for a standard cryptographic primitive within a lightweight RISC-V edge node.

**Point to Compute, Protect, and Connect while explaining each aspect.**

**Transition:** I will now summarize the conclusion and the next steps.

---

## Slide 11 - Conclusion and next steps

**Time: 8:15 to 9:10**

To conclude, this work integrates AES-CTR acceleration and explicit security control within a lightweight RISC-V processor design for IoT edge nodes.

The architecture retains the familiar RV32I pipeline, connects a dedicated AES-128 CTR accelerator through a clear control path, and supports edge-node interfaces such as SPI, UART, and DMA-lite. RTL verification and the Cyclone V synthesis result provide evidence that the architecture can be implemented as a coherent hardware system.

The next steps are to measure power, latency, and throughput on the target platform; evaluate resilience against faults; and extend the software validation. These steps will move the work from a verified and synthesized prototype toward a measured edge-security platform.

**Transition:** Thank you for your attention. I welcome your questions.

---

## Slide 12 - Questions

**Time: 9:10 to 10:00**

Thank you. We would be happy to answer questions on the processor architecture, the AES-CTR dataflow, the custom ISA interface, RTL verification, or the FPGA implementation results.

Pause after this sentence. If the session chair asks for a final remark, say: *The central message is that lightweight RISC-V processing and local AES-CTR acceleration can be integrated through a clear hardware-software control model for IoT edge nodes.*

---

## Likely questions and concise answers

### Why did you choose AES-CTR instead of AES-CBC

CTR mode creates a keystream by encrypting counter values. It supports independent counter blocks and does not require padding, which suits stream-like edge data. The essential requirement is that a counter must never repeat under the same AES key.

### What is the benefit of the custom ISA

The custom ISA makes the security control sequence explicit to software. It provides a compact way to start the accelerator, check completion, read the result, and clear the interface without treating the encryption block as an opaque component.

### Do the synthesis results prove low power or high throughput

No. The reported values are resource figures from the Cyclone V synthesis run. Power, throughput, and latency require dedicated measurements on the target platform and are identified as future work.

### How are AES keys protected in this design

The present work focuses on integrating the processor and encryption accelerator. A deployed version should include protected key provisioning, secure key storage, access control, and a defined policy for counter management.

### Why did you choose RISC-V

RV32I is a compact and well-defined base ISA that suits architectural experimentation. The design preserves that familiar processor foundation while adding focused security support through hardware acceleration and custom control.

### Is this a new AES algorithm

No. The work uses the standard AES-128 primitive in CTR mode. The contribution is the integration of the accelerator, custom ISA control, MMIO access, verification flow, and edge-node peripheral support.

---

## Technical sources

- NIST FIPS 197, Advanced Encryption Standard: https://csrc.nist.gov/pubs/fips/197/final
- RISC-V International: https://riscv.org/
- Project architecture, RTL verification, and synthesis results: authors' implementation and submitted manuscript.
