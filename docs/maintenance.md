# Reorganization notes

[Project home](../README.md) · [Documentation map](README.md) · [Validation](../results/validation.md)

This cleanup starts from commit `a49e2fe7633498c24877b54e644e6fab71608f81`. The public branch [archive/pre-reorganization-2026-10-13](https://github.com/Varadain/RISCV_lowPowerAES128/tree/archive/pre-reorganization-2026-10-13) preserves that complete snapshot. No history was force-rewritten.

## What changed

The root README is now an entry point rather than 510 viva questions. The older overlapping walkthroughs/defence script were removed from the active tree; the linked chapters cover the implementation with clearer boundaries. The thesis PDF and presentation were moved unchanged into `docs/research/`.

`rtl/rtl/cpu/` became `rtl/cpu/`. Numeric prefixes were removed from the AES source filenames. The historical module names and active RTL logic were retained. The compatibility wrapper's comment was updated for the new folder name.

Nine byte-identical screenshot copies were removed after hash comparisons. All unique screenshots remain, grouped by test, with descriptive short names. Original transcripts, synthesis reports and vendor notices were preserved.

Three unused definitions were removed: the duplicate `program_counter` module, the unused `riscv_pkg` typedef package and the unused standalone `sensor_mmio` alternative. The active top uses `pc_reg` and `sensor_spi_mmio`; the full regression validates the retained hierarchy.

## A missing source was restored

The GitHub snapshot referenced `data_mem.sv` but did not contain it. The RAM module was recovered from the author's original local project, not recreated from an imagined interface. Its original SHA-256 was `FE85A068DFE2D870C70134E9D177DD456EBE0CF763AA9079ECE3C589AB12AFB1` before newline normalization during the patch. It has the same source text and behaviour, and is now included in the SoC source list.

## Build and documentation maintenance

Use [scripts/run_simulation.ps1](../scripts/run_simulation.ps1) rather than the old machine-specific runners. Source manifests and Quartus/Genus paths now follow the repository layout. Fresh EDA output goes under ignored `build/` rather than overwriting evidence.

After changing filenames, update the source lists, QSF, chapter links and paper pages. Run:

```powershell
python scripts/check_repo.py
python -m unittest discover -s scripts/tests
python scripts/build_figures.py
```

Keep claims near their evidence. Add paper DOIs only after verifying the public record, and label a manuscript revision separately from later project measurements. If a paper-exact release is prepared later, record the source commit, tool versions, constraints and complete result set before assigning it that label.
