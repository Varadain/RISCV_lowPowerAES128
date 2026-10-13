# Post-cleanup validation - 13 October 2026

[Project home](../README.md) · [Original evidence](README.md) · [Run it yourself](../docs/running.md)

The reorganized source lists were compiled and simulated with Questa Intel Starter FPGA Edition 2023.3 on Windows. UVM used the simulator's built-in UVM-1.1d and its bundled GCC for the independent C-DPI model.

| Run | Observed result |
| --- | --- |
| `AesCore` | Both known-answer ciphertexts match; busy-start, done-clear and retained-result checks pass |
| `All` | 107 pass, 0 fail |
| `Coverage` | Seed 611, 100 transactions, 100 UART matches, 0 mismatches, 114/114 portable bins, 0 UVM errors/fatals |

Compilation reported zero errors. Simulation reported zero errors and the normal visibility/optimization warning associated with `+acc`. Raw fresh outputs remain in ignored `build/AesCore`, `build/All` and `build/Coverage` on the validating machine. The checked-in [summary excerpt](validation/2026-10-13-summary.txt) preserves the completion messages; it is an excerpt, not a replacement for a full transcript.

No new Quartus fit or Genus synthesis was performed. Their retained reports are historical evidence. The new FPGA/ASIC source paths have been checked for existence, but a path check is not a synthesis result.
