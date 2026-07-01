# External Examiner Defense Script



The language is deliberately simple, but every claim is technically bounded.

## The Four Rules for This Viva

1. Never describe an estimated result as a physical measurement.
2. Never mix standalone AES, integrated Quartus and integrated Genus results.
3. Never claim that 100% planned functional coverage proves the absence of bugs.
4. State one limitation yourself before the examiner has to expose it.

## Evidence Map

| Claim | Correct evidence | Important qualification |
|---|---|---|
| AES is functionally correct | NIST known-answer test | One known vector plus randomized C-reference comparison |
| Reusable AES reduces area and estimated power | Baseline versus reusable Genus comparison at TSMC 55 nm | Same design scope and technology must be maintained |
| Integrated FPGA meets timing | Quartus post-fit timing report | Power is vectorless and low confidence |
| Integrated ASIC netlist meets its constraint | Full-SoC Genus GPDK045 HVT report | Do not compare its absolute values with the 55 nm AES study |
| Random AES-CTR/UART behavior is correct | UVM plus independent C-DPI model | UVM DUT is AES MMIO plus UART, not the full CPU |
| Complete application flow works | Directed Full-SoC scenario | Scenario coverage is focused, not exhaustive |
| Sleep and activity are observable | MMIO activity counters and scenario waveform | Counters measure cycles, not physical energy |

# Part I: 30-Minute Presentation Script

## Slide 1: Title

**Time: 0:00 to 0:40**

Good morning respected examiners and teachers.

I am Varada Inamdar from VLSI Design. My thesis title is **Design and Verification of a Lightweight RISC-V-Based IoT Security Processor with Iterative Hardware-Reusable AES 128**.

The work has two connected contributions. The first is an iterative AES-128 architecture that reuses hardware across the rounds. The second is the integration and verification of this AES engine inside a five-stage RISC-V security processor.

In this presentation, I will keep the standalone AES evidence, FPGA SoC evidence and ASIC SoC evidence clearly separated.

## Slide 2: Motivation

**Time: 0:40 to 2:00**

Consider an autonomous vehicle sensor node. It may collect acceleration, wheel speed, temperature or fault information. The data must reach a trusted controller, but the sensor node has limited power and silicon resources.

Software AES is flexible, but it consumes CPU cycles. A fully unrolled AES engine offers high throughput, but it duplicates round hardware and increases switched capacitance. My design explores the middle point: dedicated cryptographic hardware with one datapath reused over time.

The objective is not maximum throughput. The objective is a practical area, power and latency trade-off for moderate-rate secure telemetry.

**Likely challenge:** Why call it low power before measuring a fabricated chip?

**Answer:** I use the term for the architectural objective and synthesis comparison. The strongest evidence is the controlled standalone Genus comparison at the same 55 nm technology and conditions. FPGA power is reported separately as a low-confidence vectorless estimate. I do not claim silicon-measured power.

## Slide 3: Contributions

**Time: 2:00 to 3:00**

The first contribution is the reusable AES datapath. A single SubBytes engine, MixColumns engine and key-expansion engine are repeatedly scheduled by an FSM.

The second contribution is system integration. AES supports ECB for compatibility testing and CTR for sensor-data encryption. It is controlled through MMIO and selected custom security instructions.

The third contribution is layered verification. I used directed CPU and peripheral tests, randomized smoke testing, UVM with a C-DPI reference, portable functional coverage and a complete processor-driven application scenario.

I will not claim that each layer covers the entire SoC. Instead, each layer has a defined scope.

## Slide 4: Threat Model

**Time: 3:00 to 4:10**

The present design protects confidentiality between a sensor node and a receiver. AES-CTR converts plaintext telemetry into ciphertext.

CTR alone does not authenticate the sender, prevent modification or stop replay. Nonce and counter reuse with the same key is also unsafe. Key registers are visible in the present prototype.

Therefore, production deployment requires authenticated encryption, secure key storage, replay protection and side-channel countermeasures.

**Likely challenge:** Is this a secure automotive product?

**Answer:** No. It is an RTL and FPGA proof of concept for secure telemetry acceleration. A production design would need CAN-FD or Automotive Ethernet, authenticated encryption, hardware key storage, safety mechanisms and qualification.

## Slide 5: AES-CTR

**Time: 4:10 to 5:30**

For block number i, the counter input is:

```text
X_i = nonce || counter_i
K_i = AES_encrypt(key, X_i)
C_i = P_i XOR K_i
```

The receiver generates the same keystream and calculates:

```text
P_i = C_i XOR K_i
```

Only the AES encryption datapath is needed for both directions. CTR does not need padding and blocks can be independently processed. The counter increments after every completed block.

The critical requirement is that the same nonce and counter combination must never be reused with the same key.

## Slide 6: Reusable AES Architecture

**Time: 5:30 to 7:15**

AES-128 has an initial AddRoundKey, nine complete rounds and a final round without MixColumns.

The proposed core stores the current 128-bit state and round key in registers. The FSM starts one reusable helper, waits for its done response, saves the result and moves to the next operation.

SubBytes is sequential, MixColumns processes reusable data, and key expansion is also sequenced. The same module instances serve all ten rounds.

This reduces logic duplication and simultaneous switching. It increases the number of cycles per block. The measured primitive latency is 295 cycles in the integrated simulation.

**Likely challenge:** Does architectural reuse always reduce energy?

**Answer:** Not automatically. It reduces area and switched capacitance, but more cycles add clock and register energy. That is why I report the synthesis power comparison and latency separately. A final energy-per-block conclusion would require activity-based power under identical workloads and conditions.

**Likely challenge:** Are you actually clock gating?

**Answer:** No generated clock is used. The wrapper qualifies starts and peripheral activity with clock-enable conditions. The AES core continues a transaction once accepted. This avoids unsafe RTL clock gating, but it is not equivalent to an inserted integrated clock-gating cell or a UPF power domain.

## Slide 7: Standalone AES Results

**Time: 7:15 to 8:40**

This is the controlled low-power comparison and is the most important result for a low-power examiner.

Both baseline and reusable AES results belong to the standalone AES study using Cadence Genus and the same TSMC 55 nm context.

```text
Cells:       83,352 -> 2,694       reduction 96.77%
Area:    202,949.64 -> 11,841.480 um2 reduction 94.17%
Power:       21.9 mW -> 0.853125 mW  reduction 96.10%
```

The reusable AES critical data path is 3.102 ns. At the 10 ns constraint, setup slack is positive at 6.806 ns.

These numbers support area reduction and estimated power reduction. They do not prove board-level energy, thermal behavior or side-channel resistance.

**Likely challenge:** Why is the comparison fair?

**Answer:** The designs are compared as standalone AES implementations in the same synthesis technology and constraint context. I do not compare the 55 nm AES result against the 45 nm integrated SoC or the Cyclone V FPGA.

## Slide 8: Complete SoC Architecture

**Time: 8:40 to 10:00**

The complete path is:

```text
Sensor/SPI -> RISC-V -> RAM/DMA -> AES-CTR -> UART
                         |             |
                      INTC       Activity monitor
```

The processor is a five-stage RV32I-style pipeline. Peripherals are placed in separate MMIO pages. The MEM stage performs address decoding and read-data multiplexing.

The interrupt controller retains completion events. Activity counters record CPU, AES, UART, DMA, sensor and sleep cycles.

DMA reduces processor involvement in word movement, but this DMA-lite implementation is not a high-performance bus master.

## Slide 9: MMIO Integration

**Time: 10:00 to 11:10**

The MMIO pages are:

```text
0x0300 AES and AES-CTR
0x0400 sensor and SPI
0x0500 UART
0x0600 interrupt controller
0x0700 DMA-lite
0x0800 power and activity control
```

A 32-bit processor transfers a 128-bit AES key or block through four consecutive 32-bit registers. The AES wrapper joins KEY0 to KEY3 and PT0 to PT3 into 128-bit buses.

MMIO preserves the processor pipeline. Ordinary `lw` and `sw` instructions control the accelerator without changing the base ISA.

## Slide 10: Custom ISA

**Time: 11:10 to 12:15**

The custom-0 opcode is decoded in ID, carried through EX, acted on in MEM and returned through WB.

The commands demonstrate XOR, AES status, AES start, ciphertext-word read and done clear.

The custom start instruction only carries two 32-bit source operands, so it loads the lower 64 bits of a compact plaintext and clears the upper half. Full key, nonce, counter and 128-bit plaintext programming still uses MMIO.

**Likely challenge:** Does the ID stage execute AES?

**Answer:** No. ID only recognizes the opcode and generates control. AES is a multi-cycle peripheral operation launched when the instruction reaches MEM. The pipeline is not turned into a 128-bit datapath.

## Slide 11: Application Data Record

**Time: 12:15 to 13:10**

In simulation, sensor values are supplied by the testbench. In practical use, an SPI sensor supplies measurements such as acceleration or temperature.

The processor packs multiple fields into a 128-bit record. This record is plaintext. The nonce and counter are protocol values, not sensor measurements. The key comes from secure provisioning, not from the sensor.

AES-CTR encrypts the packed record. UART transmits ciphertext for demonstration.

## Slide 12: Verification Strategy

**Time: 13:10 to 14:30**

Verification is layered because one test cannot prove every feature.

```text
AES KAT                  6 pass, 0 fail
Directed CPU            47 pass, 0 fail
Directed peripherals    25 pass, 0 fail
Random smoke             5 pass, 0 fail
UVM regression          25 matches, 0 mismatches
Portable coverage      114/114 bins with 100 transactions
Full-SoC scenario       15 pass, 0 fail
Combined directed      107 pass, 0 fail
```

The 25-transaction UVM run reaches 96 of 114 bins. Coverage closure is claimed only for the separate 100-transaction run.

**Likely challenge:** Why are there overlapping test layers?

**Answer:** They answer different questions. Directed tests locate deterministic failures. Random tests vary data. UVM supplies an independent reference and scoreboard. Coverage measures planned stimulus space. The Full-SoC scenario proves integrated control flow.

## Slide 13: UVM Architecture

**Time: 14:30 to 16:10**

The sequence randomizes plaintext, key, nonce and counter. The driver programs AES MMIO and sends the resulting record through RTL UART.

An independent C-DPI model calculates expected AES-CTR ciphertext and decrypts it. The UART monitor reconstructs bytes from the serial line. The scoreboard compares expected and observed UART text.

The important checks are:

```text
RTL ciphertext equals C reference ciphertext
C decryption equals original plaintext
Observed UART line equals expected UART line
Mismatch count remains zero
```

**Likely challenge:** Is the UVM environment verifying the whole CPU?

**Answer:** No. Its DUT scope is `aes_mmio` plus `uart_mmio`. CPU instructions and complete peripheral integration are verified by `riscv_core_tb.sv` and the Full-SoC scenario.

**Likely challenge:** Is the reference independent?

**Answer:** It is a separate C implementation reached through DPI, not the RTL algorithm reused as a predictor. Independence is improved by language and implementation separation, although using an established validated crypto library would strengthen future verification.

## Slide 14: AES Known-Answer Waveform

**Time: 16:10 to 17:10**

First I identify clock and reset. Then I locate the one-cycle start pulse. Busy remains high during processing. The round counter advances to ten. Done marks the cycle in which ciphertext is valid.

At done, I compare the 128-bit ciphertext with:

```text
69C4E0D86A7B0430D8CDB78070B4C55A
```

The waveform shows internal behavior. The self-checking testbench provides the final six-pass, zero-fail verdict.

## Slide 15: Full-SoC Waveform

**Time: 17:10 to 18:25**

I read this waveform from cause to effect.

The CPU generates MMIO addresses. Sensor or SPI activity appears. DMA copies the test word. AES start rises, busy covers the encryption interval and done marks completion. Ciphertext then drives UART writes. UART busy and serial output toggle, interrupt pending becomes visible, counters increment and sleep is asserted at the end.

The observed sensor word is `12345678`. The AES ciphertext low word becomes `62809322`. The scenario completes 15 checks with zero failures.

## Slide 16: Verification Results

**Time: 18:25 to 19:20**

The verification result is not only a PASS count. Traceability connects each claim to a test, log and waveform.

The strongest end-to-end UVM evidence is 25 matched UART transactions, zero mismatches and zero UVM errors or fatals. The 100-transaction run closes all 114 planned portable bins.

This means the implemented scenarios and planned bins passed. It does not prove all possible states, timing corners or security attacks.

## Slide 17: Quartus FPGA Results

**Time: 19:20 to 20:20**

The integrated Cyclone V design uses 13,257 ALMs and 11,154 registers. Slow-corner setup slack is positive at 2.577 ns and hold slack is positive at 0.371 ns. The constraint-equivalent frequency is approximately 57.40 MHz.

Quartus estimates total thermal power at 519.72 mW, divided into 350.49 mW static, 147.14 mW dynamic and 22.09 mW I/O.

The report marks power confidence as low because it is vectorless. Therefore, I use it as an implementation estimate, not as the main low-power proof.

**Likely challenge:** Why is static power larger than dynamic power?

**Answer:** FPGA static power includes the configured device fabric and depends strongly on device and operating assumptions. The vectorless dynamic estimate uses assumed toggle activity. It should not be interpreted as measured application power.

## Slide 18: Quartus Netlist

**Time: 20:20 to 21:05**

The Quartus RTL or technology-map viewer proves elaboration and connectivity. I trace the top module into the pipeline, MEM-stage interconnect and peripherals.

This is a synthesized connectivity view, not transistor layout and not proof of power by itself.

The AES branch shows the wrapper and reusable core hierarchy. The wide combinational and register paths reflect the 128-bit state and key storage.

## Slide 19: Full-SoC Genus Results

**Time: 21:05 to 22:00**

The integrated SoC was also synthesized using a separate GPDK045 HVT flow.

It reports 50,968 leaf cells, mapped area of 135,947.599 square micrometres, worst data path of 17.169 ns, positive setup slack of 2.315 ns and zero total negative slack. The constraint-equivalent maximum frequency is about 56.55 MHz.

Vectorless total power is 1.43753 mW. This value belongs only to this technology, library and activity assumption.

## Slide 20: Genus Netlist

**Time: 22:00 to 22:45**

The Genus schematic confirms that the complete synthesizable hierarchy maps into standard cells. HVT cells reduce leakage but normally trade some speed.

The netlist is useful for hierarchy, path and cell interpretation. It is not a post-layout result because placement, routing, extracted parasitics and signoff analysis are outside the present work.

## Slide 21: Why Results Are Separate

**Time: 22:45 to 23:35**

There are three result scopes.

1. TSMC 55 nm standalone AES compares baseline and reusable AES.
2. Quartus Cyclone V reports integrated FPGA utilization and post-fit timing.
3. GPDK045 HVT Genus reports integrated ASIC synthesis.

Technology, libraries, operating conditions and design scopes differ. Their absolute power and area numbers must not be placed in one direct comparison.

## Slide 22: Why the Design Can Reduce Activity

**Time: 23:35 to 24:45**

Dynamic power can be represented as:

```text
P_dynamic = alpha x C_load x V^2 x f
```

Hardware reuse mainly targets switched capacitance and simultaneous activity. Only one set of AES helper blocks exists instead of repeated round units.

At system level, clock-enable conditions prevent new peripheral operations during sleep, and activity counters make active and sleep intervals observable.

However, activity counters are not power meters. Also, the AES compatibility wrapper only qualifies transaction start. Once AES accepts a request, the core runs until completion. A production low-power flow would add integrated clock-gating cells, UPF power intent, isolation, retention and activity-based power analysis.

**Likely challenge:** Does `if (enable)` guarantee lower power?

**Answer:** It reduces unnecessary state changes at RTL, but the physical result depends on synthesis mapping. It may infer register enables or feedback multiplexers. Only post-synthesis activity and power analysis can quantify the benefit.

## Slide 23: Limitations and Future Work

**Time: 24:45 to 26:15**

The important limitations are:

- CTR provides confidentiality but not authentication.
- Key storage is register based.
- Nonce uniqueness is a software responsibility.
- UART is a demonstrator, not an automotive production bus.
- The CPU does not implement complete CSR and trap interrupt handling.
- Native covergroups were unavailable in the installed Starter license, so portable planned-bin coverage was used.
- Code coverage, formal verification, post-layout power, SDF timing simulation and power-aware UPF verification are not completed.
- Side-channel leakage and fault injection are not evaluated.

Future work should prioritize authenticated encryption, protected keys, proper wake-up control, CAN-FD or Ethernet, assertions, formal properties, toggle-based power and post-layout signoff.

## Slide 24: Conclusion

**Time: 26:15 to 27:30**

This work demonstrates a complete path from a reusable AES architecture to a verified RISC-V security processor.

The controlled standalone comparison shows large reductions in cell count, area and estimated power. The processor integration preserves the five-stage pipeline and adds AES-CTR, sensor/SPI, UART, interrupt, DMA and activity monitoring.

Verification progresses from a standard AES vector to directed processor tests, peripheral checks, randomized UVM comparison and a complete application scenario.

The central contribution is a measured engineering trade-off: less duplicated cryptographic hardware and lower estimated power, in exchange for higher block latency.

## Slide 25: Thank You

**Time: 27:30 to 28:00**

Thank you. I welcome your questions.

Use the remaining two minutes as timing margin. Do not fill the entire 30 minutes deliberately.

# Part II: Low-Power Expert Cross-Questions

## 1. What exactly creates the low-power benefit?

One copy of the main AES helper logic is reused. This reduces duplicated cells, physical capacitance and simultaneous switching. The synthesis comparison shows the resulting area and estimated power reduction.

## 2. Is this clock gating?

No. The design uses activity and clock-enable conditions without creating a generated clock. The reusable AES core itself runs to completion after accepting start. Proper physical clock gating is future work.

## 3. Why not gate the clock using `clk & enable`?

Combinational clock gating can create glitches, skew and short pulses. ASIC flows use characterized integrated clock-gating cells with enable timing checks. FPGA flows use dedicated clock-control or register-enable resources.

## 4. What do the activity counters measure?

They count clock cycles during which CPU, AES, UART, DMA, sensor or sleep activity is asserted. They are useful for workload comparison but do not directly measure watts or joules.

## 5. Why can more cycles still be low power?

Power and energy are different. Reuse can reduce average power by reducing active capacitance, but more cycles may increase energy. Both power and latency must be considered. This thesis does not claim silicon-measured minimum energy per block.

## 6. Why is the byte-sequential AES latency 295 cycles?

SubBytes, MixColumns and key expansion are multi-cycle reusable helpers. The FSM contains start and wait states for each helper and repeats them across ten rounds.

## 7. What throughput follows from 295 cycles?

Using the measured cycle count at a projected 50 MHz clock:

```text
Latency = 295 / 50 MHz = 5.90 us
Throughput = 128 bits / 5.90 us = 21.69 Mbit/s
```

This is a projection, not a board measurement.

## 8. Why is Quartus power low confidence?

The estimate is vectorless. Quartus used assumed switching rather than representative VCD or SAIF activity from the application.

## 9. How would you improve power accuracy?

Run representative workloads, capture post-fit signal activity, annotate it into the power analyzer, set real I/O standards and thermal conditions, and compare repeated runs. For ASIC, use gate-level activity with parasitics and signoff power tools.

## 10. Why use HVT cells for the SoC synthesis?

HVT cells usually reduce leakage at the cost of speed. They suit low-leakage goals when timing margin is available. The reported positive slack shows that this mapped design met its selected constraint.

## 11. What about glitch power?

Zero-delay RTL simulation does not accurately represent physical glitches. Post-synthesis or post-layout timing simulation and activity-based power analysis are needed.

## 12. Why are no voltage droop or current spikes visible?

RTL models logical state transitions, not analog supply behavior. IR drop, package noise, simultaneous-switching current and electromagnetic effects require physical and power-integrity analysis.

## 13. Can the processor sleep while AES is busy?

The intended software flow enters sleep after completion. In the present wrapper, AES continues after accepting start, while MMIO completion capture is clock-enable qualified. Robust production design should prevent sleep entry while busy or implement a formal wake-up and retention protocol.

## 14. Does hardware reuse improve side-channel security?

Not automatically. A regular iterative schedule may simplify analysis, but unmasked AES can still leak through power or electromagnetic behavior. Masking, hiding and leakage evaluation are separate requirements.

## 15. What is the fairest low-power conclusion?

Under the retained standalone 55 nm synthesis conditions, the reusable AES has substantially lower cell count, area and estimated total power than the baseline. Physical energy and side-channel behavior remain future validation tasks.

# Part III: Verification Expert Cross-Questions

## 1. Why use both directed testing and UVM?

Directed tests isolate known functions and are easy to debug. UVM randomizes data, separates stimulus and checking, and supports reusable monitors, scoreboards and coverage.

## 2. What is the UVM transaction?

It contains plaintext, key, nonce, counter, expected ciphertext, decrypted plaintext and expected UART text.

## 3. What does the driver do?

It programs AES MMIO registers, starts CTR encryption, waits for completion, reads ciphertext and transmits a formatted record through UART.

## 4. What does the monitor observe?

It samples the physical UART serial output, reconstructs bytes and emits the observed line to the scoreboard.

## 5. Why is monitoring UART stronger than checking its input register?

It verifies serialization, bit timing, byte reconstruction and the complete output path rather than only confirming a register write.

## 6. What makes the test self-checking?

Expected results are calculated automatically and compared with RTL and observed UART results. Mismatches issue UVM errors or increment failure counters.

## 7. What is the golden model?

A separate C-DPI AES-CTR implementation calculates expected ciphertext and performs decryption.

## 8. Could RTL and C contain the same conceptual bug?

Yes. Independent implementation reduces common-mode risk but does not eliminate it. Standard vectors and a validated external crypto library provide additional protection.

## 9. Why does the 25-transaction run not claim coverage closure?

It reaches 96 of 114 planned bins. The separate 100-transaction seed-611 run reaches 114 of 114.

## 10. What does 114/114 coverage mean?

Every planned portable bin and cross in this coverage model was observed. It does not mean every RTL state, transition, assertion or input combination was covered.

## 11. Why use portable coverage instead of native covergroups?

The installed Questa Intel Starter Edition lacks the `svverification` feature required for native covergroup execution. A deterministic portable collector was used, and this limitation is explicitly reported.

## 12. Did you collect code coverage?

No final code-coverage closure is claimed. Future work should include statement, branch, condition, toggle and FSM coverage.

## 13. Where are assertions?

The current environment mainly uses procedural checks and scoreboard comparisons. Useful future assertions include start-not-while-busy, done-eventually-after-start, one-hot MMIO select, counter increment, stable ciphertext and UART protocol properties.

## 14. What corner cases should be added?

Back-to-back starts, start while busy, reset during AES, reset during UART, illegal MMIO addresses, zero DMA length, maximum DMA length, UART write while busy, counter overflow and sleep requested during active peripherals.

## 15. How is reproducibility achieved?

The UVM and random runs accept explicit seeds and transaction counts. A failing seed can be rerun with the same plusargs.

## 16. Why is a single UVM waveform shown?

One transaction keeps the waveform readable. Statistical evidence comes from the separate 25- and 100-transaction logs.

## 17. What does the Full-SoC scenario add?

It executes CPU instructions and connects sensor/SPI, RAM, DMA, AES-CTR, UART, interrupts, activity counters and sleep in one application flow.

## 18. Is the Full-SoC scenario UVM?

No. It is a focused directed scenario inside `riscv_core_tb.sv`. The UVM scope is AES MMIO plus UART MMIO.

## 19. How do you isolate a requested test?

Runtime plusargs select AES KAT, directed CPU, directed peripherals, random smoke or Full-SoC scenario without editing RTL. UVM uses `UVM_TESTNAME`, `NUM_TXNS` and `E2E_SEED`.

## 20. What is the strongest verification limitation?

The project has strong functional scenario evidence but lacks full code coverage, assertion closure, formal verification, power-aware simulation and fault-oriented security verification.

# Part IV: Live Demonstration Script

## Directed Peripheral Test

Say:

> I am selecting only the directed peripheral suite through a runtime plusarg. The source code is not modified.

Run:

```powershell
cd "D:\mtech\sem 4\midesm presetation\riscv_aes_advancements\risc_aes_custom_ISA\verification\questa_wave_capture"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\launch_capture.ps1 -Test 03
```

Point to `PASS=25 FAIL=0`, then explain AES, SPI, UART, IRQ, DMA, power and custom-ISA activity.

## UVM End-to-End Test

Say:

> This UVM run randomizes the cryptographic transaction and compares RTL with an independent C reference and the reconstructed UART output.

Run one readable waveform:

```powershell
.\launch_capture.ps1 -Test 05
```

Point to:

```text
rtl_ciphertext_match = 1
decrypted_plaintext_match = 1
uart_matches = 1
uart_mismatches = 0
```

## Full-SoC Scenario

Say:

> This is not the standalone UVM environment. It is the complete CPU-driven application scenario.

Run:

```powershell
.\launch_capture.ps1 -Test 07
```

Point to `PASS=15 FAIL=0`, then trace sensor/SPI to RAM/DMA, AES-CTR, UART, interrupt, counters and sleep.

# Part V: Statements to Avoid

Do not say:

- "The FPGA consumes exactly 519.72 mW."
- "Clock gating removes all idle power."
- "The activity counter measures power."
- "UVM verifies the complete processor."
- "100% coverage means there are no bugs."
- "CTR prevents replay and tampering."
- "The 45 nm and 55 nm power numbers can be compared directly."
- "The netlist is the physical layout."

Say instead:

- "Quartus reports a low-confidence vectorless estimate of 519.72 mW."
- "RTL activity control reduces unnecessary transactions; physical clock gating is future work."
- "Counters measure active cycles and support workload comparison."
- "UVM verifies AES-CTR plus UART; directed tests verify the CPU and Full-SoC integration."
- "All 114 planned portable bins were hit."
- "CTR provides confidentiality; authentication and replay protection remain required."
- "Each result is interpreted only within its own technology and design scope."
- "The netlist confirms synthesized structure and connectivity."

# Final Two-Minute Revision

Before entering the room, recite these eight facts:

1. Reusable AES: 2,694 cells, 11,841.480 um2 and 0.853125 mW in the standalone 55 nm Genus study.
2. Reduction: 96.77% cells, 94.17% area and 96.10% estimated total power.
3. AES delay: 3.102 ns and setup slack +6.806 ns at a 10 ns constraint.
4. Integrated simulation latency: 295 primitive cycles; projected 21.69 Mbit/s at 50 MHz.
5. Quartus: 13,257 ALMs, 11,154 registers, setup +2.577 ns and hold +0.371 ns.
6. UVM: 25 matches and zero mismatches; separate coverage run reaches 114/114 with 100 transactions.
7. Full-SoC scenario: 15 pass and zero fail.
8. Main limitations: vectorless power, no authentication, register-based keys, no UPF/signoff power and incomplete assertion/code-coverage closure.

