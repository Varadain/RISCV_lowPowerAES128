# 30-Minute Project Presentation Script

## Presentation Title

**Design and Verification of a Lightweight RISC-V-Based IoT Security Processor with Iterative Hardware-Reusable AES 128**

## Recommended Timing

| Section | Time |
|---|---:|
| Opening and problem motivation | 3 minutes |
| Security and AES background | 4 minutes |
| Reusable AES architecture and comparison | 4 minutes |
| RISC-V security-processor architecture | 5 minutes |
| MMIO, custom ISA and peripheral flow | 4 minutes |
| Verification methodology and evidence | 5 minutes |
| FPGA and ASIC results | 3 minutes |
| Limitations, future work and conclusion | 2 minutes |
| **Total** | **30 minutes** |

The script is written for approximately 27 to 28 minutes of normal speaking. The remaining time is a buffer for slide changes, pauses, or short questions.

---

# Slide 1: Title

## Time: 0:00-1:00

Good morning respected faculty members, examiners, and everyone present.

My dissertation is titled **"Design and Verification of a Lightweight RISC-V-Based IoT Security Processor with Iterative Hardware-Reusable AES 128."**

This work brings together two related research objectives. The first objective is to design a compact and power-efficient AES-128 hardware architecture by reusing the same round datapath. The second objective is to integrate that AES engine with a five-stage RISC-V processor and verify a complete secure sensor-data path.

The final system includes the RISC-V pipeline, AES in ECB and CTR modes, sensor and SPI interfaces, UART transmission, DMA-lite, an interrupt controller, activity counters, sleep control, and a small custom security instruction extension.

The main application considered in this presentation is secure telemetry from an autonomous-vehicle sensor node.

---

# Slide 2: Motivation and Practical Problem

## Time: 1:00-3:00

Modern autonomous vehicles, robots, industrial controllers, and IoT nodes depend on distributed sensors. These sensors generate acceleration, angular velocity, wheel speed, equipment-health, diagnostic, and environmental information.

This information may travel from a sensor node to a central controller or gateway. If it is transmitted as plaintext, an observer can read sensitive operational information. In a more serious case, an attacker may replay or modify the communication.

A software implementation of AES can protect the data, but it keeps the processor active for many instructions and consumes execution time and energy. At the other extreme, a fully unrolled hardware AES implementation duplicates multiple round units. It gives high throughput, but it increases logic area and simultaneous switching.

My work studies a middle path. I use a dedicated AES accelerator so that encryption is not executed as a long software routine, but I reuse one AES round datapath instead of duplicating ten rounds.

The practical question behind the project is:

> Can a compact AES architecture be integrated into a small RISC-V processor so that sensor data is acquired, encrypted, transmitted, and verified end to end, while keeping the implementation modular and measurable?

The project therefore focuses on three ideas:

1. Hardware reuse for reducing AES implementation cost.
2. Processor-level integration through MMIO and custom instructions.
3. Layered verification from the cryptographic primitive to the complete sensor-to-UART transaction.

---

# Slide 3: Foundations of Security and Cryptography

## Time: 3:00-4:30

This figure summarizes the security foundation of the project.

The three classical security goals are confidentiality, integrity, and availability.

Confidentiality means unauthorized users should not read the sensor data. Integrity means unauthorized modification should be detected. Availability means the system should remain usable when required.

The AES-CTR path implemented in this work primarily provides **confidentiality**.

The figure also separates passive and active attacks. Passive attacks include eavesdropping and traffic analysis. Active attacks include modification, replay, impersonation, and denial of service.

Encryption is one security mechanism. It is not a complete security system by itself. Authentication, access control, secure key management, replay protection, and auditing are also required in a practical deployment.

I selected symmetric cryptography because it is efficient for repeated encryption of embedded sensor records. The same secret key is available at the transmitting node and receiving gateway. Public-key cryptography may still be used to establish or exchange a session key, but AES is better suited for bulk sensor-data protection.

This distinction is important: the present processor is a confidentiality-focused research prototype, not a complete automotive security product.

---

# Slide 4: AES-128 Operation

## Time: 4:30-6:00

AES is a 128-bit block cipher. AES-128 uses a 128-bit key and performs ten rounds.

The plaintext is first combined with the original key using AddRoundKey.

Rounds one to nine perform:

1. SubBytes,
2. ShiftRows,
3. MixColumns,
4. AddRoundKey.

The tenth round omits MixColumns, as required by the AES specification.

SubBytes provides nonlinearity. ShiftRows changes byte positions. MixColumns provides diffusion across each column. AddRoundKey combines the state with the generated round key.

The known-answer vector used for verification is:

- Key: `000102030405060708090A0B0C0D0E0F`
- Plaintext: `00112233445566778899AABBCCDDEEFF`
- Expected ciphertext: `69C4E0D86A7B0430D8CDB78070B4C55A`

This vector is important because it verifies the complete combination of byte ordering, key expansion, all AES transformations, MMIO register ordering, and final ciphertext reconstruction.

---

# Slide 5: Why CTR Mode Was Selected

## Time: 6:00-7:00

The AES primitive is preserved in ECB mode for the standard known-answer test. However, ECB is not suitable for repeated structured sensor data because equal plaintext blocks produce equal ciphertext blocks.

For the application flow, I use AES-CTR.

CTR operation is:

```text
Keystream = AES_encrypt(nonce || counter)
Ciphertext = plaintext XOR keystream
```

Decryption uses the same AES encryption primitive:

```text
Plaintext = ciphertext XOR keystream
```

CTR is useful here for three reasons:

1. Encryption and decryption reuse the AES encryption hardware.
2. Records can be processed independently.
3. No block-padding operation is required for stream-like data.

The counter is incremented after each block.

The important limitation is that the same nonce-counter combination must never be reused with the same key. CTR also does not provide authentication. A production system should therefore use AES-GCM or add a MAC such as GMAC or HMAC.

---

# Slide 6: Traditional Versus Proposed AES Architecture

## Time: 7:00-9:00

This figure compares software AES, a fully unrolled hardware architecture, and the proposed reusable hardware architecture.

Software AES requires little dedicated cryptographic hardware, but the CPU executes many instructions and remains active during encryption.

A fully unrolled AES architecture instantiates multiple round stages. It provides high throughput and low latency, but its area and switching activity are high.

The proposed architecture uses a single reusable datapath. The state and round key are stored in registers. A round counter and finite-state machine control repeated use of SubBytes, ShiftRows, MixColumns, AddRoundKey, and key-expansion logic.

The initial round is performed first. The same datapath is then used for rounds one through nine. In the final round, MixColumns is bypassed.

The main advantage is lower duplicated logic and lower simultaneous activity.

The main disadvantage is multi-cycle latency.

This is acceptable for the selected application because control telemetry, health records, event packets, and moderate-rate sensor information usually arrive more slowly than a high-bandwidth camera pixel stream.

For workloads requiring higher throughput, the architecture can be extended using partial unrolling or multiple reusable AES lanes.

---

# Slide 7: Standalone AES Results

## Time: 9:00-11:00

The standalone AES comparison was performed using Cadence Genus and a 55-nanometre low-power standard-cell library.

These values belong only to the standalone baseline and proposed AES comparison. They must not be mixed with the complete FPGA processor results.

The baseline AES uses **83,352 cells**, while the proposed reusable AES uses **2,694 cells**. This is a reduction of approximately **96.77 percent**.

The baseline area is **202,949.64 square micrometres**, while the proposed area is **11,841.48 square micrometres**. This is approximately **94.17 percent lower area**.

The baseline total power is **21.9 milliwatts**, while the proposed total power is approximately **0.853 milliwatts**. This is approximately **96.10 percent lower total power** under the reported synthesis conditions.

These results support the hardware-reuse objective. They do not mean that every future implementation will have exactly the same percentage. The values depend on the library, constraints, activity assumptions, and synthesis flow.

The defensible conclusion is that, under the same reported 55-nanometre Genus environment, the iterative architecture significantly reduces AES hardware area and estimated power in exchange for latency.

---

# Slide 8: Complete Security-Processor Architecture

## Time: 11:00-13:00

This figure shows the complete system architecture.

At the input, a sensor or SPI interface provides telemetry. The five-stage RISC-V processor controls data movement and peripheral configuration.

The processor pipeline contains:

- Instruction Fetch,
- Instruction Decode,
- Execute,
- Memory,
- Writeback.

Hazard and forwarding units maintain pipeline correctness.

The memory stage is also the central internal peripheral-integration point. It selects normal data memory or one of the memory-mapped peripherals.

The major security and communication blocks are:

- iterative AES-128 with ECB and CTR modes,
- sensor and SPI interface,
- UART transmitter,
- interrupt controller,
- DMA-lite,
- power and activity counters.

Debug outputs expose the current PC, AES completion, AES ciphertext, UART TX pin, interrupt line, sleep status, and a selected activity counter.

These outputs help simulation and FPGA observation and prevent the integrated design from behaving like a closed black box.

---

# Slide 9: RISC-V Pipeline and Data Movement

## Time: 13:00-15:00

I will briefly explain how an instruction moves through the processor.

The IF stage uses the program counter to fetch an instruction.

The ID stage extracts opcode, source registers, destination register, function fields, and immediate value. It also reads the register file and generates control signals.

The EX stage performs arithmetic, logical operations, branch comparison, and effective-address calculation.

The MEM stage performs either normal RAM access or peripheral access.

The WB stage writes an ALU result, loaded value, PC-plus-four value, or custom-instruction result back to the register file.

The forwarding unit reuses results from later pipeline stages without always waiting for writeback. The hazard unit stalls load-use dependencies and flushes instructions after taken control-flow changes.

The directed verification checks R-type, I-type, load/store, branch, upper-immediate, jump, system, fence, pseudo, and custom operations.

Signal-activity checks also prove that pipeline stall and flush signals actually assert during the regression.

---

# Slide 10: MMIO Address Map

## Time: 15:00-16:30

The processor controls most peripherals through memory-mapped I/O.

The address ranges are:

| Address | Peripheral |
|---|---|
| `0x0000_0300` | AES and AES-CTR |
| `0x0000_0400` | Sensor and SPI |
| `0x0000_0500` | UART |
| `0x0000_0600` | Interrupt controller |
| `0x0000_0700` | DMA-lite |
| `0x0000_0800` | Power and activity control |

The CPU uses ordinary load and store instructions to access these registers.

The AES range contains key, plaintext, ciphertext, nonce, counter, control, and status registers.

The MEM-stage address decoder ensures that only one peripheral is selected for a transaction. A controlled multiplexer returns the selected read value. Addresses outside the peripheral ranges continue to use normal data memory.

This approach avoids rewriting the processor pipeline around a new bus. Its limitation is scalability. If the system grows to many bus masters and peripherals, a standard AMBA, Wishbone, or TileLink interconnect would be more appropriate.

---

# Slide 11: Custom Security ISA

## Time: 16:30-18:00

In addition to MMIO, the project includes a small custom instruction extension.

It uses the RISC-V custom-0 opcode:

```text
0001011
```

The `funct3` field selects commands such as:

- custom XOR,
- AES status read,
- AES start,
- ciphertext word read,
- AES done clear.

The instruction still travels through the normal pipeline.

The IF stage fetches it. The ID stage recognizes the custom opcode. The EX stage forwards operands. The MEM stage communicates with the AES wrapper. The WB stage returns a custom result when required.

AES itself is not claimed to become a single-cycle operation. It remains a multi-cycle accelerator. The custom instruction starts or controls the accelerator, while busy and done status preserve correct sequencing.

MMIO is retained because it is flexible and software-visible. The custom ISA provides a more compact instruction-level control path. Keeping both interfaces allows comparison without sacrificing compatibility.

---

# Slide 12: Sensor-to-Encrypted-Output Flow

## Time: 18:00-20:00

The selected application is an autonomous-vehicle sensor-security gateway.

A practical 128-bit plaintext record can contain:

- a 32-bit timestamp or record identifier,
- acceleration values,
- angular-velocity values,
- wheel speed,
- diagnostic flags,
- sensor-health status.

The processing flow is:

1. The sensor sample is read through sensor MMIO or SPI.
2. The CPU stores or formats the sample.
3. DMA-lite can move the required word or record.
4. The CPU programs the AES key, nonce, counter, and plaintext registers.
5. AES-CTR produces ciphertext.
6. Ciphertext bytes are written to UART.
7. The interrupt controller captures completion events.
8. Activity counters record CPU, AES, UART, DMA, sensor, and sleep cycles.
9. The processor can request sleep after completing the transaction.

At the receiver, the same key, nonce, and counter regenerate the CTR keystream. XORing the ciphertext with that keystream recovers the original plaintext.

The key is not transmitted with the ciphertext. It must be provisioned securely at both endpoints.

UART is used only as a simple demonstration interface. A deployable vehicle design would use CAN-FD or Automotive Ethernet.

---

# Slide 13: Verification Strategy

## Time: 20:00-22:00

The verification strategy is layered.

The first layer is the AES known-answer test. It proves the cryptographic primitive after MMIO integration.

The second layer is directed processor verification. It proves the supported instruction behavior.

The third layer is directed peripheral verification. It checks AES-CTR, sensor, SPI, UART, interrupt, DMA, power counters, and custom commands.

The fourth layer is deterministic randomized smoke testing. It changes operands, sensor data, DMA values, and UART bytes so the design does not only pass fixed constants.

The fifth layer is UVM end-to-end verification with an independent C-DPI AES-CTR model.

The sixth layer is functional coverage.

The seventh layer is a complete scenario:

```text
Sensor -> CPU/RAM -> DMA -> AES-CTR -> UART -> IRQ/Power -> Sleep
```

Layering the tests makes debugging practical. If the full scenario fails, the earlier unit and peripheral tests help identify whether the problem is in the AES core, CPU, register interface, UART, or integration sequence.

---

# Slide 14: UVM and Independent C Reference

## Time: 22:00-24:00

The UVM environment randomizes:

- 128-bit plaintext,
- 128-bit AES key,
- 64-bit nonce,
- 64-bit counter.

The sequence creates reproducible transactions using a known seed.

The driver programs the RTL AES interface.

An independently compiled C-DPI reference model performs AES-128 and CTR processing using separate C code. It calculates the expected ciphertext and decrypts the result.

The RTL ciphertext must equal the C reference ciphertext.

The decrypted value must equal the original randomized plaintext.

The RTL UART then serializes the output. A passive UART monitor samples the physical `uart_tx` waveform, reconstructs bytes and complete lines, and sends the observed record to the scoreboard.

This is stronger than checking an internal UART register because the serialized output path is included in the comparison.

The coverage collector measures input categories, low nibbles, nonce-counter crosses, and match outcomes.

The final coverage run reports:

- **100 randomized transactions**,
- **100 UART matches**,
- **114 out of 114 portable coverage bins**,
- **zero UVM errors**.

One limitation is that this UVM environment concentrates on the AES and UART end-to-end path. The complete CPU, DMA, interrupt, and power flow is additionally proven through directed and scenario-based verification.

---

# Slide 15: Waveform Evidence

## Time: 24:00-25:30

When reading the waveform, I use four steps:

1. Identify the input stimulus.
2. Observe the main control transition.
3. Check the output against the expected result.
4. State the verification conclusion.

For the AES known-answer waveform, reset is released, the key and plaintext are loaded, start is asserted, busy becomes active, the round counter advances, and done asserts at completion.

At done, the ciphertext is:

```text
69C4E0D86A7B0430D8CDB78070B4C55A
```

The transcript confirms six checks: done, busy, and four ciphertext words.

The CPU waveforms show PC movement, execution controls, memory operations, stalls, and flushes.

The peripheral waveforms show AES-CTR, sensor/SPI, UART, interrupts, DMA, activity counters, and custom instruction interaction.

The UVM waveforms show randomized inputs, RTL and reference ciphertext, recovered plaintext, UART reconstruction, scoreboard matches, and coverage progression.

The full-SoC waveforms connect sensor input to encrypted output, event status, activity, and final sleep behavior.

---

# Slide 16: Directed and Scenario Results

## Time: 25:30-26:30

The complete integrated directed regression reports:

```text
107 passes
0 failures
```

This result includes processor instructions, AES ECB and CTR behavior, peripheral operations, signal activity, custom security commands, randomized smoke checks, and integrated paths.

The full-SoC scenario contains **15 explicit pass criteria**.

These results are not a mathematical proof that no bug exists. They show that the defined requirements and scenarios pass under the tested conditions.

Additional confidence could be obtained from formal assertions, code coverage, constrained-random CPU instruction generation, mutation testing, and gate-level simulation.

---

# Slide 17: Quartus FPGA Results

## Time: 26:30-28:00

The complete RISC-V security processor was compiled using Quartus Prime **23.1 Standard Edition, Build 993**.

The target device is Cyclone V:

```text
5CGXFC7C7F23C8
```

The integrated design uses:

- **13,257 out of 56,480 ALMs**, or 23 percent,
- **11,154 registers**,
- **106 out of 268 pins**, or 40 percent,
- zero DSP blocks,
- zero reported block-memory bits,
- zero PLLs.

The clock constraint is **20 nanoseconds**, corresponding to **50 megahertz**.

The reported worst setup slack is **positive 2.577 nanoseconds**, and the worst hold slack is **positive 0.371 nanoseconds**. Therefore, the design meets the reported 50-megahertz post-fit timing requirement.

The approximate critical delay under this constraint is:

```text
20 - 2.577 = 17.423 nanoseconds
```

The Quartus power result is a vectorless, low-confidence estimate:

- total: **519.72 milliwatts**,
- static: **350.49 milliwatts**,
- dynamic: **147.14 milliwatts**,
- I/O: **22.09 milliwatts**.

This is not measured board power. A stronger result would use workload-derived SAIF or VCD activity and physical current measurement.

Also, the high pin count comes partly from debug visibility. Physical pin assignments and a reduced board-level interface are required before FPGA board deployment.

---

# Slide 18: Limitations and Production Upgrade

## Time: 28:00-29:00

The main limitations of the present implementation are:

1. CTR provides confidentiality but not authentication.
2. Nonce-counter reuse must be prevented.
3. AES keys are currently stored in visible registers.
4. UART is a demonstration interface.
5. The interrupt output is verified, but full privileged CSR and trap handling is not implemented.
6. The AES architecture has higher latency than a fully unrolled core.
7. Quartus power is vectorless and low confidence.
8. The design is not automotive safety or cybersecurity certified.

The production upgrade path is:

- AES-CTR to AES-GCM or CTR plus HMAC,
- key registers to secure key storage or PUF-derived keys,
- UART to CAN-FD or Automotive Ethernet,
- debug interrupt to full RISC-V CSR and trap handling,
- add replay protection and monotonic counters,
- add secure boot and authenticated firmware loading,
- add fault injection, side-channel analysis, watchdogs, and safety mechanisms.

These limitations do not invalidate the prototype. They define the boundary between a verified research implementation and a deployable secure automotive controller.

---

# Slide 19: Conclusion

## Time: 29:00-30:00

To conclude, this work connects a low-power AES research contribution with a complete processor-level security system.

The reusable AES architecture significantly reduces standalone AES implementation cost in the reported 55-nanometre Genus comparison:

- 96.77 percent fewer cells,
- 94.17 percent lower area,
- 96.10 percent lower total power.

The AES engine is integrated with a five-stage RISC-V processor using both MMIO and custom security instructions.

The complete system includes sensor/SPI input, DMA-lite, AES-CTR encryption, UART output, interrupts, activity counters, and sleep control.

Verification is performed through known-answer tests, directed CPU and peripheral tests, randomized smoke testing, UVM with an independent C model, functional coverage, and a complete application scenario.

The integrated regression reports 107 passes with zero failures, while the UVM closure run reports 100 UART matches and 114 out of 114 planned portable coverage bins.

The complete design is successfully fitted to a Cyclone V FPGA and meets the reported 50-megahertz timing constraint.

The final contribution is therefore not only an AES core. It is a modular and verified security-processor prototype that demonstrates how hardware reuse, processor control, encrypted sensor flow, and layered verification can be combined for resource-conscious edge systems.

Thank you.

---

# Likely Questions Immediately After the Presentation

## Why did you choose CTR instead of GCM?

CTR allows the existing AES encryption primitive to be reused for both encryption and decryption, keeps the wrapper compact, and is convenient for independent telemetry records. It provides confidentiality only. GCM is the correct future upgrade when authentication is required.

## Is the design really automotive ready?

No. It is an RTL and FPGA proof of concept using an automotive sensor-security application. Production use requires CAN-FD or Automotive Ethernet, authenticated encryption, secure key storage, replay protection, safety mechanisms, and certification.

## Why is the power reduction so high?

The baseline and proposed AES were compared under the same reported 55-nanometre Genus environment. The proposed design removes duplicated round hardware and reduces simultaneous switching. The exact percentage depends on synthesis conditions, so I report it only for that controlled comparison.

## Why are there two sets of synthesis results?

Cadence Genus compares the standalone baseline and reusable AES architectures using a 55-nanometre ASIC library. Quartus evaluates the complete AES plus RISC-V system on a Cyclone V FPGA. They answer different research questions and are not mixed.

## Does 100 percent coverage mean there are no bugs?

No. It means all 114 bins in the defined portable functional-coverage model were exercised. Additional coverage models, assertions, formal verification, code coverage, and fault-oriented tests can still find bugs.

## Did the custom instruction perform complete AES in one cycle?

No. AES remains multi-cycle. The custom instructions provide compact accelerator control and status or result access. Busy and done signals preserve correct sequencing.

## What exactly is your core contribution?

The core contribution is the iterative hardware-reusable AES architecture and its integration into a modular RISC-V security processor with AES-CTR, MMIO, custom security instructions, peripherals, and layered end-to-end verification.

---

# Delivery Notes

- Speak slowly when stating numerical results.
- Pause after the problem statement and after the main contribution.
- Do not read every label inside a figure. Explain its engineering message.
- Always identify whether a result comes from Genus, Quartus, or Questa.
- Say "estimated" for vectorless power.
- Say "RV32I-style" rather than claiming formal RISC-V compliance.
- Say "proof of concept" rather than "production automotive processor."
- When challenged, answer using: fact, evidence, limitation, improvement.
