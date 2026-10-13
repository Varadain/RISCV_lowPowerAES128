# Diagram sources

[Project home](../../README.md) · [Documentation map](../README.md)

New diagrams use background `#F5EFE1`, dark readable text and restrained teal/ochre accents. They are SVGs so labels stay sharp when enlarged. Each has an accessible title and description.

| Diagram | Where it helps |
| --- | --- |
| [Project roadmap](project-roadmap.svg) | Three development/learning stages |
| [AES rounds](aes-rounds.svg) | Reused transformation hardware |
| [AES handshake](aes-handshake.svg) | Request, busy and completion timing |
| [System architecture](system-architecture.svg) | Pipeline and MEM-stage integration |
| [MMIO word order](mmio-word-order.svg) | Four 32-bit words form a 128-bit value |
| [Interrupt sequence](interrupt-sequence.svg) | Source status versus controller pending |
| [Verification flow](verification-flow.svg) | Independent reference and monitor paths |
| [Measurement scope](measurement-scope.svg) | ASIC, FPGA and functional evidence |

The diagrams are explanatory, not captured waveforms or measured power charts. Original simulator screenshots retain their original colours in the [evidence gallery](../../results/README.md).

Rebuild the diagrams from the repository root:

```powershell
python scripts/build_figures.py
```

The [generator](../../scripts/build_figures.py) uses only the Python standard library. No font download, image-generation service or plotting package is required.
