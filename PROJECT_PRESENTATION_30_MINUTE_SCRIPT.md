# 30-Minute Thesis Presentation Speaker Script

**Presentation:** Design and Verification of a Lightweight RISC-V-Based IoT Security Processor with Iterative Hardware-Reusable AES 128  
**Presenter:** Varada Inamdar, MIS 712438020  
**Deck:** `RISC_V_AES_Thesis_Presentation_30_Minutes_Revised.pptx`  
**Target duration:** 30 minutes, followed by questions

## How to Use This Script

- Text in normal paragraphs is written to be spoken.
- Text in square brackets is a delivery or pointing cue and is not spoken.
- Aim for a steady presentation pace of approximately 130 to 135 words per minute; slow briefly when reading hexadecimal values.
- Do not rush the results slides. If time is short, reduce detail on Slides 18 and 20, not on the verification or limitations slides.
- Keep the three synthesis evidence domains separate: standalone AES in TSMC 55 nm, integrated FPGA SoC in Quartus, and integrated ASIC-style SoC in GPDK045 HVT.

## Timing Checkpoints

| Time | Expected position |
|---:|---|
| 5 minutes | Completing Slide 4 |
| 10 minutes | Completing Slide 8 |
| 15 minutes | Completing Slide 12 |
| 20 minutes | Completing Slide 16 |
| 25 minutes | Completing Slide 20 |
| 30 minutes | Completing Slide 25 |

---

## Slide 1: Title

**Time: 0:00 to 0:45**

Good morning respected examiners, faculty members, and everyone present. I am Varada Inamdar from VLSI Design, and today I am presenting my M.Tech thesis titled, **Design and Verification of a Lightweight RISC-V-Based IoT Security Processor with Iterative Hardware-Reusable AES 128**, completed under the guidance of Dr. Ashwini Kulkarni.

This work began with a focused hardware question: can AES-128 be implemented with substantially lower area and switching activity by reusing one round datapath? It then developed into a processor-level question: can that reusable AES engine become part of a practical RISC-V security system that acquires sensor data, encrypts it, transmits it, and verifies the complete operation?

The presentation therefore follows one continuous path: reusable AES research, RISC-V integration, end-to-end verification, and implementation evidence from both FPGA and ASIC-oriented synthesis.

[Pause briefly, then advance.]

---

## Slide 2: Motivation

**Time: 0:45 to 2:05**

The motivation comes from a practical edge-computing problem. Consider an autonomous vehicle or an advanced driver-assistance unit. It continuously produces telemetry such as acceleration, angular velocity, wheel speed, diagnostic state, and event information. If this information is transmitted in plaintext, an attacker on the communication path may observe it, replay an old record, or alter a record before it reaches the gateway.

Encryption is therefore useful, but an edge node has limited area, power, memory, and timing budget. A software-only AES implementation uses many processor instructions and keeps the CPU active for longer. At the other extreme, a fully unrolled hardware AES places several round structures in parallel. It provides high throughput, but duplicates logic and increases capacitance and switching activity.

My design question was not simply, "Can I add AES to RISC-V?" The more useful question was, "How little active hardware is sufficient for the required secure telemetry rate?" This led to an iterative AES accelerator, where one round datapath is reused under finite-state-machine control, and then to a lightweight SoC that surrounds it with sensor, DMA, UART, interrupt, and power-management functions.

[Point from "security pressure" to "edge constraints," then to "design need."]

---

## Slide 3: Research Contribution

**Time: 2:05 to 3:00**

The contribution has three connected layers.

First, at the cryptographic hardware layer, I use one AES round datapath repeatedly across the ten AES-128 rounds. SubBytes, ShiftRows, MixColumns, AddRoundKey, and key expansion are controlled sequentially instead of being duplicated ten times.

Second, at the processor layer, I integrate this engine with a five-stage RV32I-style pipeline. The accelerator is accessible through memory-mapped registers, and selected security operations are also exposed through custom RISC-V instructions. Around it, the system includes a sensor or SPI interface, UART, DMA-lite, interrupt control, and activity monitoring.

Third, at the verification layer, I move from primitive verification to application verification. The project includes known-answer tests, directed CPU and peripheral tests, randomized tests, a UVM environment with an independent C-DPI reference model, functional coverage, and a complete sensor-to-UART scenario.

Thus, the thesis extends a standalone AES architecture into a verified security processor rather than presenting only an isolated cipher block.

---

## Slide 4: Automotive Threat Model

**Time: 3:00 to 4:20**

[Point from the sensors across the data path to the trusted gateway.]

This diagram defines the security boundary clearly. The sensor values are legitimate plaintext at the source. They pass through the RISC-V security processor and leave the prototype through UART. In a production vehicle, UART would be replaced by a qualified interface such as CAN-FD or Automotive Ethernet.

Four threats are shown. Interception exposes the telemetry. Replay injects an old valid message. Modification changes the message in transit. Key extraction compromises future communication.

The implemented AES-CTR path directly addresses confidentiality against interception. Counter progression also gives the system the state needed for replay handling, but replay protection is not complete until the receiver checks freshness. CTR by itself does not provide authentication, so it does not prevent deliberate ciphertext modification. Production deployment would therefore use authenticated encryption, such as GCM, or combine CTR with a MAC. Similarly, the prototype stores the key in registers for controlled RTL study; production hardware requires protected key storage and side-channel hardening.

This distinction is important: I am presenting an RTL and FPGA proof of concept with a defined upgrade path, not claiming that the current UART prototype is already an automotive-qualified security module.

---

## Slide 5: Cryptography Choice

**Time: 4:20 to 5:40**

AES is the standardized 128-bit block cipher primitive. The design supports the original ECB behavior for known-answer testing and adds CTR mode for streaming sensor records.

For block number `i`, the processor supplies a nonce and counter. These are concatenated to form a 128-bit counter input, shown here as `X_i = Nonce parallel Counter_i`. The AES engine encrypts this input using the secret key to produce the keystream `K_i`. The plaintext record is then XORed with that keystream: `C_i = P_i XOR K_i`.

At the receiver, the same key, nonce, and counter regenerate exactly the same keystream. A second XOR recovers the plaintext because `C_i XOR K_i = P_i`.

[Point to CTR in the mode comparison.]

CTR was selected because encryption and decryption use the same AES encryption primitive, records do not require padding, and independent counters allow record-wise processing. ECB is retained only to verify the primitive against the NIST vector; it is unsuitable for actual telemetry because identical plaintext blocks produce identical ciphertext blocks. GCM is the intended production extension because it adds authentication, but CTR keeps the current hardware and verification scope compact and transparent.

---

## Slide 6: Iterative AES Microarchitecture

**Time: 5:40 to 7:05**

This slide shows the central architectural decision. A software implementation has small dedicated hardware cost but consumes many CPU cycles. A fully unrolled AES implementation duplicates the round logic and gives low block latency, but at high area and activity. The proposed architecture occupies the middle ground: dedicated hardware is present, but the same round datapath is reused.

At start, plaintext is XORed with the original key. For rounds one to nine, the state passes through SubBytes, ShiftRows, MixColumns, and AddRoundKey. The final round omits MixColumns, as required by AES-128. A round counter and finite-state machine select the correct transformation and round key. The state and key registers preserve intermediate values between cycles.

The reuse reduces replicated combinational logic and the amount of hardware switching simultaneously. The cost is increased latency because rounds are performed over time rather than in parallel. This is a deliberate trade-off for telemetry systems, where the data rate is moderate and energy and area are more important than multi-gigabit throughput.

The comparison shown here is from the standalone AES study: cell count reduces from 83,352 to 2,694, area from 202,949.64 to 11,841.48 square micrometres, and total estimated power from 21.9 to 0.853 milliwatts.

---

## Slide 7: Standalone AES Results in Cadence Genus, TSMC 55 nm

**Time: 7:05 to 8:15**

These results quantify the reusable AES contribution under one consistent synthesis environment. Both the baseline and proposed AES architectures were evaluated using Cadence Genus with a TSMC 55 nanometre low-power RVT library under the stated conditions.

[Point to each reduction bar in order.]

The proposed design uses 2,694 cells instead of 83,352, which is a 96.77 percent cell-count reduction. Area decreases by 94.17 percent, from 202,949.64 to 11,841.48 square micrometres. Total estimated power decreases by 96.10 percent, from 21.9 to 0.853 milliwatts.

For the proposed core, the reported critical data-path delay is 3.102 nanoseconds. With a 10-nanosecond clock constraint, the worst setup slack is positive at 6.806 nanoseconds, so the design meets that synthesis timing constraint.

These figures support a specific conclusion: hardware reuse is highly effective for reducing the standalone AES implementation cost. They do not yet describe the complete RISC-V SoC, and I will keep that distinction throughout the remaining results.

---

## Slide 8: Complete System Architecture

**Time: 8:15 to 9:50**

[Trace the diagram from left to right.]

The complete architecture begins with a vehicle sensor or SPI peripheral. A five-stage RV32I-style processor executes the control program. The stages are instruction fetch, decode, execute, memory, and writeback, with hazard detection and forwarding to preserve pipeline correctness.

The security subsystem contains the AES wrapper, iterative AES-128 primitive, CTR-mode logic, UART transmitter, DMA-lite engine, interrupt controller, and power-management counters. The CPU can read a sensor sample, place or move it into a 128-bit record, program the AES key, nonce, counter, and plaintext registers, start encryption, and wait for completion. The ciphertext can then be written to UART for transmission. Completion events are collected by the interrupt controller, and the activity counters record CPU, AES, UART, DMA, and sleep behavior.

The main functional path is therefore: acquire data, buffer or move it, encrypt it, transmit ciphertext, observe completion, and enter an idle state.

For the prototype, UART makes the serial behavior easy to verify at RTL. The blocks are modular, so an automotive bus controller can replace UART without changing the AES primitive. This modularity is one reason the system uses MMIO as its primary integration mechanism.

---

## Slide 9: RISC-V Integration Through the MEM Stage

**Time: 9:50 to 11:10**

The largest system-level RTL change is in the memory stage. Normal load and store instructions already calculate an address in the execute stage. I reuse that path as a lightweight internal interconnect.

If the address is ordinary memory, the access goes to data RAM. If the upper address matches a peripheral window, the MEM stage selects exactly one MMIO block. The map is: `0x300` for AES and AES-CTR, `0x400` for sensor or SPI, `0x500` for UART, `0x600` for the interrupt controller, `0x700` for DMA-lite, and `0x800` for power and activity control.

Each peripheral receives read-enable, write-enable, address offset, and write data. A read-data multiplexer returns only the selected peripheral value, with a defined default for unmapped locations. This avoids multiple blocks driving the read path.

The pipeline itself is not rewritten. Fetch, decode, execute, memory, and writeback remain recognizable, while MMIO extends the existing load-store behavior. The debug outputs expose PC, AES completion, ciphertext, UART, interrupt, sleep, and activity information so that the integrated hardware remains observable in simulation and FPGA synthesis.

---

## Slide 10: Custom Security ISA

**Time: 11:10 to 12:45**

MMIO remains the complete and portable control method. The custom ISA is an additional research path used to examine tighter processor-accelerator interaction.

[Point to the 32-bit field layout.]

The instructions use the RISC-V `custom-0` opcode, binary `0001011`. The standard R-type positions are retained: source registers `rs1` and `rs2`, destination register `rd`, and `funct3` to select the command. In this implementation, `funct3` selects `CSEC_XOR`, `CSEC_AES_STATUS`, `CSEC_AES_START`, `CSEC_AES_CT0`, or `CSEC_AES_CLEAR`.

The instruction is fetched normally. In decode, the control unit recognizes the custom opcode and generates a custom-command field. The execute stage forwards source operands in the same way as other dependent instructions. In the memory stage, the command interacts with the AES control and status path. A returned status or ciphertext word travels through writeback into `rd`.

For example, `CSEC_AES_STATUS` reads accelerator status without an explicit software load instruction, while `CSEC_AES_CT0` returns the least-significant ciphertext word. The implementation is intentionally modest: it demonstrates an ISA-level control path without forcing a 128-bit register-file redesign. MMIO is still used for full key, nonce, counter, and block programming.

---

## Slide 11: Concrete Automotive Telemetry Scenario

**Time: 12:45 to 14:00**

This slide makes the data path concrete. The sensor does not provide an AES nonce, counter, or key. It provides physical measurements. The processor packs those measurements into a 128-bit plaintext record.

[Point from `PT3` down to `PT0`.]

In this example, the upper word stores a timestamp. The next word contains X, Y, and Z acceleration values plus an event class. The next contains three gyroscope components plus a quality field. The lowest word contains wheel speed, diagnostic information, and a health byte. Together these four 32-bit words form one AES plaintext block.

The key is provisioned by the trusted system, while the nonce identifies the communication context and the counter identifies the block. AES encrypts nonce and counter to form a keystream, and the telemetry record is XORed with it. Only ciphertext is transmitted.

At the trusted gateway, the receiver uses the same key and the corresponding nonce-counter value to recover the original record. It can then unpack timestamp, acceleration, gyroscope, wheel-speed, and diagnostic fields. This is the practical meaning of the sensor-to-encrypted-output path implemented in the thesis.

---

## Slide 12: Layered Verification Methodology

**Time: 14:00 to 15:05**

Verification was organized in layers so that a failure could be localized instead of hidden inside one long scenario.

Layer one verifies the AES primitive using the NIST known-answer vector. Layer two verifies supported processor behavior, including arithmetic, immediate, load-store, branch, jump, system, fence, and pseudo operations. Layer three verifies AES MMIO, sensor and SPI, UART, interrupts, DMA, power management, and custom commands. Layer four adds deterministic randomized smoke testing.

Layer five uses UVM with randomized plaintext, key, nonce, and counter, plus an independent C-DPI AES-CTR reference. Layer six measures the planned functional-coverage bins and end-to-end result coverage. Layer seven runs a complete processor-controlled scenario from sensor acquisition through encryption, UART, interrupt observation, counters, and sleep.

This progression is deliberate. A final scenario proves integration, but the earlier layers tell us why it works and make debugging practical. The verification evidence therefore covers the primitive, instructions, interfaces, randomized data space, and full application flow.

---

## Slide 13: UVM End-to-End Architecture

**Time: 15:05 to 16:35**

[Follow the upper path from sequence to scoreboard.]

The UVM sequence creates randomized 128-bit plaintext, AES key, nonce, and counter values. The driver programs the AES and UART MMIO interfaces. The RTL AES-CTR block produces ciphertext, and the UART transmitter serializes a textual transaction record using the physical TX line.

The UART monitor does not simply inspect the transmit register. It reconstructs bytes from the serial line, checks the UART framing, assembles the complete line, and sends the observed result to the scoreboard.

In parallel, a C-DPI model independently computes the expected AES-CTR ciphertext and decrypts it again. The scoreboard requires three agreements: RTL ciphertext must equal the C reference, the reference decryption must recover the original plaintext, and the UART monitor must reconstruct the expected output line.

The coverage collector measures input distributions, selected crosses, match status, and UART result behavior.

One scope detail is important: this UVM environment verifies the AES-MMIO and UART end-to-end component path. It is not the proof of complete CPU execution. CPU-pipeline integration is covered by the directed regression and the full-SoC scenario shown later. Together, the environments cover both component depth and system breadth.

---

## Slide 14: AES-128 NIST Known-Answer Waveform

**Time: 16:35 to 17:45**

This is the wrapper-level AES known-answer test captured in Questa. The key is `000102030405060708090A0B0C0D0E0F`, and the plaintext is `00112233445566778899AABBCCDDEEFF`.

[Point to start, busy, round count, state, and ciphertext in that order.]

After reset, the test initializes the AES wrapper inputs and pulses start. Busy asserts while the round counter progresses through the ten AES rounds. The state and round-key buses change as the reusable datapath processes each round. At completion, busy deasserts, done asserts, and the ciphertext becomes `69C4E0D86A7B0430D8CDB78070B4C55A`, matching the NIST expected result.

The screenshot focuses on the cryptographic time window, so the displayed pass counter may still show its pre-check value at the cursor. The companion self-checking log executes immediately afterward and reports six checks passed, zero failed, and `ALL TESTS PASSED`. The six checks cover completion, busy behavior, and the four 32-bit ciphertext words.

This waveform proves correct primitive sequencing and output for the selected standard vector.

---

## Slide 15: Full-SoC Scenario Waveform

**Time: 17:45 to 18:55**

The previous slide isolated the AES wrapper. This waveform exercises the integrated application path.

[Point from sensor read to DMA, AES, UART, IRQ, and sleep.]

The CPU enables the required control registers, reads the modeled sensor value, and starts the SPI-side activity. DMA-lite performs the staged word transfer. The processor then programs the AES key, nonce, counter, plaintext, and CTR mode. AES busy asserts and the round engine runs. When done asserts, the resulting ciphertext becomes available; the shown lower plaintext word `0x12345678` produces the observed lower ciphertext word `0x62809322` for the programmed key and counter context.

The software flow writes ciphertext data to UART, observes completion through status and pending-interrupt behavior, reads the activity counters, and finally enters sleep. The self-checking full-scenario test contains fifteen explicit checks, and the result is fifteen passed and zero failed.

This is the system-level proof that the blocks are not merely instantiated together: their control and data movement form a coherent sensor-security transaction.

---

## Slide 16: Regression and Coverage Summary

**Time: 18:55 to 20:10**

This slide summarizes the verification evidence without combining unlike test counts.

The complete integrated directed regression reports 107 checks passed and zero failed. That regression covers the processor instruction groups, AES modes, peripherals, custom ISA behavior, signal activity, randomized smoke operations, and the full system scenario.

The dedicated UVM end-to-end run is reported separately. With 25 randomized transactions, the scoreboard records 25 UART matches, zero mismatches, and 96 of 114 planned portable coverage bins, or 84.21 percent. A longer 100-transaction coverage run then reaches 114 of 114 bins, with 100 matches and zero mismatches.

[Point to the final coverage values in the waveform.]

The portable coverage collector was used because the installed Questa Intel FPGA Starter Edition did not provide the licensed native SystemVerilog covergroup feature. It measures the same planned distributions and crosses in ordinary SystemVerilog. Therefore, I report it explicitly as portable functional coverage, not as simulator-native covergroup coverage.

The main conclusion is that deterministic checking, independent-reference comparison, UART reconstruction, and planned randomized-space closure all agree with the RTL behavior.

---

## Slide 17: Integrated FPGA Results in Quartus

**Time: 20:10 to 21:25**

These are the complete AES-plus-RISC-V processor results from Quartus Prime Standard 23.1, targeting the Cyclone V device `5CGXFC7C7F23C8`.

The fitted design uses 13,257 ALMs, approximately 23 percent of the selected device, and 11,154 registers. The report shows no DSP blocks or embedded RAM blocks inferred for this implementation. The wide debug interface contributes to 106 I/O pins.

With a 20-nanosecond, or 50-megahertz, clock constraint, the post-fit worst setup slack is positive at 2.577 nanoseconds. The worst hold slack is also positive at 0.371 nanoseconds, so the reported timing constraints are met with no setup or hold violations.

The Quartus power estimate is 519.72 milliwatts, consisting primarily of 350.49 milliwatts static and 147.14 milliwatts dynamic power, with about 22.09 milliwatts of I/O power. This is a vectorless estimate marked low confidence because no workload-derived VCD or SAIF activity was supplied. It is useful as an implementation estimate, but it is not measured board power.

---

## Slide 18: Quartus RTL Netlist Evidence

**Time: 21:25 to 22:20**

These Quartus RTL Viewer images confirm that synthesis retains the intended hierarchy and connectivity.

[Briefly indicate the complete, MEM-stage, and EX-stage views.]

The top-level view shows the processor stages and peripheral integration. The memory-stage view is particularly important because it contains the RAM path, load-store formatting, MMIO decode, AES, UART, sensor-SPI, DMA, interrupt, and power-management branches. The execute-stage view shows the ALU, operand selection, forwarding, and branch-related path.

I use these figures as structural evidence, not as a claim that every primitive gate was manually inspected. Their purpose is to show that the expected modules were elaborated and connected rather than optimized into an unintended or disconnected structure. Functional correctness comes from simulation, while implementation feasibility and structure come from synthesis and fitting.

---

## Slide 19: Complete SoC in Cadence Genus, GPDK045 HVT

**Time: 22:20 to 23:40**

This is a second implementation view of the complete SoC, using Cadence Genus 23.14 and the GPDK045 high-threshold-voltage standard-cell library at the stated slow corner of 0.9 volts and 125 degrees Celsius.

The mapped design contains 50,968 leaf cells: 40,120 combinational cells and 10,848 sequential cells. The reported pre-layout area is 135,947.6 square micrometres.

[Point to the timing allocation bar.]

For the 20-nanosecond clock constraint, the data-path portion is 17.169 nanoseconds. Including the reported setup and uncertainty terms, the worst setup slack remains positive at 2.315 nanoseconds, with total negative slack equal to zero. The corresponding constraint-equivalent estimate is about 56.55 megahertz, but this is not a post-layout signoff frequency.

The vectorless synthesis power estimate is 1.43753 milliwatts: approximately 1.29801 milliwatts internal, 0.13743 milliwatts switching, and 0.002084 milliwatts leakage. The very low leakage is consistent with HVT mapping, while the longer data path reflects the speed trade-off. These numbers require post-layout parasitics and workload activity before signoff conclusions.

---

## Slide 20: Cadence Genus Mapped Netlist

**Time: 23:40 to 24:30**

This image is the Genus GUI schematic of the mapped complete processor. At this scale it is intentionally dense because it represents 50,968 standard-cell instances and the connectivity between them.

The useful interpretation is structural. The design was read, elaborated, synthesized, and mapped using HVT cells, while seventeen hierarchy groups were retained for traceability. The dense central routing reflects the shared processor buses, control fanout, and the MEM-stage peripheral interconnect. The large schematic should not be mistaken for a placed-and-routed physical layout; cell placement, clock-tree synthesis, routing parasitics, and final signoff are outside this synthesis-stage image.

Together with the QoR, timing, and power reports, this netlist provides evidence that the full RTL is mappable to a standard-cell library rather than being only simulation code.

---

## Slide 21: Correct Interpretation of the Three Result Domains

**Time: 24:30 to 25:30**

This slide prevents a common but serious reporting error. The three result groups answer different questions and should not be directly divided against one another.

The standalone AES comparison uses Cadence Genus with TSMC 55 nanometre RVT cells. Because baseline and reusable AES use the same scope, library, and conditions, that is the valid evidence for the 94.17 percent area reduction and 96.10 percent power reduction.

The Quartus result covers the complete FPGA SoC and answers whether the integrated design fits and meets timing on the selected Cyclone V device.

The GPDK045 HVT Genus result also covers the complete SoC, but in a different library and synthesis environment. It answers whether the integrated RTL can be mapped to HVT standard cells and meet the 50-megahertz constraint at that synthesis corner.

I therefore do not compare 13,257 FPGA ALMs with 50,968 ASIC cells, or 519.72 milliwatts in an FPGA estimate with 1.43753 milliwatts in a vectorless ASIC-library estimate. The technologies, scopes, activity assumptions, and implementation stages are different.

---

## Slide 22: Low-Power Interpretation

**Time: 25:30 to 26:40**

The architectural reasoning follows the dynamic-power relation `P_dynamic = alpha times C times V squared times f`.

The RTL does not control fabrication voltage, and the comparison frequency is constrained by the chosen synthesis setup. The main architectural levers are therefore switching activity `alpha` and effective switched capacitance `C`.

The reusable AES reduces capacitance by removing duplicated round hardware. It reduces simultaneous activity because only the required round datapath and state updates operate in each cycle. Hardware acceleration also avoids a long software sequence of loads, substitutions, shifts, XORs, and key-expansion operations on the CPU. Around the accelerator, clock-enable style controls suppress unnecessary register updates when AES, UART, sensor, or DMA are idle; no unsafe generated clocks are used.

However, RTL structure alone does not prove final energy. Accurate dynamic-power comparison requires representative switching activity from VCD or SAIF, followed by post-placement clock-tree and parasitic analysis across process, voltage, and temperature corners. The current evidence supports the architectural reduction and synthesis estimates; silicon-level energy remains future validation.

---

## Slide 23: Limitations and Production Upgrade Path

**Time: 26:40 to 28:00**

[Point across each prototype-to-production row.]

The current system is intentionally a research prototype, and its limitations define the next engineering steps.

First, AES-CTR provides confidentiality but not integrity. CTR ciphertext is malleable, and the same key must never reuse the same nonce-counter combination. Production communication should therefore move to authenticated encryption, such as AES-GCM, or use a separate MAC with strict freshness checking.

Second, the key is held in visible control registers. Production hardware needs secure provisioning, protected nonvolatile or physically isolated key storage, zeroization, debug restrictions, and resistance to side-channel and fault attacks.

Third, UART is a convenient demonstration interface. Automotive deployment requires CAN-FD or Automotive Ethernet, message authentication, error handling, and network timing analysis.

Fourth, the present interrupt line is observable and its pending behavior is verified, but the processor does not yet implement complete privileged CSR, trap-vector, and return handling.

Finally, an automotive product requires safety and cybersecurity engineering, including ISO 26262 and ISO/SAE 21434 processes, fault injection, watchdog and redundancy strategy, secure boot, authenticated firmware update, and qualification across operating corners. This slide is therefore not an apology for the prototype; it is the technically honest path from thesis RTL to deployable hardware.

---

## Slide 24: Conclusion

**Time: 28:00 to 29:15**

To conclude, this work makes five connected contributions.

First, it demonstrates an iterative AES-128 architecture that reuses one round datapath and, in the controlled standalone TSMC 55 nanometre study, substantially reduces cell count, area, and estimated power relative to the baseline.

Second, it integrates that AES primitive into a five-stage RV32I-style processor with CTR-mode support, sensor and SPI access, UART, DMA-lite, interrupt collection, sleep control, and activity counters.

Third, it provides both conventional MMIO control and a compact custom security ISA path while preserving the existing load-store pipeline organization.

Fourth, verification moves beyond a ciphertext-only check. It covers processor instructions, peripheral behavior, randomized AES-CTR transactions, an independent C-DPI reference model, physical UART reconstruction, planned coverage closure, and a fifteen-check full-SoC scenario.

Fifth, the implementation is supported by distinct evidence: standalone AES synthesis, complete FPGA fitting and timing, and complete HVT standard-cell mapping.

The main engineering result is a traceable path from a hardware-reusable cipher core to a verified lightweight security processor, with its benefits and limitations stated separately and quantitatively.

---

## Slide 25: Thank You

**Time: 29:15 to 30:00**

Thank you for your time and attention.

The central idea I would like to leave with you is that low-power security does not always require removing hardware or executing everything in software. It can also be achieved by using dedicated hardware carefully: reusing the expensive datapath, activating it only when needed, and integrating it through a simple, verifiable processor interface.

I will be happy to answer questions on the AES architecture, RISC-V integration, verification environment, synthesis results, or the production upgrade path.

[Stop. Look at the panel. Do not continue filling the silence.]

---

# Short Viva Preparation After the Talk

These answers are not part of the timed presentation. Use them if the panel asks follow-up questions.

## 1. What is the single most important novelty?

The strongest standalone architectural contribution is reuse of one AES round datapath across all AES-128 rounds, demonstrated against the baseline under the same TSMC 55 nm synthesis conditions. The thesis-level contribution is extending that core into a verified RISC-V security processor with both MMIO and custom-instruction control.

## 2. Why choose CTR instead of ECB?

ECB was retained only for the NIST known-answer test. CTR avoids pattern leakage, supports arbitrary-length records without padding, permits independent counter blocks, and uses only the AES encryption primitive for both encryption and decryption. CTR does not authenticate data, so GCM or CTR plus a MAC is needed for production.

## 3. Does the sensor supply the nonce and key?

No. The sensor supplies physical readings. The processor packs those readings into the plaintext. The key comes from trusted provisioning. The nonce identifies the security context or session, and the counter advances for each encrypted block.

## 4. What happens if the nonce and counter are reused?

If the same key and nonce-counter input are reused, the same keystream is generated. XORing the two ciphertexts then reveals the XOR of the two plaintexts, which can expose both messages. The combination must therefore be unique for every block under a given key.

## 5. Why retain MMIO after adding custom instructions?

MMIO is complete, modular, and software-portable. It can program all 128-bit key, nonce, counter, and plaintext words. The custom instructions are a compact research extension for common control and result operations; they do not replace the entire register interface.

## 6. Is the UVM test a full CPU test?

No. The UVM environment deeply verifies the AES-MMIO-to-UART component path using randomized transactions and an independent C-DPI model. Full CPU-pipeline participation is verified separately by the directed regression and the full-SoC scenario. This separation makes failure diagnosis clearer.

## 7. Why use a portable coverage collector?

The installed Questa Intel FPGA Starter Edition did not include the `svverification` license required for native covergroups. The project therefore implements the planned bins and crosses in portable SystemVerilog and reports exactly how the metric was collected. The 100-transaction run closes all 114 planned bins.

## 8. Why are Quartus and Genus power values so different?

They are not directly comparable. One is a Cyclone V FPGA estimate and includes FPGA static and I/O behavior. The other is a GPDK045 HVT standard-cell synthesis estimate. Their technologies, libraries, operating conditions, scopes of physical information, and activity assumptions differ.

## 9. Is 56.55 MHz the proven ASIC Fmax?

No. It is a constraint-equivalent estimate derived from the Genus synthesis timing report. Final Fmax requires post-layout extraction, clock-tree effects, parasitics, and multi-corner signoff.

## 10. Why are no DSP or embedded RAM blocks used in Quartus?

AES transformations are logic and XOR dominated, so DSP blocks are unnecessary. In this RTL configuration, the instruction and data storage structures were not inferred as embedded RAM blocks, partly because of their behavioral and verification-oriented access patterns. A production FPGA version could restructure memories for block-RAM inference.

## 11. What exactly does the 107-pass result mean?

It is the final complete integrated directed regression: 107 explicit self-checking conditions passed and zero failed. It is separate from the dedicated UVM transaction counts and the 114-bin coverage metric.

## 12. What is the main performance disadvantage of iterative AES?

Its block latency is higher than a fully unrolled or deeply pipelined implementation because the same round hardware is reused over several cycles. The architecture is appropriate when telemetry rate is moderate and area and energy are more important than maximum throughput.

## 13. Does this design meet automotive production requirements?

No production qualification is claimed. It is an RTL and FPGA proof of concept. Production requires authenticated encryption, secure key storage, replay protection, automotive interfaces, full trap handling, secure boot, fault tolerance, side-channel evaluation, and ISO 26262 and ISO/SAE 21434 processes.

## 14. What would you implement next?

The most valuable next step is authenticated encryption with secure nonce management and protected key storage. At the processor level, I would add privileged CSR and trap support. At the interface level, I would replace UART with CAN-FD or Automotive Ethernet, then perform activity-based post-layout power and fault-security evaluation.

## 15. Which result most directly proves the low-power AES claim?

The controlled baseline-versus-proposed standalone AES comparison in Cadence Genus using the same TSMC 55 nm RVT environment. The integrated Quartus and GPDK045 results establish SoC feasibility, but they are not the source of the standalone percentage reductions.

---

# Final Delivery Checklist

- Open the revised deck and disable automatic slide timing.
- Keep a backup PDF of the presentation on the same machine.
- Verify that Slides 14 and 15 remain readable on the projector.
- Say "estimated power," not "measured power."
- Say "portable functional coverage," not "native covergroup coverage."
- Say "RTL/FPGA proof of concept," not "automotive-qualified processor."
- Keep TSMC 55 nm AES results, Cyclone V FPGA results, and GPDK045 HVT SoC results separate.
- End at Slide 25 and wait for questions.
