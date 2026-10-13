# Documentation map

[Project home](../README.md)

Read the chapters in order the first time. After that, use the references to jump directly to an interface or test.

| Page | Question it answers |
| --- | --- |
| [Start here](start-here.md) | What are RTL, a clock, a pipeline and an accelerator? |
| [1. AES core](01-aes-core.md) | How does one set of hardware perform all ten rounds? |
| [2. RISC-V integration](02-riscv-integration.md) | How does a 32-bit CPU talk to a 128-bit cipher? |
| [3. Interrupts and power](03-interrupts-and-power.md) | How are events recorded and activity controlled? |
| [4. Verification](04-verification.md) | What was checked, against which reference? |
| [5. Results](05-results.md) | Which numbers are directly supported by reports? |
| [Running the project](running.md) | Which command should I use? |
| [Register map](register-map.md) | Which address and bit do I need? |
| [Limitations](limitations.md) | What is still missing? |
| [Glossary](glossary.md) | What does an unfamiliar abbreviation mean? |

## Research and evidence

[GCON paper](papers/gcon-2026.md) · [ISAIA paper](papers/isaia-2026.md) · [Original logs and waveforms](../results/README.md) · [Thesis and slides](research/README.md)

## Following the source

Open [aes128_core.sv](../rtl/aes/aes128_core.sv) for the round controller, [mem_stage.sv](../rtl/cpu/mem_stage.sv) for the peripheral interconnect, and [riscv_aes_advancements.sv](../rtl/top/riscv_aes_advancements.sv) for the complete pipeline. The [source lists](../tb/filelists/) show what each simulation actually compiles.

[Maintenance notes](maintenance.md) record the cleanup and preserve a route back to the original files. Figure source files are in [figures/](figures/README.md).
