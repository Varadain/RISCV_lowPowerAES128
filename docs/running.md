# Running the project

[Home](../README.md) · [Documentation map](README.md) · [Verification scope](04-verification.md)

## Before running

Clone the `final` branch, open a terminal at its root, and check the source lists:

```powershell
git clone --branch final https://github.com/Varadain/RISCV_lowPowerAES128.git
cd RISCV_lowPowerAES128
python scripts/check_repo.py
```

The provided runner targets Windows Questa, with `vlib`, `vlog` and `vsim` on PATH. A working simulator licence is required. UVM also needs a C compiler for the DPI reference DLL; the runner looks for `gcc` or Questa's bundled GCC. Intel/Altera-generated SPI code remains subject to its vendor terms. See [NOTICE](../NOTICE.md).

No RISC-V cross-compiler, board or licensed ASIC library is needed for the supplied simulations. The main directed testbench encodes instructions and preloads its simulated ROM directly.

## A small test, then a larger one

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/run_simulation.ps1 -Mode AesCore
powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/run_simulation.ps1 -Mode AesKat
powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/run_simulation.ps1 -Mode All
```

`RemoteSigned` is process-scoped here. If your organisation enforces a signed-script policy, follow that policy instead of changing machine settings. Alternatively inspect the [source lists](../tb/filelists/) and use the [Questa GUI compile script](../tb/scripts/questa/compile_rtl.do).

Pass `-QuestaBin "C:/path/to/questa/win64"` if the tools are not on PATH. Use `-DryRun` with any mode to print/check its source list without invoking the tools.

## Select the boundary you want to check

| Mode | Typical use |
| --- | --- |
| `AesCore` | First cipher-core exercise, no processor |
| `AesKat` | NIST-vector check through AES MMIO |
| `DirectedCpu` | Pipeline instruction examples |
| `DirectedPeripheral` | Peripheral and custom-command checks |
| `RandomSmoke` | Small deterministic random smoke test |
| `FullSocScenario` | The CPU-driven application alone |
| `All` | Complete directed regression |
| `UvmE2e` | Randomized AES/UART subsystem with C-DPI reference |
| `Coverage` | Default 100 transactions, seed 611, checks 114-bin closure |

```powershell
powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/run_simulation.ps1 -Mode FullSocScenario
powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/run_simulation.ps1 -Mode UvmE2e -NumTxns 25 -Seed 101
powershell -NoProfile -ExecutionPolicy RemoteSigned -File scripts/run_simulation.ps1 -Mode Coverage
```

You can override the transaction count/seed in `Coverage`, but an alternative run might not close every bin; the mode will report that as a failure. This is intentional. `-NativeCovergroups` is optional and needs simulator support. The default portable coverage counters do not depend on native covergroup support.

## Where outputs go

Each mode has its own ignored folder under `build/`: `compile.log`, `simulation.log`, `simulation.wlf` and, for UVM, a DPI DLL. The directed testbench also produces a VCD. The runner does not delete the original `results/` evidence or an existing work library; it recompiles the selected source list.

The process exit code and transcript are checked. A timeout without a completed passing summary, RTL fatal/error, directed failure or UVM mismatch raises a failure rather than being labelled successful.

## View waveforms

From the repository root, open a fresh recording with Questa:

```powershell
vsim -view build/All/simulation.wlf
```

In its Transcript window:

```tcl
do tb/scripts/questa/waveform_capture/01_aes_known_answer_view.do
```

The view scripts use dataset `sim`, Questa's default name for the opened recording. If you renamed the dataset, adjust `DS` in the view script. Choose the [corresponding view](../tb/scripts/questa/waveform_capture/) and mode for CPU, peripheral, UVM or scenario signals. A UVM view needs a UVM recording, not a CPU recording. Original screenshots are in the [gallery](../results/README.md).

## FPGA and ASIC flows

Open [riscv_aes_advancements.qpf](../fpga/quartus/riscv_aes_advancements.qpf) in a compatible Quartus installation. The QSF now references the reorganized sources relative to its own folder. The target is Cyclone V `5CGXFC7C7F23C8`, and the main SDC creates a 50 MHz clock. The expanded SDC is an additional constraint example, not the active SDC in this project.

The project has no complete board-specific pin/I/O constraint set. The synthesis ROM also contains only a small example program, unlike the testbench-preloaded application. Do not treat the archived fitted reports as a ready-to-program board demonstration. A new fit was not performed during this cleanup.

For standalone AES ASIC synthesis, set `AES_LIBERTY` to a licensed Liberty file, then run [genus_script.tcl](../asic/cadence_genus/scripts/genus_script.tcl) inside Genus. It uses the retained monolithic AES source, a 10 ns clock constraint and ignored `build/genus_aes/` outputs. Genus and the original technology library are not bundled; this flow was not re-synthesized during the reorganization.

## When a test fails

First check `compile.log`: missing sources are a path problem; unresolved modules are an incomplete source list. Licence errors must be resolved in your simulator installation.

If compilation succeeds, find the **first** failure in `simulation.log`. For AES mismatches, compare KEY0..KEY3 and PT0..PT3 packing, then mode/nonce/counter, then the standalone cipher result. For UART, check enable, divisor and busy/done. For interrupts, distinguish the peripheral's level flag from the sticky INTC bit. For UVM, check the DPI library and reference/RTL/UART match messages separately.

A single passing seed is not broad verification. Keep the input seed and transcript when reporting a failure.
