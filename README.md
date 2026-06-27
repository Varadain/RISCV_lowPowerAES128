[Custom opcode decoding](control_unit.sv#L235-L247)

[Custom instruction execution](mem_stage.sv#L130-L137)

[AES custom-command handling](aes_mmio.sv#L165-L185)

[Custom operand forwarding](ex_stage.sv#L210-L219)

[Custom ISA verification](riscv_core_tb.sv#L1015-L1055)

[Reusable AES core](rtl/AES128_updated_new.sv#L1-L100)
# 510 Viva and Cross-Examination Questions

## Project

**Design and Verification of a Lightweight RISC-V-Based IoT Security Processor with Iterative Hardware-Reusable AES 128**

> I defined and reviewed the architecture, interfaces, verification objectives, application, and result interpretation. I used EDA tools and coding automation to accelerate implementation, debugging, regression execution, and documentation. I validated the final behavior against independent references, waveforms, transcripts, and synthesis reports, and I can trace each major claim to its evidence.


## Exact Result Fact Sheet

| Item | Verified project fact |
|---|---|
| Top module | riscv_aes_advancements |
| Processor | Five-stage RV32I-style pipeline: IF, ID, EX, MEM, WB |
| AES primitive | Iterative hardware-reusable AES-128 |
| Modes | ECB for NIST compatibility; CTR for sensor-record encryption |
| AES base | 0x0000_0300 |
| Sensor/SPI base | 0x0000_0400 |
| UART base | 0x0000_0500 |
| Interrupt base | 0x0000_0600 |
| DMA-lite base | 0x0000_0700 |
| Power base | 0x0000_0800 |
| Custom opcode | 0001011 (RISC-V custom-0) |
| NIST ciphertext | 69C4E0D86A7B0430D8CDB78070B4C55A |
| Integrated directed result | 107 passes, 0 failures |
| UVM coverage result | 100 transactions, 100 UART matches, 114/114 portable bins, 0 UVM errors |
| Full-SoC scenario | 15 checks passed |
| Genus cell count | 83,352 baseline versus 2,694 proposed; 96.77% reduction |
| Genus cell area | 202,949.64 versus 11,841.48 um^2; 94.17% reduction |
| Genus total power | 21.9 mW versus 0.853 mW; 96.10% reduction |
| Complete-SoC Genus library | GPDK045 HVT, slow 0.9 V, 125 C |
| Complete-SoC Genus area | 50,968 cells; 135,947.599 um^2 mapped cell area |
| Complete-SoC Genus timing | 20 ns target; +2.315 ns setup slack; TNS 0; 0 violating paths |
| Complete-SoC Genus power | 1.43753 mW vectorless total; 0.002084 mW leakage |
| Complete-SoC Genus area concentration | MEM-stage hierarchy is 92.13% of mapped cell area |
| Quartus version/device | 23.1std.1 Build 993; Cyclone V 5CGXFC7C7F23C8 |
| Quartus utilization | 13,257/56,480 ALMs (23%); 11,154 registers; 106/268 pins (40%) |
| Clock/timing | 20 ns constraint, 50 MHz; +2.577 ns setup and +0.371 ns hold slack |
| Quartus vectorless power | 519.72 mW total = 350.49 static + 147.14 dynamic + 22.09 I/O; low confidence |

## Figure-by-Figure Speaking Guide

| Figure/visual | What it contains | What you should say |
|---|---|---|
| Foundations of security and cryptography | CIA goals, attack types, services, mechanisms, symmetric/asymmetric, and block/stream concepts. | Use it to state that AES-CTR addresses confidentiality but not complete security. |
| AES-128 Modes of Operation | ECB, CBC, CTR, and GCM comparison. | Explain why ECB is retained for NIST testing, CTR is implemented, and GCM is future work. |
| AES implementation architecture tradeoff | Software, fully unrolled, and reusable hardware AES. | Connect reuse to the 94.17% area and 96.10% total-power reductions. |
| Complete autonomous vehicle security processor | Sensor, CPU, AES, DMA, UART, interrupt, and power blocks. | Explain the complete application before discussing module details. |
| RISC-V pipeline and MMIO peripherals | Five pipeline stages, custom path, address map, and debug outputs. | Trace one load/store or AES command through the processor. |
| Custom ISA encoding and pipeline path | custom-0 fields and IF-to-WB execution. | State opcode 0001011 and explain why AES remains multi-cycle. |
| RTL module hierarchy | Top-level CPU stages and MEM-stage peripheral subtree. | Identify riscv_aes_advancements as top and mem_stage as integration point. |
| MEM-stage MMIO interconnect | Address decoding and read-data multiplexing. | Emphasize one selected peripheral and preserved RAM path. |
| UVM end-to-end architecture | Sequence, driver, DUT, C-DPI, UART monitor, scoreboard, and coverage. | Explain independence of the reference model and physical-pin monitoring. |
| Questa waveform set | Known-answer, CPU, peripheral, custom ISA, random, UVM, coverage, and full-SoC captures. | For every waveform say stimulus, key transition, observed result, and conclusion. |
| AES area and power charts | Baseline versus proposed Genus results. | Keep these standalone 55 nm ASIC results separate from the integrated FPGA. |
| SoC utilization, timing, and power | Quartus ALMs/registers, positive slack, and vectorless power. | Disclose target device and low-confidence power assumption. |
| Genus complete-SoC HVT charts and schematic | HVT cell mix, area hierarchy, timing budget, power composition, and mapped schematic. | Conclude that synthesis and 50 MHz setup timing are good, but clearly state pre-layout and vectorless limitations. |
| RTL/netlist views | Complete SoC plus EX and MEM expansion. | Use structural evidence only; do not call it functional proof. |
| 128-bit automotive telemetry record | PT3-PT0 field packing. | Show how real sensor fields become one AES block. |
| Automotive threat model | Interception, replay, modification, and key extraction. | Match each threat to current protection, remaining gap, and upgrade. |
| Security upgrade path | CTR to authenticated encryption, key registers to vault, UART to CAN/Ethernet, debug IRQ to traps. | State clearly that the present design is a proof of concept. |
| Application portfolio | Automotive, humanoid, UAV, industrial, medical, and smart grid. | Argue suitability for moderate-rate edge telemetry. |
| Secure gateway flow | Sensor acquisition through encrypted output and sleep. | Use it to explain the 15-check full-SoC scenario. |
| Secure boot future work | Decrypt, authenticate, authorize, and release firmware. | Explain that encryption without hash/MAC verification is insufficient for secure boot. |


## Security and Cryptography Foundations

**Level:** Basic

### CIA security goals

**1. Explain CIA security goals.**

Confidentiality prevents unauthorized disclosure, integrity detects unauthorized modification, and availability keeps the service usable.

**2. What role does CIA security goals have in this project?**

The implemented AES-CTR path directly addresses confidentiality of sensor records; integrity and availability are discussed as required production extensions.

**3. Why is CIA security goals important to the design?**

Separating the three goals prevents the incorrect claim that encryption alone provides complete security.

**4. How does the project handle or implement CIA security goals?**

Sensor plaintext is encrypted before UART transmission, while status, interrupt, and activity logic preserve observable operation.

**5. How was CIA security goals verified?**

The end-to-end tests prove ciphertext generation and plaintext recovery, not message authentication.

**6. Which signals or data should be observed when explaining CIA security goals?**

The main observations are plaintext, ciphertext, decrypted data, UART output, completion flags, and scoreboard match flags.

**7. Which result or number supports the discussion of CIA security goals?**

The UVM run reports 100 UART matches and zero UVM errors, supporting confidentiality-path correctness.

**8. What is the principal limitation related to CIA security goals?**

CTR ciphertext is malleable, so integrity needs GCM, GMAC, or HMAC.

**9. What alternative could replace or extend the present approach to CIA security goals?**

Authenticated encryption such as AES-GCM would combine confidentiality and integrity.

**10. How would you defend the project's treatment of CIA security goals under a difficult cross-question?**

The defensible claim is confidentiality-focused RTL proof of concept, not a complete automotive security product.

### symmetric and asymmetric cryptography

**11. Explain symmetric and asymmetric cryptography.**

Symmetric cryptography uses the same secret key for encryption and decryption; asymmetric cryptography uses a public/private key pair.

**12. What role does symmetric and asymmetric cryptography have in this project?**

The processor uses symmetric AES-128 because repeated embedded telemetry encryption benefits from compact, deterministic hardware.

**13. Why is symmetric and asymmetric cryptography important to the design?**

AES is much more area- and energy-efficient than public-key cryptography for bulk sensor data.

**14. How does the project handle or implement symmetric and asymmetric cryptography?**

A 128-bit key is loaded through four 32-bit MMIO words and consumed by the reusable AES datapath.

**15. How was symmetric and asymmetric cryptography verified?**

Known-answer and randomized tests use identical keys in RTL and the independent C reference.

**16. Which signals or data should be observed when explaining symmetric and asymmetric cryptography?**

Key words, plaintext, counter block, keystream-derived ciphertext, and recovered plaintext are observed.

**17. Which result or number supports the discussion of symmetric and asymmetric cryptography?**

The NIST vector produces 69C4E0D86A7B0430D8CDB78070B4C55A.

**18. What is the principal limitation related to symmetric and asymmetric cryptography?**

Shared keys require secure provisioning, storage, rotation, and access control.

**19. What alternative could replace or extend the present approach to symmetric and asymmetric cryptography?**

Asymmetric cryptography can establish a session key, after which AES protects the data stream.

**20. How would you defend the project's treatment of symmetric and asymmetric cryptography under a difficult cross-question?**

The design intentionally accelerates bulk encryption; it does not attempt to replace a public-key key-exchange protocol.

### block and stream cipher behavior

**21. Explain block and stream cipher behavior.**

A block cipher transforms fixed-size blocks, while a stream cipher combines data with a generated keystream.

**22. What role does block and stream cipher behavior have in this project?**

AES is a 128-bit block cipher, but CTR mode makes it behave like a stream cipher by XORing plaintext with AES-encrypted nonce-counter blocks.

**23. Why is block and stream cipher behavior important to the design?**

Stream-like operation is convenient for telemetry because encryption and decryption use the same primitive and padding is unnecessary.

**24. How does the project handle or implement block and stream cipher behavior?**

The wrapper computes KS_i = AES_K(nonce || counter_i) and C_i = P_i XOR KS_i.

**25. How was block and stream cipher behavior verified?**

A zero-plaintext CTR test makes ciphertext equal to the keystream and also checks counter auto-increment.

**26. Which signals or data should be observed when explaining block and stream cipher behavior?**

Mode, nonce, counter, plaintext, AES busy/done, ciphertext, and incremented counter are useful signals.

**27. Which result or number supports the discussion of block and stream cipher behavior?**

CTR operation is verified alongside preservation of the ECB NIST test.

**28. What is the principal limitation related to block and stream cipher behavior?**

Reusing the same nonce-counter value with the same key repeats the keystream and breaks confidentiality.

**29. What alternative could replace or extend the present approach to block and stream cipher behavior?**

CBC is possible but introduces chaining and encryption/decryption asymmetry; GCM adds authentication.

**30. How would you defend the project's treatment of block and stream cipher behavior under a difficult cross-question?**

CTR was selected for hardware reuse and record independence, not because it is universally more secure than every mode.

### passive and active attacks

**31. Explain passive and active attacks.**

Passive attacks observe traffic; active attacks modify, replay, impersonate, inject, or disrupt traffic.

**32. What role does passive and active attacks have in this project?**

AES-CTR hides sensor values from passive interception, while the report explicitly identifies replay and modification as unresolved active threats.

**33. Why is passive and active attacks important to the design?**

A realistic threat model prevents overclaiming security from functional encryption alone.

**34. How does the project handle or implement passive and active attacks?**

The prototype exposes nonce and counter control so uniqueness behavior can be studied and verified.

**35. How was passive and active attacks verified?**

The current scoreboards test correct encryption/decryption, not adversarial packet authentication.

**36. Which signals or data should be observed when explaining passive and active attacks?**

Nonce, counter, ciphertext, receive order, and message-authentication status would be required in a production monitor.

**37. Which result or number supports the discussion of passive and active attacks?**

The verified result is exact RTL/reference ciphertext equality over randomized transactions.

**38. What is the principal limitation related to passive and active attacks?**

There is no MAC/tag checker, replay window, tamper sensor, or protected monotonic counter.

**39. What alternative could replace or extend the present approach to passive and active attacks?**

AES-GCM plus persisted counters and receiver-side replay checks would address modification and replay.

**40. How would you defend the project's treatment of passive and active attacks under a difficult cross-question?**

The correct answer is that the project is a confidentiality accelerator and verification platform with a documented security upgrade path.

### project motivation

**41. Explain project motivation.**

The motivation is to protect distributed sensor telemetry without paying the area and switching cost of a fully unrolled AES or the CPU cost of software-only AES.

**42. What role does project motivation have in this project?**

The work combines a five-stage RV32I-style processor, iterative AES-128, AES-CTR, sensor/SPI, DMA-lite, UART, interrupts, power counters, and a custom ISA.

**43. Why is project motivation important to the design?**

Autonomous and edge systems contain many moderate-rate sensor records for which predictable low-area encryption is more valuable than maximum block throughput.

**44. How does the project handle or implement project motivation?**

The processor controls peripherals through MMIO and selected custom-0 commands while the AES datapath is reused across rounds.

**45. How was project motivation verified?**

Verification progresses from AES known-answer tests to directed CPU/peripheral tests, random smoke, UVM with C-DPI, coverage, and a full-SoC scenario.

**46. Which signals or data should be observed when explaining project motivation?**

The architectural figures, Questa waveforms, transcripts, Genus reports, and Quartus reports provide independent evidence.

**47. Which result or number supports the discussion of project motivation?**

The standalone reusable AES shows 94.17% lower area and 96.10% lower total power than the baseline in the reported 55 nm Genus comparison.

**48. What is the principal limitation related to project motivation?**

The iterative architecture has higher latency than a fully unrolled design.

**49. What alternative could replace or extend the present approach to project motivation?**

Software AES minimizes dedicated hardware; unrolled AES maximizes throughput; multiple reusable lanes offer a middle extension.

**50. How would you defend the project's treatment of project motivation under a difficult cross-question?**

The contribution is the measured reusable AES architecture plus its processor integration and layered verification, not the invention of AES or RISC-V.


## AES-128 Algorithm and Reusable Hardware

**Level:** Basic to Intermediate

### AES-128 algorithm

**51. Explain AES-128 algorithm.**

AES-128 encrypts a 128-bit state with a 128-bit key using an initial AddRoundKey, nine full rounds, and a final round without MixColumns.

**52. What role does AES-128 algorithm have in this project?**

The same functional sequence is implemented in the reusable core and retained behind the AES MMIO wrapper.

**53. Why is AES-128 algorithm important to the design?**

AES is standardized, widely analyzed, and suitable for hardware acceleration.

**54. How does the project handle or implement AES-128 algorithm?**

SubBytes, ShiftRows, MixColumns, AddRoundKey, and key expansion are controlled by a round FSM/counter.

**55. How was AES-128 algorithm verified?**

The standard NIST key 000102...0F and plaintext 001122...FF produce the expected ciphertext.

**56. Which signals or data should be observed when explaining AES-128 algorithm?**

start, busy, done, round, state, round_key, plaintext, key, and ciphertext explain the full operation.

**57. Which result or number supports the discussion of AES-128 algorithm?**

Observed ciphertext is 69C4E0D86A7B0430D8CDB78070B4C55A.

**58. What is the principal limitation related to AES-128 algorithm?**

AES correctness does not itself solve key storage, authentication, replay, or side-channel leakage.

**59. What alternative could replace or extend the present approach to AES-128 algorithm?**

AES-256 increases key size but also adds rounds and latency; lightweight ciphers may reduce cost in different threat models.

**60. How would you defend the project's treatment of AES-128 algorithm under a difficult cross-question?**

The project changes the microarchitecture and integration, not the mathematical AES specification.

### iterative hardware reuse

**61. Explain iterative hardware reuse.**

Iterative reuse means one round datapath is time-multiplexed across AES rounds instead of duplicating ten round units.

**62. What role does iterative hardware reuse have in this project?**

The proposed low-power core reuses the transformation and key-expansion hardware under sequential control.

**63. Why is iterative hardware reuse important to the design?**

It reduces logic duplication, switched capacitance, and simultaneous activity.

**64. How does the project handle or implement iterative hardware reuse?**

State and round-key registers feed the same combinational transformations each cycle until the final round.

**65. How was iterative hardware reuse verified?**

Round progression and final ciphertext are visible in the known-answer waveform.

**66. Which signals or data should be observed when explaining iterative hardware reuse?**

The round counter, state register, round key, busy, and done demonstrate reuse.

**67. Which result or number supports the discussion of iterative hardware reuse?**

Cell count falls from 83,352 to 2,694 and area from 202,949.64 to 11,841.48 square micrometres in the reported Genus comparison.

**68. What is the principal limitation related to iterative hardware reuse?**

A block takes multiple cycles, reducing peak throughput compared with an unrolled pipeline.

**69. What alternative could replace or extend the present approach to iterative hardware reuse?**

Partial unrolling or multiple reusable lanes can trade additional area for throughput.

**70. How would you defend the project's treatment of iterative hardware reuse under a difficult cross-question?**

Lower active hardware is the architectural reason for savings; clock gating is not the sole explanation.

### SubBytes, ShiftRows, and MixColumns

**71. Explain SubBytes, ShiftRows, and MixColumns.**

SubBytes provides nonlinearity, ShiftRows permutes byte positions, and MixColumns diffuses each column over GF(2^8).

**72. What role does SubBytes, ShiftRows, and MixColumns have in this project?**

These transformations are implemented once and reused for rounds 1 through 9; the final round bypasses MixColumns.

**73. Why is SubBytes, ShiftRows, and MixColumns important to the design?**

Together they provide confusion and diffusion required by the AES specification.

**74. How does the project handle or implement SubBytes, ShiftRows, and MixColumns?**

S-box lookup logic feeds row permutation and finite-field column mixing before round-key XOR.

**75. How was SubBytes, ShiftRows, and MixColumns verified?**

The internal state waveform changes round by round and converges to the NIST ciphertext.

**76. Which signals or data should be observed when explaining SubBytes, ShiftRows, and MixColumns?**

Round state and round index are more useful than probing every internal gate.

**77. Which result or number supports the discussion of SubBytes, ShiftRows, and MixColumns?**

Correct final ciphertext across known and randomized vectors indirectly validates the composed transformations.

**78. What is the principal limitation related to SubBytes, ShiftRows, and MixColumns?**

A final-output-only test can miss compensating internal faults, so internal assertions or formal checks would strengthen verification.

**79. What alternative could replace or extend the present approach to SubBytes, ShiftRows, and MixColumns?**

Composite-field S-boxes or ROM-based S-boxes offer different area, timing, and side-channel tradeoffs.

**80. How would you defend the project's treatment of SubBytes, ShiftRows, and MixColumns under a difficult cross-question?**

MixColumns is omitted only in round 10, exactly as required by AES-128.

### AES key expansion

**81. Explain AES key expansion.**

Key expansion derives ten round keys from the original 128-bit key using rotation, substitution, round constants, and XOR recurrence.

**82. What role does AES key expansion have in this project?**

The reusable design generates round keys sequentially rather than storing a large fully expanded schedule.

**83. Why is AES key expansion important to the design?**

Sequential generation saves storage and supports the hardware-reuse objective.

**84. How does the project handle or implement AES key expansion?**

A key register is updated each round and supplied to AddRoundKey.

**85. How was AES key expansion verified?**

The waveform exposes the changing round key while the final known-answer ciphertext confirms schedule correctness.

**86. Which signals or data should be observed when explaining AES key expansion?**

Original key, round number, round key, and state are the essential signals.

**87. Which result or number supports the discussion of AES key expansion?**

The exact NIST output is strong evidence that both datapath and key schedule byte ordering are correct.

**88. What is the principal limitation related to AES key expansion?**

On-the-fly expansion adds dependency and can affect the critical path.

**89. What alternative could replace or extend the present approach to AES key expansion?**

Pre-expanded keys improve throughput at the cost of memory and key-loading overhead.

**90. How would you defend the project's treatment of AES key expansion under a difficult cross-question?**

Byte ordering must be consistent across MMIO words, state mapping, key expansion, and the C reference.

### AES latency and throughput

**91. Explain AES latency and throughput.**

Latency is time from start to valid ciphertext; throughput is encrypted payload bits per second.

**92. What role does AES latency and throughput have in this project?**

The report uses a conservative upper bound of 40 cycles at a 50 MHz target for system-level estimation.

**93. Why is AES latency and throughput important to the design?**

A multi-cycle accelerator must be evaluated by both area/power savings and processing rate.

**94. How does the project handle or implement AES latency and throughput?**

The CPU starts AES and waits for done or an event while the round FSM advances.

**95. How was AES latency and throughput verified?**

The directed test requires done within 40 cycles and busy to deassert after completion.

**96. Which signals or data should be observed when explaining AES latency and throughput?**

Count clock edges between start and done; confirm ciphertext stability at done.

**97. Which result or number supports the discussion of AES latency and throughput?**

Using 128 x 50 MHz / 40 gives an estimated lower-bound throughput of 160 Mbit/s, and 40/50 MHz gives 0.8 microseconds latency.

**98. What is the principal limitation related to AES latency and throughput?**

The 40-cycle value is a test bound, not necessarily the exact optimized core latency.

**99. What alternative could replace or extend the present approach to AES latency and throughput?**

Exact measured cycle count should be reported for final silicon benchmarking; pipelining increases throughput.

**100. How would you defend the project's treatment of AES latency and throughput under a difficult cross-question?**

State clearly whether a number is measured, constrained, bounded, or analytically estimated.


## Five-Stage RISC-V Processor

**Level:** Intermediate

### five-stage pipeline

**101. Explain five-stage pipeline.**

The stages are instruction fetch, instruction decode, execute, memory, and writeback.

**102. What role does five-stage pipeline have in this project?**

The RV32I-style core moves instructions through IF, ID, EX, MEM, and WB while hazard and forwarding units preserve correctness.

**103. Why is five-stage pipeline important to the design?**

Pipelining overlaps instruction work and gives a clear integration point for memory-mapped peripherals.

**104. How does the project handle or implement five-stage pipeline?**

Pipeline registers carry data and control between stages; flush and stall signals manage dependencies and control changes.

**105. How was five-stage pipeline verified?**

Directed instruction groups and signal-activity checks cover arithmetic, loads/stores, branches, jumps, stalls, and flushes.

**106. Which signals or data should be observed when explaining five-stage pipeline?**

PC, instruction, decoded operands, ALU result, memory controls, writeback data, stall, and flush reveal movement.

**107. Which result or number supports the discussion of five-stage pipeline?**

The integrated directed transcript reports 107 checks with zero failures across the complete regression.

**108. What is the principal limitation related to five-stage pipeline?**

The core is RV32I-style rather than a fully privileged, compliance-certified RISC-V implementation.

**109. What alternative could replace or extend the present approach to five-stage pipeline?**

A single-cycle core is simpler but slower in critical path; a deeper pipeline raises hazard complexity.

**110. How would you defend the project's treatment of five-stage pipeline under a difficult cross-question?**

The pipeline was preserved while integration was concentrated primarily in decode/control and MEM-stage paths.

### instruction fetch and decode

**111. Explain instruction fetch and decode.**

IF uses the PC to read an instruction; ID extracts opcode, register indices, function fields, and immediates.

**112. What role does instruction fetch and decode have in this project?**

The decode path supports standard RV32I-style instructions and recognizes custom-0 opcode 0001011.

**113. Why is instruction fetch and decode important to the design?**

Correct field extraction is the foundation for both standard and custom operations.

**114. How does the project handle or implement instruction fetch and decode?**

instr_mem supplies the word, reg_file supplies operands, imm_gen creates signed immediates, and control_unit creates controls.

**115. How was instruction fetch and decode verified?**

Directed tests load instruction words into simulation ROM and check architectural register results.

**116. Which signals or data should be observed when explaining instruction fetch and decode?**

PC, fetched instruction, opcode, rs1, rs2, rd, immediate, and control signals are useful.

**117. Which result or number supports the discussion of instruction fetch and decode?**

R-type, I-type, load/store, branch, upper-immediate, jump, system/fence, pseudo, and custom operations pass.

**118. What is the principal limitation related to instruction fetch and decode?**

Direct hierarchical ROM loading is a simulation convenience, not a software toolchain or boot mechanism.

**119. What alternative could replace or extend the present approach to instruction fetch and decode?**

A hex initialization file or compiled firmware image is more portable for deployment.

**120. How would you defend the project's treatment of instruction fetch and decode under a difficult cross-question?**

The SIMULATION define preserves the ROM array for the testbench without changing Quartus synthesis behavior.

### execute stage and ALU

**121. Explain execute stage and ALU.**

The EX stage performs arithmetic, logic, shifts, comparisons, branch decisions, and effective-address calculation.

**122. What role does execute stage and ALU have in this project?**

The ALU supports ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, and AND plus address and branch operations.

**123. Why is execute stage and ALU important to the design?**

These operations cover the required RV32I-style datapath and software control of peripherals.

**124. How does the project handle or implement execute stage and ALU?**

Forwarded operands and immediate/RS2 selection feed the ALU; branch logic computes redirection.

**125. How was execute stage and ALU verified?**

Directed R- and I-type tests compare register results against known values.

**126. Which signals or data should be observed when explaining execute stage and ALU?**

ALU operands, operation code, result, compare result, branch target, and forwarding selects are key.

**127. Which result or number supports the discussion of execute stage and ALU?**

The regression reports correct arithmetic and logical outcomes with no directed failures.

**128. What is the principal limitation related to execute stage and ALU?**

No multiply/divide or floating-point extension is claimed.

**129. What alternative could replace or extend the present approach to execute stage and ALU?**

RISC-V M or F extensions can be added with dedicated multi-cycle or pipelined units.

**130. How would you defend the project's treatment of execute stage and ALU under a difficult cross-question?**

Custom AES is not implemented by overloading the normal ALU; commands proceed to the integration path.

### hazards, stalls, flushing, and forwarding

**131. Explain hazards, stalls, flushing, and forwarding.**

Hazards occur when data or control dependencies make a following instruction use unavailable or wrong-path information.

**132. What role does hazards, stalls, flushing, and forwarding have in this project?**

The forwarding unit bypasses recent results, while the hazard unit stalls load-use cases and flushes wrong-path instructions.

**133. Why is hazards, stalls, flushing, and forwarding important to the design?**

Without these mechanisms, a pipelined core can produce correct results only for carefully spaced programs.

**134. How does the project handle or implement hazards, stalls, flushing, and forwarding?**

Forward selects choose EX/MEM or MEM/WB values; stall_if freezes fetch; flush_ifid removes invalid instructions.

**135. How was hazards, stalls, flushing, and forwarding verified?**

Signal-activity checks require stall_if and flush_ifid to assert at least once.

**136. Which signals or data should be observed when explaining hazards, stalls, flushing, and forwarding?**

Source/destination register numbers, reg_write, mem_read, forwarding selects, stall, flush, and PC are examined together.

**137. Which result or number supports the discussion of hazards, stalls, flushing, and forwarding?**

The earlier directed verification observed nonzero stall and flush assertion counts.

**138. What is the principal limitation related to hazards, stalls, flushing, and forwarding?**

Directed activity proves occurrence, not exhaustive absence of every hazard corner case.

**139. What alternative could replace or extend the present approach to hazards, stalls, flushing, and forwarding?**

Assertions, random instruction generation, and formal pipeline equivalence would provide stronger closure.

**140. How would you defend the project's treatment of hazards, stalls, flushing, and forwarding under a difficult cross-question?**

Explain the exact dependency causing a stall instead of saying that all hazards are solved generically.

### memory and writeback stages

**141. Explain memory and writeback stages.**

MEM performs RAM or peripheral access; WB selects ALU, load, PC+4, or custom result for register writeback.

**142. What role does memory and writeback stages have in this project?**

MEM is the central MMIO decode point for AES, sensor/SPI, UART, INTC, DMA, and power control.

**143. Why is memory and writeback stages important to the design?**

Using the existing load/store path avoids redesigning the processor around a separate bus.

**144. How does the project handle or implement memory and writeback stages?**

Address-range selects gate one peripheral and a read multiplexer returns exactly one value; WB writes selected data to rd.

**145. How was memory and writeback stages verified?**

Loads/stores and every peripheral range are tested before end-to-end scenarios.

**146. Which signals or data should be observed when explaining memory and writeback stages?**

Address, write data, read data, byte enables, peripheral selects, result source, rd, and reg_write are key.

**147. Which result or number supports the discussion of memory and writeback stages?**

Normal data memory tests and MMIO peripheral tests pass in the same regression.

**148. What is the principal limitation related to memory and writeback stages?**

A single internal decode path can become a timing or arbitration bottleneck as the SoC grows.

**149. What alternative could replace or extend the present approach to memory and writeback stages?**

An AMBA, Wishbone, or TileLink interconnect would scale to more masters and peripherals.

**150. How would you defend the project's treatment of memory and writeback stages under a difficult cross-question?**

The current architecture is intentionally small and deterministic, suitable for thesis-scale integration.


## MMIO and Peripheral Integration

**Level:** Intermediate

### memory-mapped I/O

**151. Explain memory-mapped I/O.**

MMIO assigns peripheral registers to normal processor address locations accessed by load and store instructions.

**152. What role does memory-mapped I/O have in this project?**

AES is at 0x300, sensor/SPI at 0x400, UART at 0x500, INTC at 0x600, DMA at 0x700, and power control at 0x800.

**153. Why is memory-mapped I/O important to the design?**

It reuses the CPU load/store machinery and keeps software control simple.

**154. How does the project handle or implement memory-mapped I/O?**

mem_stage decodes ranges, generates read/write enables, and multiplexes peripheral read data.

**155. How was memory-mapped I/O verified?**

Directed peripheral tests read and write each block and verify default behavior for normal RAM and unmapped space.

**156. Which signals or data should be observed when explaining memory-mapped I/O?**

Address, mem_read, mem_write, write data, read data, and individual select/enables identify the transaction.

**157. Which result or number supports the discussion of memory-mapped I/O?**

AES, sensor/SPI, UART, interrupt, DMA, power, and custom command checks pass together.

**158. What is the principal limitation related to memory-mapped I/O?**

MMIO requires several instructions and can consume CPU cycles compared with a custom command.

**159. What alternative could replace or extend the present approach to memory-mapped I/O?**

A coprocessor interface or standard SoC bus can reduce coupling or improve scaling.

**160. How would you defend the project's treatment of memory-mapped I/O under a difficult cross-question?**

Only one read source must drive the returned value; the design uses explicit selection rather than wired multiple drivers.

### AES MMIO register protocol

**161. Explain AES MMIO register protocol.**

The AES wrapper exposes control, status, key, plaintext, ciphertext, nonce, and counter registers.

**162. What role does AES MMIO register protocol have in this project?**

Four key words, four plaintext words, four ciphertext words, two nonce words, and two counter words support 128-bit data over a 32-bit CPU interface.

**163. Why is AES MMIO register protocol important to the design?**

The wrapper preserves the stable AES primitive and localizes system integration and CTR behavior.

**164. How does the project handle or implement AES MMIO register protocol?**

Control starts encryption, clears done, and selects mode; status reports busy, done, and mode.

**165. How was AES MMIO register protocol verified?**

The CPU/testbench writes the standard key/plaintext, starts AES, polls done, and reads CT0 through CT3.

**166. Which signals or data should be observed when explaining AES MMIO register protocol?**

aes_sel, aes_write_en, aes_read_en, busy, done, mode, and data registers explain the protocol.

**167. Which result or number supports the discussion of AES MMIO register protocol?**

CT0=70B4C55A, CT1=D8CDB780, CT2=6A7B0430, and CT3=69C4E0D8 reconstruct the NIST ciphertext.

**168. What is the principal limitation related to AES MMIO register protocol?**

Register-based keys are visible to software/debug and are not secure key storage.

**169. What alternative could replace or extend the present approach to AES MMIO register protocol?**

A key vault, PUF-derived key, or write-only protected key port is required for production.

**170. How would you defend the project's treatment of AES MMIO register protocol under a difficult cross-question?**

Word ordering is little-endian at the 32-bit register interface while the complete 128-bit vector is reported in canonical hexadecimal order.

### sensor and SPI interface

**171. Explain sensor and SPI interface.**

The sensor block provides readable data/status/control registers; the SPI wrapper offers RX, TX, status, control, and slave-select registers.

**172. What role does sensor and SPI interface have in this project?**

It models a practical path from an external IMU or vehicle-health sensor into the security processor.

**173. Why is sensor and SPI interface important to the design?**

A sensor source is required to demonstrate a meaningful secure-data application rather than isolated AES.

**174. How does the project handle or implement sensor and SPI interface?**

The CPU reads sensor MMIO and can initiate SPI-style transfers through the optional generated IP wrapper.

**175. How was sensor and SPI interface verified?**

Directed tests inject/read sensor data, observe ready state, and verify SPI activity.

**176. Which signals or data should be observed when explaining sensor and SPI interface?**

sensor_data, data_ready, SPI clock, chip select, RX/TX data, and enables should be correlated.

**177. Which result or number supports the discussion of sensor and SPI interface?**

The peripheral waveform captures sensor MMIO read and SPI activity before AES-CTR processing.

**178. What is the principal limitation related to sensor and SPI interface?**

The current sensor model is not a complete physical sensor protocol implementation with timing/error qualification.

**179. What alternative could replace or extend the present approach to sensor and SPI interface?**

Production use can replace the model with qualified SPI, I2C, CAN sensor, or automotive Ethernet interfaces.

**180. How would you defend the project's treatment of sensor and SPI interface under a difficult cross-question?**

The application abstraction is deliberate: security processing remains stable when the front-end sensor interface changes.

### UART transmitter

**181. Explain UART transmitter.**

UART serializes bytes asynchronously; 8-N-1 means one start bit, eight data bits, no parity, and one stop bit.

**182. What role does UART transmitter have in this project?**

The CPU writes ciphertext bytes/records to UART TXDATA and observes busy/done status.

**183. Why is UART transmitter important to the design?**

UART is simple, synthesizable, and easy to monitor in simulation for an end-to-end output demonstration.

**184. How does the project handle or implement UART transmitter?**

A baud divisor holds each serial bit for a configured number of system-clock cycles.

**185. How was UART transmitter verified?**

The UVM UART monitor samples the TX pin, reconstructs bytes and lines, and sends them to the scoreboard.

**186. Which signals or data should be observed when explaining UART transmitter?**

tx_start, tx_data, tx_busy, tx_done, baud_count, bit_count, and uart_tx are useful.

**187. Which result or number supports the discussion of UART transmitter?**

The 100-transaction coverage run reports 100 UART line matches.

**188. What is the principal limitation related to UART transmitter?**

UART is not a production automotive network and has framing overhead and limited robustness.

**189. What alternative could replace or extend the present approach to UART transmitter?**

CAN-FD or Automotive Ethernet should replace it in a deployable vehicle design.

**190. How would you defend the project's treatment of UART transmitter under a difficult cross-question?**

At baud B, 8-N-1 useful payload is approximately 8B/10, because ten serial bits carry eight payload bits.

### DMA, interrupt, and power-management peripherals

**191. Explain DMA, interrupt, and power-management peripherals.**

DMA moves data with reduced CPU copying, the interrupt controller records events, and power logic counts activity and requests sleep.

**192. What role does DMA, interrupt, and power-management peripherals have in this project?**

DMA-lite supports word transfers; IRQ pending/enable/clear tracks AES, UART, sensor, and DMA events; counters record CPU, AES, UART, DMA, sensor, and sleep cycles.

**193. Why is DMA, interrupt, and power-management peripherals important to the design?**

These blocks turn the design from a CPU-plus-AES demo into a small measurable security SoC.

**194. How does the project handle or implement DMA, interrupt, and power-management peripherals?**

Each block is MMIO-controlled and clock-enabled rather than driven by unsafe generated clocks.

**195. How was DMA, interrupt, and power-management peripherals verified?**

Directed tests check DMA completion, pending/enable/clear behavior, nonzero activity counts, and sleep-cycle growth.

**196. Which signals or data should be observed when explaining DMA, interrupt, and power-management peripherals?**

DMA busy/done, IRQ pending/enable/line, sleep request, and active-cycle counters are central.

**197. Which result or number supports the discussion of DMA, interrupt, and power-management peripherals?**

The full-SoC scenario has 15 explicit pass criteria covering the integrated transaction.

**198. What is the principal limitation related to DMA, interrupt, and power-management peripherals?**

The DMA is staged and simple, and the CPU lacks full privileged CSR/trap interrupt handling.

**199. What alternative could replace or extend the present approach to DMA, interrupt, and power-management peripherals?**

A bus-master DMA and standard RISC-V machine-mode interrupt/trap subsystem are future upgrades.

**200. How would you defend the project's treatment of DMA, interrupt, and power-management peripherals under a difficult cross-question?**

The current IRQ line is verified as an event/debug path; claiming complete architectural interrupt service would be incorrect.


## Custom Security ISA

**Level:** Intermediate to Advanced

### custom-0 opcode choice

**201. Explain custom-0 opcode choice.**

RISC-V reserves custom opcode spaces so application-specific instructions can be added without colliding with standard encodings.

**202. What role does custom-0 opcode choice have in this project?**

All security commands use the custom-0 opcode 0001011.

**203. Why is custom-0 opcode choice important to the design?**

Using a reserved custom space preserves standard RV32I decoding and makes the extension explicit.

**204. How does the project handle or implement custom-0 opcode choice?**

control_unit/id_stage recognize the opcode and pass a three-bit command toward the integration path.

**205. How was custom-0 opcode choice verified?**

Directed custom instruction words exercise XOR, AES status, AES start, ciphertext read, and clear.

**206. Which signals or data should be observed when explaining custom-0 opcode choice?**

instruction, opcode, funct3, custom_valid, custom_cmd, operands, result, and rd reveal execution.

**207. Which result or number supports the discussion of custom-0 opcode choice?**

Custom commands pass without breaking the standard instruction regression.

**208. What is the principal limitation related to custom-0 opcode choice?**

Standard assemblers do not automatically recognize project-specific mnemonics.

**209. What alternative could replace or extend the present approach to custom-0 opcode choice?**

Use .word encodings initially, then add assembler/binutils support for a mature extension.

**210. How would you defend the project's treatment of custom-0 opcode choice under a difficult cross-question?**

Reserved custom encoding is compliant usage; the semantics remain project-specific and nonportable.

### custom instruction field encoding

**211. Explain custom instruction field encoding.**

The 32-bit instruction retains rd, funct3, rs1, rs2, funct7, and opcode fields in an R-type-like layout.

**212. What role does custom instruction field encoding have in this project?**

funct3 selects CSEC_XOR, AES_STATUS, AES_START, AES_CT0, or AES_CLEAR.

**213. Why is custom instruction field encoding important to the design?**

A small command field gives multiple security operations while preserving register operand conventions.

**214. How does the project handle or implement custom instruction field encoding?**

Decode maps funct3 into custom_cmd; operands are forwarded and a custom result is returned to writeback.

**215. How was custom instruction field encoding verified?**

Each command is encoded and checked against its expected architectural or peripheral effect.

**216. Which signals or data should be observed when explaining custom instruction field encoding?**

funct3 and custom_cmd should match; rd changes only for result-producing commands.

**217. Which result or number supports the discussion of custom instruction field encoding?**

The custom ISA waveform shows decode, command assertion, AES interaction, and result return.

**218. What is the principal limitation related to custom instruction field encoding?**

Only selected low-word operations are exposed; full 128-bit transfer still uses MMIO words.

**219. What alternative could replace or extend the present approach to custom instruction field encoding?**

Vector registers, paired registers, or multi-instruction load/start/read protocols can carry 128-bit data.

**220. How would you defend the project's treatment of custom instruction field encoding under a difficult cross-question?**

The extension accelerates control and selected data operations rather than pretending a 32-bit instruction directly contains a 128-bit block.

### custom instruction pipeline path

**221. Explain custom instruction pipeline path.**

A custom instruction still travels through IF, ID, EX, MEM, and WB, but its command is interpreted by the security integration logic.

**222. What role does custom instruction pipeline path have in this project?**

IF fetches, ID decodes, EX forwards operands, MEM communicates with AES, and WB returns custom_result.

**223. Why is custom instruction pipeline path important to the design?**

Reusing the pipeline minimizes disruption and keeps hazard/writeback behavior consistent.

**224. How does the project handle or implement custom instruction pipeline path?**

Additional control and operand signals are carried through existing stage boundaries.

**225. How was custom instruction pipeline path verified?**

The directed waveform correlates opcode/funct3 with AES start/status/ciphertext behavior.

**226. Which signals or data should be observed when explaining custom instruction pipeline path?**

custom_valid across stages, operands, AES command pulse, custom_result, reg_write, and rd are examined.

**227. Which result or number supports the discussion of custom instruction pipeline path?**

Existing CPU tests continue to pass after the extension, indicating preserved baseline behavior.

**228. What is the principal limitation related to custom instruction pipeline path?**

A multi-cycle AES operation cannot truly complete in one ordinary ALU cycle.

**229. What alternative could replace or extend the present approach to custom instruction pipeline path?**

The instruction can start the accelerator and later poll/read, or the pipeline can stall until completion.

**230. How would you defend the project's treatment of custom instruction pipeline path under a difficult cross-question?**

In this project, custom commands are accelerator-control operations; AES itself remains a multi-cycle engine.

### MMIO versus custom ISA

**231. Explain MMIO versus custom ISA.**

MMIO uses load/store instructions to peripheral registers; a custom ISA expresses selected operations directly in the instruction stream.

**232. What role does MMIO versus custom ISA have in this project?**

Both interfaces are preserved so software portability and instruction-level acceleration can be compared.

**233. Why is MMIO versus custom ISA important to the design?**

MMIO is transparent and flexible, while custom commands can reduce instruction count and encode intent.

**234. How does the project handle or implement MMIO versus custom ISA?**

MMIO decode remains in mem_stage; custom decode generates equivalent AES-facing control/result paths.

**235. How was MMIO versus custom ISA verified?**

Directed tests independently exercise MMIO ECB/CTR behavior and custom AES commands.

**236. Which signals or data should be observed when explaining MMIO versus custom ISA?**

Compare instruction count, bus transactions, custom_valid, MMIO enables, and final AES state.

**237. Which result or number supports the discussion of MMIO versus custom ISA?**

Both paths coexist without removing the original NIST-compatible AES interface.

**238. What is the principal limitation related to MMIO versus custom ISA?**

Custom ISA software requires toolchain and portability support.

**239. What alternative could replace or extend the present approach to MMIO versus custom ISA?**

A standard coprocessor or accelerator interface avoids ISA changes but still needs driver software.

**240. How would you defend the project's treatment of MMIO versus custom ISA under a difficult cross-question?**

The thesis contribution is the comparison and integration path, not a claim that custom ISA is always superior.

### custom ISA hazards and correctness

**241. Explain custom ISA hazards and correctness.**

A custom instruction can create dependencies on source registers, destination registers, and multi-cycle accelerator state.

**242. What role does custom ISA hazards and correctness have in this project?**

The extension reuses register operands/writeback and separates start/status/read commands to respect AES latency.

**243. Why is custom ISA hazards and correctness important to the design?**

Treating AES as a single-cycle combinational operation would violate timing and pipeline semantics.

**244. How does the project handle or implement custom ISA hazards and correctness?**

Forwarding supports operand freshness; software or commands observe busy/done before reading ciphertext.

**245. How was custom ISA hazards and correctness verified?**

Tests start AES, verify status, wait for completion, read CT0, and clear done.

**246. Which signals or data should be observed when explaining custom ISA hazards and correctness?**

Source/destination tags, forwarding, custom command timing, busy, done, and result-valid relationship matter.

**247. Which result or number supports the discussion of custom ISA hazards and correctness?**

Custom operation checks pass together with pipeline hazard activity tests.

**248. What is the principal limitation related to custom ISA hazards and correctness?**

The extension does not implement a formal decoupled request/response protocol or exception model.

**249. What alternative could replace or extend the present approach to custom ISA hazards and correctness?**

A ready/valid coprocessor interface or scoreboarded long-latency instruction unit would be more general.

**250. How would you defend the project's treatment of custom ISA hazards and correctness under a difficult cross-question?**

The correct defense emphasizes controlled multi-command semantics rather than claiming zero-cycle AES latency.


## Directed and Scenario-Based Verification

**Level:** Intermediate

### AES known-answer test

**251. Explain AES known-answer test.**

A known-answer test applies a standardized key/plaintext pair and compares the result against a published ciphertext.

**252. What role does AES known-answer test have in this project?**

The NIST AES-128 ECB vector is programmed through MMIO after integration with the processor.

**253. Why is AES known-answer test important to the design?**

It detects algorithm, byte-order, key-schedule, register-map, and integration errors with one reproducible reference.

**254. How does the project handle or implement AES known-answer test?**

Write key/PT words, assert start, wait for done within the bound, read CT0-CT3, and compare.

**255. How was AES known-answer test verified?**

The test checks done, busy deassertion, and all four ciphertext words.

**256. Which signals or data should be observed when explaining AES known-answer test?**

Key, plaintext, start, busy, done, round, state, round key, and ciphertext are shown.

**257. Which result or number supports the discussion of AES known-answer test?**

Six checks pass: done, busy, and CT0 through CT3; reconstructed ciphertext matches the NIST value.

**258. What is the principal limitation related to AES known-answer test?**

One vector is necessary but not sufficient for broad functional coverage.

**259. What alternative could replace or extend the present approach to AES known-answer test?**

Use multiple NIST vectors, randomized C-reference comparison, and formal properties.

**260. How would you defend the project's treatment of AES known-answer test under a difficult cross-question?**

This test proves the primitive after MMIO integration, not merely a standalone behavioral model.

### directed CPU instruction verification

**261. Explain directed CPU instruction verification.**

Directed verification chooses specific instructions and operands with predetermined expected outcomes.

**262. What role does directed CPU instruction verification have in this project?**

Tests cover arithmetic, immediate, load/store, branch, upper-immediate, jump, system/fence, pseudo, and custom security operations.

**263. Why is directed CPU instruction verification important to the design?**

It provides easy-to-debug evidence that each supported instruction category behaves correctly.

**264. How does the project handle or implement directed CPU instruction verification?**

The testbench loads small programs, runs sufficient cycles, drains the pipeline, and checks registers or memory.

**265. How was directed CPU instruction verification verified?**

Each check reports got, expected, and PASS/FAIL.

**266. Which signals or data should be observed when explaining directed CPU instruction verification?**

PC progression, pipeline controls, ALU/memory results, and final register values support diagnosis.

**267. Which result or number supports the discussion of directed CPU instruction verification?**

The integrated regression totals 107 passes and zero failures.

**268. What is the principal limitation related to directed CPU instruction verification?**

Directed programs do not exhaust all operand combinations or instruction sequences.

**269. What alternative could replace or extend the present approach to directed CPU instruction verification?**

Constrained-random instruction generation and ISA reference-model comparison provide broader confidence.

**270. How would you defend the project's treatment of directed CPU instruction verification under a difficult cross-question?**

The project claims verified supported behavior, not full RISC-V architectural compliance.

### directed peripheral verification

**271. Explain directed peripheral verification.**

Peripheral directed tests program documented registers and check status, data, and side effects.

**272. What role does directed peripheral verification have in this project?**

AES-CTR, sensor, SPI, UART, INTC, DMA-lite, power counters, sleep, and custom commands are exercised.

**273. Why is directed peripheral verification important to the design?**

Each block should be validated independently before relying on a full application scenario.

**274. How does the project handle or implement directed peripheral verification?**

Testbench tasks perform MMIO-like writes/reads and wait for protocol completion.

**275. How was directed peripheral verification verified?**

Expected data, busy/done transitions, pending bits, copied words, and counter increments are checked.

**276. Which signals or data should be observed when explaining directed peripheral verification?**

Peripheral select, write/read enable, address offset, data, status, and output pins are important.

**277. Which result or number supports the discussion of directed peripheral verification?**

The peripheral captures and transcript show all selected blocks passing.

**278. What is the principal limitation related to directed peripheral verification?**

Independent tests may miss cross-peripheral ordering or contention issues.

**279. What alternative could replace or extend the present approach to directed peripheral verification?**

The full-SoC scenario and UVM environment provide system interaction coverage.

**280. How would you defend the project's treatment of directed peripheral verification under a difficult cross-question?**

Layering verification is intentional: isolate faults first, then prove integration.

### randomized smoke verification

**281. Explain randomized smoke verification.**

A random smoke test varies representative data and control values while remaining lighter than a full constrained-random environment.

**282. What role does randomized smoke verification have in this project?**

It changes custom-XOR operands, sensor samples, DMA source values, and UART bytes.

**283. Why is randomized smoke verification important to the design?**

It quickly detects designs that only pass fixed constants.

**284. How does the project handle or implement randomized smoke verification?**

A deterministic seed generates repeatable values and the test compares each result.

**285. How was randomized smoke verification verified?**

Failures include the seed and expected/observed data for reproduction.

**286. Which signals or data should be observed when explaining randomized smoke verification?**

Random inputs, transaction index, selected peripheral, and pass/fail counters are useful.

**287. Which result or number supports the discussion of randomized smoke verification?**

The smoke regression passes before the heavier UVM tests are run.

**288. What is the principal limitation related to randomized smoke verification?**

Random smoke does not provide class-based stimulus, a reference model, or complete coverage closure.

**289. What alternative could replace or extend the present approach to randomized smoke verification?**

UVM constrained random with coverage and scoreboarding is the stronger methodology.

**290. How would you defend the project's treatment of randomized smoke verification under a difficult cross-question?**

Call it deterministic randomized smoke, not exhaustive random verification.

### full-SoC scenario

**291. Explain full-SoC scenario.**

Scenario-based verification executes a meaningful application transaction across multiple blocks.

**292. What role does full-SoC scenario have in this project?**

The flow is sensor to CPU/RAM to DMA to AES-CTR to UART to IRQ/power to sleep.

**293. Why is full-SoC scenario important to the design?**

Passing isolated unit tests does not prove that sequencing, handshakes, and data routing work together.

**294. How does the project handle or implement full-SoC scenario?**

The CPU enables events, reads sensor data, stages a record, configures DMA/AES/UART, checks pending state/counters, then requests sleep.

**295. How was full-SoC scenario verified?**

Fifteen explicit criteria cover data movement, encryption, transmission, events, activity, and final state.

**296. Which signals or data should be observed when explaining full-SoC scenario?**

Sensor data, DMA addresses/data/done, AES input/output/done, UART busy/done, IRQ pending, counters, and sleep are correlated.

**297. Which result or number supports the discussion of full-SoC scenario?**

The standalone scenario reports 15 checks passed.

**298. What is the principal limitation related to full-SoC scenario?**

It is one representative use case rather than every automotive operating condition.

**299. What alternative could replace or extend the present approach to full-SoC scenario?**

A scenario suite can add reset-during-transfer, UART backpressure, replay, malformed sensor data, and fault injection.

**300. How would you defend the project's treatment of full-SoC scenario under a difficult cross-question?**

The scenario proves integrated functional flow; it does not certify ISO 26262 safety or automotive cybersecurity compliance.


## UVM, C-DPI, Scoreboarding, and Coverage

**Level:** Advanced Verification

### UVM transaction and sequence

**301. Explain UVM transaction and sequence.**

A UVM transaction is a data object; a sequence generates ordered transactions for a sequencer and driver.

**302. What role does UVM transaction and sequence have in this project?**

Each transaction contains randomized 128-bit plaintext, 128-bit key, 64-bit nonce, and 64-bit counter.

**303. Why is UVM transaction and sequence important to the design?**

Transaction-level abstraction separates stimulus intent from signal-level driving.

**304. How does the project handle or implement UVM transaction and sequence?**

A deterministic pseudo-random sequence creates reproducible transactions for a selected seed and count.

**305. How was UVM transaction and sequence verified?**

The same transaction is sent to RTL programming logic and the independent C-DPI reference.

**306. Which signals or data should be observed when explaining UVM transaction and sequence?**

Transaction number, seed, plaintext, key, nonce, counter, expected ciphertext, and status are logged.

**307. Which result or number supports the discussion of UVM transaction and sequence?**

The closure run executes 100 randomized transactions.

**308. What is the principal limitation related to UVM transaction and sequence?**

Randomization quality depends on constraints, seed diversity, and meaningful coverage definitions.

**309. What alternative could replace or extend the present approach to UVM transaction and sequence?**

Directed sequences target corners; virtual sequences can coordinate multiple interfaces.

**310. How would you defend the project's treatment of UVM transaction and sequence under a difficult cross-question?**

Repeatability is a strength: a failing seed must reproduce the exact transaction.

### UVM driver and interface

**311. Explain UVM driver and interface.**

The driver converts transactions into pin- or register-level operations through a virtual interface.

**312. What role does UVM driver and interface have in this project?**

It writes AES key, plaintext, nonce, counter, starts CTR, reads ciphertext, and feeds the UART path.

**313. Why is UVM driver and interface important to the design?**

Encapsulation prevents tests from manually toggling every DUT signal.

**314. How does the project handle or implement UVM driver and interface?**

Interface tasks perform synchronized MMIO-style reads/writes and UART configuration.

**315. How was UVM driver and interface verified?**

The driver waits for busy/done with timeouts and reports protocol errors.

**316. Which signals or data should be observed when explaining UVM driver and interface?**

MMIO address, data, write/read enable, AES status, and UART control show correct driving.

**317. Which result or number supports the discussion of UVM driver and interface?**

Twenty-five-transaction seed runs and the 100-transaction closure run complete without UVM errors.

**318. What is the principal limitation related to UVM driver and interface?**

The current UVM top focuses primarily on the AES/UART end-to-end path rather than executing the complete CPU pipeline for every transaction.

**319. What alternative could replace or extend the present approach to UVM driver and interface?**

A full-SoC UVM environment could drive instruction memory and monitor architectural retirement.

**320. How would you defend the project's treatment of UVM driver and interface under a difficult cross-question?**

Be precise about verification scope: UVM proves cryptographic/UART behavior; directed scenario tests prove broader SoC integration.

### independent C-DPI reference model

**321. Explain independent C-DPI reference model.**

DPI allows SystemVerilog to call independently compiled C functions used as a golden reference.

**322. What role does independent C-DPI reference model have in this project?**

The C model implements AES-128 encryption and CTR XOR independently from the SystemVerilog RTL.

**323. Why is independent C-DPI reference model important to the design?**

Comparing RTL against separate code reduces the risk of repeating the same RTL bug in the expected-value calculation.

**324. How does the project handle or implement independent C-DPI reference model?**

The transaction words are converted to bytes, nonce and counter form the counter block, AES generates a keystream, and plaintext is XORed.

**325. How was independent C-DPI reference model verified?**

RTL ciphertext must equal C ciphertext, and C-side CTR decryption must reproduce the original plaintext.

**326. Which signals or data should be observed when explaining independent C-DPI reference model?**

RTL ciphertext, reference ciphertext, decrypted plaintext, and equality flags are central.

**327. Which result or number supports the discussion of independent C-DPI reference model?**

The UVM transcript reports ciphertext, decrypt, input, and UART matches.

**328. What is the principal limitation related to independent C-DPI reference model?**

Independence is logical, not mathematical proof; both implementations can still misunderstand byte ordering or the specification.

**329. What alternative could replace or extend the present approach to independent C-DPI reference model?**

Cross-check with a third library such as OpenSSL/Python Crypto and standard CTR vectors.

**330. How would you defend the project's treatment of independent C-DPI reference model under a difficult cross-question?**

The C model was not synthesized; it exists solely as verification reference code.

### UART monitor and scoreboard

**331. Explain UART monitor and scoreboard.**

A passive monitor reconstructs observed behavior; a scoreboard compares observed transactions with expected transactions.

**332. What role does UART monitor and scoreboard have in this project?**

The monitor samples the physical uart_tx serial waveform, reconstructs newline-terminated records, and forwards them to the scoreboard.

**333. Why is UART monitor and scoreboard important to the design?**

Checking the serial pin proves more than checking an internal parallel UART register.

**334. How does the project handle or implement UART monitor and scoreboard?**

The monitor detects start, samples data bits at the configured divisor, checks stop, assembles bytes, and builds a line.

**335. How was UART monitor and scoreboard verified?**

The scoreboard compares the observed text/data record against the C-derived expected record.

**336. Which signals or data should be observed when explaining UART monitor and scoreboard?**

UART pin, bit index, byte value, line buffer, expected line, observed line, and match count are useful.

**337. Which result or number supports the discussion of UART monitor and scoreboard?**

The final run reports 100 UART matches.

**338. What is the principal limitation related to UART monitor and scoreboard?**

The monitor assumes the configured simulation baud divisor and does not model analog clock drift or metastability.

**339. What alternative could replace or extend the present approach to UART monitor and scoreboard?**

A protocol VIP can add parity, framing-error, jitter, and baud-tolerance checks.

**340. How would you defend the project's treatment of UART monitor and scoreboard under a difficult cross-question?**

The scoreboard is end-to-end because it consumes reconstructed serial output rather than trusting DUT internals.

### functional coverage

**341. Explain functional coverage.**

Functional coverage measures whether planned categories and combinations of behavior were exercised.

**342. What role does functional coverage have in this project?**

Coverage includes input quadrants, low nibbles, nonce/counter crosses, and input/cipher/decrypt/UART match outcomes.

**343. Why is functional coverage important to the design?**

A passing test count does not show whether important value classes and crosses were visited.

**344. How does the project handle or implement functional coverage?**

Native covergroups exist under an option; a portable collector tracks equivalent bins in the available Starter Edition flow.

**345. How was functional coverage verified?**

Coverage is sampled per randomized transaction and accumulated until the planned total is reached.

**346. Which signals or data should be observed when explaining functional coverage?**

Transaction count, individual bin masks/counts, cross count, total covered, and match counts explain closure.

**347. Which result or number supports the discussion of functional coverage?**

The final run reports 114/114 portable bins and 100 UART matches with zero UVM errors.

**348. What is the principal limitation related to functional coverage?**

100% of a coverage model means the defined bins were hit; it does not prove the model contains every possible bug scenario.

**349. What alternative could replace or extend the present approach to functional coverage?**

Add code coverage, assertions, mutation testing, formal properties, and requirement-based coverage.

**350. How would you defend the project's treatment of functional coverage under a difficult cross-question?**

Coverage closure is meaningful only when each bin maps to a verification intent.


## Synthesis, Timing, Power, and Netlists

**Level:** Advanced RTL

### Cadence Genus standalone AES comparison

**351. Explain Cadence Genus standalone AES comparison.**

The standalone study compares a baseline AES and the proposed reusable AES under the same ASIC synthesis environment.

**352. What role does Cadence Genus standalone AES comparison have in this project?**

Cadence Genus with a TSMC 55 nm low-power RVT library reports cell count, area, power, and timing for the AES core.

**353. Why is Cadence Genus standalone AES comparison important to the design?**

Keeping technology and constraints consistent makes the architectural comparison meaningful.

**354. How does the project handle or implement Cadence Genus standalone AES comparison?**

Only the standalone AES result domain is used for the baseline-versus-proposed ASIC comparison.

**355. How was Cadence Genus standalone AES comparison verified?**

Functional AES correctness is established before interpreting synthesis reports.

**356. Which signals or data should be observed when explaining Cadence Genus standalone AES comparison?**

Area, cell, power, timing, QoR, netlist, SDC, and SDF reports are the evidence.

**357. Which result or number supports the discussion of Cadence Genus standalone AES comparison?**

Baseline/proposed cell counts are 83,352/2,694; areas are 202,949.64/11,841.48 square micrometres; total powers are 21.9/0.853 mW.

**358. What is the principal limitation related to Cadence Genus standalone AES comparison?**

Synthesis estimates depend on library, constraints, activity assumptions, and flow settings.

**359. What alternative could replace or extend the present approach to Cadence Genus standalone AES comparison?**

Post-layout extraction and gate-level activity would provide more accurate silicon estimates.

**360. How would you defend the project's treatment of Cadence Genus standalone AES comparison under a difficult cross-question?**

Do not mix these ASIC numbers with the integrated Quartus FPGA SoC numbers.

### Quartus integrated FPGA resources

**361. Explain Quartus integrated FPGA resources.**

FPGA resource reports show how the complete processor maps to the target programmable device.

**362. What role does Quartus integrated FPGA resources have in this project?**

Quartus Prime 23.1std.1 Build 993 targets Cyclone V 5CGXFC7C7F23C8.

**363. Why is Quartus integrated FPGA resources important to the design?**

The integrated result demonstrates synthesizability and implementation cost beyond simulation.

**364. How does the project handle or implement Quartus integrated FPGA resources?**

The project includes the CPU, AES, UART, sensor/SPI, DMA, interrupt, counters, memories, and debug outputs.

**365. How was Quartus integrated FPGA resources verified?**

Successful Analysis and Synthesis and Fitter completion provide implementation evidence.

**366. Which signals or data should be observed when explaining Quartus integrated FPGA resources?**

ALMs, registers, pins, memory bits, DSPs, PLLs, fitter status, and warnings are reported.

**367. Which result or number supports the discussion of Quartus integrated FPGA resources?**

13,257 of 56,480 ALMs (23%), 11,154 registers, 106 of 268 pins (40%), and zero DSP/block-memory/PLL usage are reported.

**368. What is the principal limitation related to Quartus integrated FPGA resources?**

Many debug outputs increase pin count; missing physical pin assignments prevent immediate board deployment.

**369. What alternative could replace or extend the present approach to Quartus integrated FPGA resources?**

Internal SignalTap/debug buses and a smaller physical interface would reduce external pins.

**370. How would you defend the project's treatment of Quartus integrated FPGA resources under a difficult cross-question?**

Zero block memory reflects the current inferred implementation and test-oriented architecture, not a general claim that RISC-V needs no memory.

### timing analysis

**371. Explain timing analysis.**

Static timing analysis checks whether data paths meet setup, hold, and pulse-width requirements without simulating every vector.

**372. What role does timing analysis have in this project?**

The main clock constraint is 20 ns, equivalent to 50 MHz.

**373. Why is timing analysis important to the design?**

Functional correctness is insufficient if the synthesized circuit cannot meet its clock period.

**374. How does the project handle or implement timing analysis?**

TimeQuest analyzes the post-fit netlist across reported corners.

**375. How was timing analysis verified?**

Positive setup and hold slack indicate timing closure for the constraint.

**376. Which signals or data should be observed when explaining timing analysis?**

Clock period, worst setup slack, worst hold slack, corner, and critical endpoints are required.

**377. Which result or number supports the discussion of timing analysis?**

The final report uses 2.577 ns setup slack and 0.371 ns hold slack; estimated critical delay is 20-2.577=17.423 ns.

**378. What is the principal limitation related to timing analysis?**

The result applies to the selected device, constraints, fitter result, and modeled corners.

**379. What alternative could replace or extend the present approach to timing analysis?**

Tighter constraints, floorplanning, pipelining, or logic restructuring can improve Fmax.

**380. How would you defend the project's treatment of timing analysis under a difficult cross-question?**

Do not confuse earlier post-map pessimistic slack with final post-fit sign-off timing.

### power analysis

**381. Explain power analysis.**

Power analysis estimates static, dynamic, and I/O contributions under device, temperature, voltage, clock, and activity assumptions.

**382. What role does power analysis have in this project?**

Quartus reports vectorless post-fit power for the complete FPGA SoC.

**383. Why is power analysis important to the design?**

Power is a central motivation, but confidence level and activity source must be disclosed.

**384. How does the project handle or implement power analysis?**

Fitted-netlist capacitance/delay is combined with estimated switching activity.

**385. How was power analysis verified?**

The report is checked for total, component breakdown, thermal estimate, toggle-rate assumptions, and confidence.

**386. Which signals or data should be observed when explaining power analysis?**

Core static, core dynamic, I/O, total thermal power, junction temperature, and confidence are key.

**387. Which result or number supports the discussion of power analysis?**

Total is 519.72 mW: 350.49 mW static, 147.14 mW dynamic, and 22.09 mW I/O.

**388. What is the principal limitation related to power analysis?**

This is a low-confidence vectorless estimate, not measured board power or VCD-driven sign-off.

**389. What alternative could replace or extend the present approach to power analysis?**

Use SAIF/VCD activity from representative workloads and validate with board current measurement.

**390. How would you defend the project's treatment of power analysis under a difficult cross-question?**

The strong low-power comparison comes from the controlled Genus AES study; the Quartus number characterizes the complete FPGA prototype.

### RTL and synthesized netlists

**391. Explain RTL and synthesized netlists.**

An RTL view shows logical hierarchy before technology mapping; a synthesized netlist shows mapped logic and optimized connectivity.

**392. What role does RTL and synthesized netlists have in this project?**

Figures include the complete SoC hierarchy and expanded EX- and MEM-stage netlists.

**393. Why is RTL and synthesized netlists important to the design?**

Netlists confirm that modules elaborate, connect, and survive synthesis as intended.

**394. How does the project handle or implement RTL and synthesized netlists?**

The MEM hierarchy contains RAM/load-store and the MMIO peripheral branches; EX contains operand selection, forwarding, ALU, and comparison.

**395. How was RTL and synthesized netlists verified?**

Netlist inspection complements reports by locating the actual integrated structures.

**396. Which signals or data should be observed when explaining RTL and synthesized netlists?**

Hierarchy names, fan-in/out, muxes, registers, peripheral instances, and optimized-away logic matter.

**397. Which result or number supports the discussion of RTL and synthesized netlists?**

Quartus successfully elaborates and fits the top module riscv_aes_advancements.

**398. What is the principal limitation related to RTL and synthesized netlists?**

A netlist image is structural evidence, not proof of functional correctness or timing by itself.

**399. What alternative could replace or extend the present approach to RTL and synthesized netlists?**

Formal equivalence and gate-level simulation provide stronger implementation checks.

**400. How would you defend the project's treatment of RTL and synthesized netlists under a difficult cross-question?**

Explain why synthesis may remove registers with no fanout and why observable debug outputs help preserve research-visible logic.


## Application, Security Limits, and Production Path

**Level:** Advanced System

### automotive telemetry application

**401. Explain automotive telemetry application.**

The chosen application is a secure sensor gateway for moderate-rate autonomous-vehicle telemetry.

**402. What role does automotive telemetry application have in this project?**

Candidate data includes IMU acceleration/angular velocity, wheel speed, radar metadata, timestamps, diagnostic flags, and sensor health.

**403. Why is automotive telemetry application important to the design?**

Distributed vehicle sensors create a realistic need for local confidentiality before records leave the sensor/ECU boundary.

**404. How does the project handle or implement automotive telemetry application?**

Sensor/SPI acquisition feeds CPU/DMA staging, AES-CTR encryption, UART demonstration output, interrupt monitoring, counters, and sleep.

**405. How was automotive telemetry application verified?**

The full-SoC scenario follows this complete path.

**406. Which signals or data should be observed when explaining automotive telemetry application?**

Plaintext record, counter, ciphertext, transmitted bytes, event pending, and sleep state show the application.

**407. Which result or number supports the discussion of automotive telemetry application?**

A 128-bit record is encrypted as one AES block and the scenario passes 15 checks.

**408. What is the principal limitation related to automotive telemetry application?**

UART and register keys are demonstrators, not automotive-qualified interfaces or secure storage.

**409. What alternative could replace or extend the present approach to automotive telemetry application?**

CAN-FD/Automotive Ethernet, secure key hardware, authenticated encryption, and safety diagnostics are required.

**410. How would you defend the project's treatment of automotive telemetry application under a difficult cross-question?**

Call it an RTL/FPGA proof of concept for an automotive sensor-security node, not a production ECU.

### 128-bit telemetry record packing

**411. Explain 128-bit telemetry record packing.**

Packing maps multiple sensor fields into one fixed 128-bit AES plaintext block.

**412. What role does 128-bit telemetry record packing have in this project?**

PT3 carries a 32-bit timestamp/record ID; PT2 and PT1 pack acceleration and angular velocity; PT0 carries wheel speed, diagnostics, and health.

**413. Why is 128-bit telemetry record packing important to the design?**

A deterministic record format aligns software, DMA, AES registers, UART formatting, and receiver decoding.

**414. How does the project handle or implement 128-bit telemetry record packing?**

Four 32-bit CPU words form the 128-bit plaintext register set.

**415. How was 128-bit telemetry record packing verified?**

The same ordering is used by RTL, the C reference model, and the expected UART record.

**416. Which signals or data should be observed when explaining 128-bit telemetry record packing?**

PT0-PT3 and corresponding ciphertext words should be labeled with bit ranges.

**417. Which result or number supports the discussion of 128-bit telemetry record packing?**

The complete 32+32+32+32 layout equals one AES-128 block.

**418. What is the principal limitation related to 128-bit telemetry record packing?**

Real sensor scaling, signed formats, endianness, and schema versioning must be standardized.

**419. What alternative could replace or extend the present approach to 128-bit telemetry record packing?**

Use a framed packet with version, sequence number, payload length, ciphertext, and authentication tag.

**420. How would you defend the project's treatment of 128-bit telemetry record packing under a difficult cross-question?**

A timestamp/monotonic ID can assist replay handling, but only if authenticated and checked.

### receiver decryption

**421. Explain receiver decryption.**

CTR decryption regenerates the same keystream and XORs it with ciphertext.

**422. What role does receiver decryption have in this project?**

The receiver uses the same key, nonce, and counter to compute P_i = C_i XOR AES_K(N || CTR_i).

**423. Why is receiver decryption important to the design?**

XOR is self-inverse, so the AES encryption datapath serves both directions.

**424. How does the project handle or implement receiver decryption?**

The independent C model performs this operation and checks recovered plaintext.

**425. How was receiver decryption verified?**

The scoreboard requires decrypted data to equal the original randomized plaintext.

**426. Which signals or data should be observed when explaining receiver decryption?**

Input plaintext, RTL ciphertext, reference keystream/ciphertext, decrypted value, and match flag are examined.

**427. Which result or number supports the discussion of receiver decryption?**

The UVM end-to-end logs report decrypt match for all completed transactions.

**428. What is the principal limitation related to receiver decryption?**

Loss of nonce/counter synchronization prevents correct recovery; reuse creates a security failure.

**429. What alternative could replace or extend the present approach to receiver decryption?**

Transmit an authenticated sequence/nonce field and maintain replay-safe session state.

**430. How would you defend the project's treatment of receiver decryption under a difficult cross-question?**

The key is not sent with ciphertext; it must be provisioned securely at both endpoints.

### security limitations

**431. Explain security limitations.**

A limitation statement defines what the prototype does not guarantee.

**432. What role does security limitations have in this project?**

The current design lacks authentication tags, replay protection, secure key storage, complete CSR/trap handling, side-channel hardening, and production network interfaces.

**433. Why is security limitations important to the design?**

Transparent limitations make the research technically credible and prevent unsafe conclusions.

**434. How does the project handle or implement security limitations?**

Nonce/counter and key registers are intentionally visible for verification and experimentation.

**435. How was security limitations verified?**

Tests prove functional encryption and transmission, not resistance to physical or active attacks.

**436. Which signals or data should be observed when explaining security limitations?**

No auth-tag output, replay window, key-vault status, or privileged trap sequence exists in the current RTL.

**437. Which result or number supports the discussion of security limitations?**

The report explicitly labels Quartus power low confidence and the system an RTL/FPGA proof of concept.

**438. What is the principal limitation related to security limitations?**

Confidentiality without integrity can allow controlled ciphertext modification.

**439. What alternative could replace or extend the present approach to security limitations?**

AES-GCM/HMAC, secure key storage, protected debug, monotonic counters, fault detection, and certified interfaces.

**440. How would you defend the project's treatment of security limitations under a difficult cross-question?**

A convincing answer acknowledges the gap and gives a concrete engineering upgrade.

### production upgrade path

**441. Explain production upgrade path.**

The production path replaces research-friendly interfaces and controls with authenticated, protected, standardized mechanisms.

**442. What role does production upgrade path have in this project?**

CTR moves to authenticated encryption; register key moves to secure storage; UART moves to CAN-FD/Ethernet; debug IRQ moves to CSR/trap handling.

**443. Why is production upgrade path important to the design?**

Automotive deployment requires cybersecurity, safety, fault handling, diagnostics, and lifecycle key management.

**444. How does the project handle or implement production upgrade path?**

Future blocks include secure boot, MAC/tag verification, rollback protection, key vault/PUF, watchdogs, ECC, and network controllers.

**445. How was production upgrade path verified?**

Fault injection, negative security tests, formal properties, code coverage, gate-level checks, and hardware measurements would be added.

**446. Which signals or data should be observed when explaining production upgrade path?**

Authentication result, replay counter, secure-boot state, key access violations, bus errors, and safety faults become required.

**447. Which result or number supports the discussion of production upgrade path?**

The current architecture and verification environment provide a modular base for these additions.

**448. What is the principal limitation related to production upgrade path?**

Adding security features increases area, latency, verification effort, and certification scope.

**449. What alternative could replace or extend the present approach to production upgrade path?**

A commercial secure element can offload key storage and authentication while this processor handles dataflow.

**450. How would you defend the project's treatment of production upgrade path under a difficult cross-question?**

The thesis demonstrates an extensible foundation, not completed ISO 21434 or ISO 26262 qualification.


## Research Contribution, Figures, and Viva Defense

**Level:** Expert Cross-Examination

### research novelty and contribution

**451. Explain research novelty and contribution.**

The contribution combines a measured iterative reusable AES microarchitecture with processor integration, AES-CTR, MMIO/custom ISA control, peripherals, and layered verification.

**452. What role does research novelty and contribution have in this project?**

The standalone paper result and integrated M.Tech SoC result are treated as separate but connected research domains.

**453. Why is research novelty and contribution important to the design?**

This separation prevents ASIC AES metrics from being incorrectly presented as full-SoC FPGA metrics.

**454. How does the project handle or implement research novelty and contribution?**

Stable AES primitive plus wrappers and modular peripherals preserve the original working design.

**455. How was research novelty and contribution verified?**

Known-answer, directed, randomized, UVM C-DPI, coverage, scenario, Genus, and Quartus evidence are all traceable.

**456. Which signals or data should be observed when explaining research novelty and contribution?**

The report's architecture, verification, result, and traceability figures show the chain from idea to evidence.

**457. Which result or number supports the discussion of research novelty and contribution?**

Key headline results are 94.17% AES area reduction, 96.10% AES power reduction, 107/0 directed checks, 114/114 bins, and timing-clean 50 MHz FPGA implementation.

**458. What is the principal limitation related to research novelty and contribution?**

The processor is a research prototype and the reusable AES trades latency for efficiency.

**459. What alternative could replace or extend the present approach to research novelty and contribution?**

Prior work often emphasizes software, fully unrolled throughput, or isolated accelerators; this work emphasizes reuse plus system verification.

**460. How would you defend the project's treatment of research novelty and contribution under a difficult cross-question?**

Novelty should be framed as architecture, integration, measurement, and verification contribution, not ownership of standard algorithms.

### interpretation of report figures

**461. Explain interpretation of report figures.**

A technical figure should communicate one claim: architecture, flow, evidence, result, limitation, or upgrade path.

**462. What role does interpretation of report figures have in this project?**

Figures cover security foundations, AES modes/tradeoffs, CPU/MMIO hierarchy, UVM, netlists, power, telemetry, threats, applications, and waveforms.

**463. Why is interpretation of report figures important to the design?**

Visual evidence lets an examiner connect prose to implementation without reading every RTL file.

**464. How does the project handle or implement interpretation of report figures?**

Detailed captions explain what to observe while the List of Figures uses concise titles.

**465. How was interpretation of report figures verified?**

Waveform figures are paired with transcript excerpts and expected-versus-observed interpretation.

**466. Which signals or data should be observed when explaining interpretation of report figures?**

For each figure, identify input, transformation/control, output, and the single conclusion.

**467. Which result or number supports the discussion of interpretation of report figures?**

The final report compiles as an 80-page A4 portrait document with no overfull boxes or unresolved references.

**468. What is the principal limitation related to interpretation of report figures?**

A diagram is explanatory and may abstract handshakes or timing details.

**469. What alternative could replace or extend the present approach to interpretation of report figures?**

Use RTL/netlist views and waveform captures when exact implementation evidence is required.

**470. How would you defend the project's treatment of interpretation of report figures under a difficult cross-question?**

Never read the figure word-for-word; explain its engineering message and relate it to a measured result.

### reproducibility and traceability

**471. Explain reproducibility and traceability.**

Reproducibility means another engineer can locate sources, run commands, and connect claims to evidence.

**472. What role does reproducibility and traceability have in this project?**

The appendices provide MMIO map, custom encoding, commands, UVM hierarchy, and result-to-source paths.

**473. Why is reproducibility and traceability important to the design?**

Large EDA projects can otherwise mix stale logs, vendor results, or unverifiable numbers.

**474. How does the project handle or implement reproducibility and traceability?**

Results are separated into directed, UVM, coverage, scenario, Quartus SoC, and Genus AES domains.

**475. How was reproducibility and traceability verified?**

Exact seeds, transaction counts, tool versions, target device, clock constraint, and report filenames are documented.

**476. Which signals or data should be observed when explaining reproducibility and traceability?**

A claim should point to a transcript, waveform, synthesis report, or source module.

**477. Which result or number supports the discussion of reproducibility and traceability?**

Quartus version 23.1std.1 Build 993 and target 5CGXFC7C7F23C8 are explicitly recorded.

**478. What is the principal limitation related to reproducibility and traceability?**

Tool/library availability and licenses can affect reproducibility on another machine.

**479. What alternative could replace or extend the present approach to reproducibility and traceability?**

Containerized open-source flows improve portability but may not reproduce vendor-specific implementation.

**480. How would you defend the project's treatment of reproducibility and traceability under a difficult cross-question?**

When two reports disagree, explain scope, tool stage, corner, and timestamp instead of selecting the preferred number.

### ownership and engineering process

**481. Explain ownership and engineering process.**

Engineering ownership means understanding and defending the problem, architecture, interfaces, tradeoffs, verification intent, and interpretation of results.

**482. What role does ownership and engineering process have in this project?**

Your defensible contribution is selecting the reusable-AES security-processor direction, defining the integrated architecture and application, guiding iterations, validating outputs, and organizing evidence.

**483. Why is ownership and engineering process important to the design?**

Modern engineering uses compilers, EDA tools, scripts, libraries, and coding assistants; responsibility remains with the engineer who reviews and validates the result.

**484. How does the project handle or implement ownership and engineering process?**

Automation assisted repetitive coding, debugging, regression scripting, report extraction, and document preparation; final claims were checked against RTL and tool reports.

**485. How was ownership and engineering process verified?**

You should be able to explain every interface, test objective, expected result, limitation, and headline number without relying on the automation.

**486. Which signals or data should be observed when explaining ownership and engineering process?**

The strongest demonstration of ownership is a coherent explanation and the ability to trace an answer to code or evidence.

**487. Which result or number supports the discussion of ownership and engineering process?**

The project has reproducible source, simulations, reports, waveforms, scripts, and a traceability appendix.

**488. What is the principal limitation related to ownership and engineering process?**

Do not claim hand authorship of every generated line or deny tool assistance if directly asked under an academic policy.

**489. What alternative could replace or extend the present approach to ownership and engineering process?**

A truthful phrasing is: I defined and reviewed the architecture and verification intent, used automation for implementation support and debugging, and independently validated the final results.

**490. How would you defend the project's treatment of ownership and engineering process under a difficult cross-question?**

Your credibility comes from technical mastery and transparent responsibility, not from pretending that engineering tools were absent.

### hard examiner challenges

**491. Explain hard examiner challenges.**

Hard cross-questions test whether claims remain valid under alternative explanations, missing assumptions, or system-level constraints.

**492. What role does hard examiner challenges have in this project?**

Likely challenges concern CTR authentication, nonce reuse, key exposure, exact latency, UVM scope, vectorless power, pin assignments, and automotive qualification.

**493. Why is hard examiner challenges important to the design?**

Preparing limitations is as important as memorizing strengths.

**494. How does the project handle or implement hard examiner challenges?**

Answer in four steps: state the fact, cite project evidence, acknowledge the limitation, and give the engineering remedy.

**495. How was hard examiner challenges verified?**

Distinguish functional proof, coverage evidence, timing closure, synthesis estimate, and physical measurement.

**496. Which signals or data should be observed when explaining hard examiner challenges?**

Listen for words such as 'prove', 'all', 'secure', 'low power', 'compliant', and 'production ready'; qualify them carefully.

**497. Which result or number supports the discussion of hard examiner challenges?**

The strongest verified statements are exact AES correctness, passing regressions, planned-bin closure, successful fit, positive timing slack, and controlled standalone AES comparison.

**498. What is the principal limitation related to hard examiner challenges?**

No test suite proves absence of all bugs, and no synthesis report equals silicon measurement.

**499. What alternative could replace or extend the present approach to hard examiner challenges?**

Propose formal verification, authenticated encryption, activity-based power, board measurements, and certification-oriented verification.

**500. How would you defend the project's treatment of hard examiner challenges under a difficult cross-question?**

A mature answer can say 'that is outside the present scope' and then describe exactly how it would be addressed.

## Supplementary Complete-SoC Genus HVT Cross-Questions

**501. What is the final conclusion from the combined AES plus RISC-V Genus synthesis?**

The result is good for a synthesis-stage research prototype. The complete SoC elaborates and maps without unresolved references, meets the 50 MHz setup constraint with +2.315 ns slack, and uses only HVT cells. It is not final ASIC sign-off because placement, routed parasitics, clock-tree synthesis, activity-based power, and multi-corner hold analysis are still pending.

**502. Which exact numbers support that positive conclusion?**

Genus reports 50,968 mapped leaf cells, 135,947.599 square micrometres of mapped cell area, +2.315 ns worst setup slack, zero total negative slack, zero violating setup paths, 1.43753 mW vectorless total power, and 0.002084 mW leakage power.

**503. Why was an HVT library selected?**

High-threshold-voltage cells reduce subthreshold leakage and are suitable for energy-constrained designs where maximum frequency is not the only objective. The tradeoff is increased propagation delay compared with SVT or LVT cells.

**504. Does the HVT result prove that the complete SoC is low power?**

It provides encouraging low-leakage synthesis evidence, not complete proof. HVT mapping produces a very small reported leakage component, but the power analysis is vectorless and pre-layout. Activity-derived SAIF or VCD, clock-tree power, routed capacitance, and preferably silicon or board measurement are required for a stronger claim.

**505. Why is internal power 90.29 percent even though HVT cells were used?**

HVT primarily reduces leakage. Internal power remains high relative to leakage because the design contains 10,848 sequential cells, register-based storage, clocked pipeline state, AES state registers, counters, and peripheral registers. Reducing internal power requires activity reduction, memory macros, clock-enable refinement, and physical power optimization.

**506. Why does the MEM-stage hierarchy occupy 92.13 percent of mapped cell area?**

The hierarchy contains data memory synthesized from registers, the AES subsystem, MMIO address decoding, peripheral read multiplexing, sensor/SPI, UART, DMA-lite, interrupt logic, and power management. It is therefore the integration hub rather than a small conventional pipeline stage.

**507. Is the 56.55 MHz value a sign-off Fmax result?**

No. It is a constraint-equivalent estimate calculated from the 20 ns period and +2.3152 ns setup slack. It is useful for interpretation, but sign-off Fmax requires physical implementation and multi-corner timing analysis with extracted interconnect and propagated clocks.

**508. Can the 1.43753 mW Genus estimate be compared directly with the 519.72 mW Quartus estimate?**

No. Genus reports a pre-layout ASIC-style cell estimate using GPDK045 HVT cells, while Quartus reports fitted Cyclone V FPGA thermal power including FPGA static and I/O contributions. The technologies, power models, physical assumptions, and result meanings are different.

**509. What is the biggest weakness revealed by the combined Genus reports?**

The largest structural weakness is area concentration in the MEM-stage hierarchy, particularly register-based storage and the wide peripheral integration network. The largest evidence limitation is that power and timing are pre-layout estimates rather than activity-based and post-route sign-off results.

**510. What should be done next to improve and validate the combined SoC?**

Infer or instantiate SRAM macros, reduce unnecessary debug buses, partition the MMIO interconnect, annotate realistic full-SoC activity, run Innovus placement and routing, perform Tempus slow-corner setup and fast-corner hold analysis, and compare the optimized result against the present HVT baseline.

## Final 20-Minute Revision Strategy

1. Memorize the exact fact sheet and never mix standalone 55 nm Genus AES results, complete-SoC GPDK045 HVT Genus results, and Quartus integrated-FPGA results.
2. Practice the five-stage pipeline, MMIO map, custom opcode, AES-CTR equation, and sensor-to-UART flow without notes.
3. For every waveform, say stimulus, transition, observed result, and conclusion.
4. For every result, say tool, design scope, technology/device, constraint, value, and limitation.
5. Lead with the contribution, but voluntarily state latency, authentication, key-storage, UART, IRQ, and power-estimation limitations.
6. Never claim production automotive qualification. Call it a synthesizable RTL/FPGA proof of concept with a concrete production upgrade path.

## Ten Sentences Worth Memorizing

1. The top module is `riscv_aes_advancements`, and the MEM stage is the central MMIO integration point.
2. The AES primitive is iterative and hardware reusable, so it trades latency for substantial area and switching reduction.
3. ECB is retained for the standard known-answer test, while CTR is selected for stream-friendly sensor-record encryption.
4. CTR encryption is `C_i = P_i XOR AES_K(nonce || counter_i)`, and decryption uses the same operation.
5. The custom extension uses RISC-V custom-0 opcode `0001011` and supplements rather than replaces MMIO.
6. The integrated directed regression reports 107 passes and zero failures.
7. The UVM closure run reports 100 transactions, 100 UART matches, 114/114 planned portable bins, and zero UVM errors.
8. The standalone Genus study reports 94.17% lower AES area and 96.10% lower AES total power than the baseline under the stated 55 nm flow.
9. The integrated Cyclone V implementation uses 13,257 ALMs and 11,154 registers and meets the 50 MHz constraint with positive setup and hold slack.
10. The complete-SoC HVT Genus run maps 50,968 cells, meets 50 MHz setup timing with +2.315 ns slack, and is promising but still pre-layout and vectorless.
11. The prototype provides confidentiality, but production deployment still requires authenticated encryption, nonce/replay management, secure key storage, a qualified network interface, and complete interrupt/safety handling.
