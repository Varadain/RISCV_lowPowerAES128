# Start here

[Home](../README.md) · [Documentation map](README.md) · Next: [AES core](01-aes-core.md)

You do not need to know UVM or every RISC-V instruction to understand this project. Start with a clocked circuit that accepts one block, then add the processor interface.

## Four ideas to keep in mind

**RTL describes hardware.** A SystemVerilog module has ports, combinational logic and registers. Unlike a software function, several modules can work at the same time. An `always_comb` block describes a combinational calculation. An `always_ff` block describes storage updated on a clock edge.

**A clock edge changes stored state.** The right-hand sides of nonblocking assignments (`<=`) are evaluated using the values before that edge. The new values become visible after the edge. This is why the AES controller has separate START and WAIT states: raising a start register does not make another sequential module finish immediately.

**An accelerator is a separate worker.** The CPU sends it data and a start request. The AES block takes many cycles, then makes a result available. The CPU's 32-bit width does not force the AES algorithm to use 32-bit blocks; it just changes how data is transferred.

**A testbench is not firmware.** The supplied testbench can preload memories and drive interfaces directly. Those actions are useful for checking hardware, but should not be mistaken for a deployable application or a complete embedded software stack.

## The project in one example

Suppose a sensor produces a value. The CPU reads it, stores it in RAM, and can ask DMA to copy it. The CPU programs the AES registers and starts a CTR-mode operation. AES generates a keystream block; XOR with the sensor record produces ciphertext. UART sends a byte or a test transcript, depending on the test. The interrupt controller records completion events, and the activity block counts active and sleep cycles.

The [full-system scenario](../tb/scenarios/secure_health_monitoring_scenario_testcase.md) is a concrete simulated example. Its health-monitoring label is an application demonstration, not medical validation or real patient data.

## Your first source-code exercise

Open [aes128_core.sv](../rtl/aes/aes128_core.sv) and locate these names:

| Name | Meaning |
| --- | --- |
| `plaintext`, `key` | The 128-bit input block and key |
| `state_reg` | The intermediate cipher state |
| `round_key` | The key used for the current round |
| `round` | The current AES round, 1 through 10 |
| `busy` | The core is processing a block |
| `done` | The core has completed the block |

Do not read every S-box entry yet. Follow the `S_IDLE` branch and see where the inputs are first captured. Then find the condition that bypasses MixColumns in round 10.

Run the [small standalone test](../tb/directed/aes128_core_tb.sv), following [Running the project](running.md). It has only two known-answer vectors, so it is easier to follow than the integrated testbench. Correct ciphertext proves those checks passed; it does not prove every possible input or resistance to attacks.

## Suggested learning sessions

First session: read the AES chapter and run `AesCore`. Second session: read the integration chapter and run `AesKat` through MMIO. Third session: follow `FullSocScenario`, then compare its scope with UVM. Keep the [glossary](glossary.md) open when a term is unfamiliar.

When something fails, start from the last known-good boundary: cipher result, MMIO word order, processor store, or peripheral status. [Debugging notes](running.md#when-a-test-fails) give a practical sequence.
