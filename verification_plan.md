# Verification Plan

## Regression Goals

The original RV32I/AES checks must continue passing:

- R-type ALU operations.
- I-type immediate operations.
- Loads and stores.
- Branches and jumps.
- LUI/AUIPC.
- Basic pseudo/system/fence behavior.
- AES-128 ECB NIST known-answer vector.
- Pipeline stall/flush signal activity.

## New IoT Security SoC Checks

The extended `riscv_core_tb.sv` adds directed checks for:

- AES-CTR mode using a known counter block.
- CTR counter auto-increment.
- Sensor MMIO data/status reads.
- Intel Avalon SPI IP access through the sensor MMIO window and observable SPI clock/slave-select activity.
- UART MMIO transmit start, busy, and done behavior.
- Interrupt pending and combined IRQ output.
- DMA-lite memory copy completion.
- Sleep-control bit behavior.
- Activity counter increment and debug visibility.
- Custom security ISA instructions:
  - `CSEC_XOR`
  - `CSEC_AES_STATUS`
  - `CSEC_AES_START`
  - `CSEC_AES_CT0`
  - `CSEC_AES_CLEAR`

## Current Simulation Result

The original IoT-security baseline passed before adding the custom ISA:

```text
PASS=77 FAIL=0
ALL TESTS PASSED
```

The custom-ISA project extends that regression with six additional directed
checks. Current Questa command-line result:

```text
PASS=83 FAIL=0
ALL TESTS PASSED
```

Quartus Analysis & Synthesis also completed with `0 errors, 0 warnings`.

The only simulator warning is the normal `+acc` optimization warning used for waveform/debug visibility.

## Future Verification Extensions

- Add constrained-random instruction streams.
- Add multi-block AES-CTR messages.
- Add UART byte-order tests for complete 128-bit ciphertext transfer.
- Add external SPI sensor loopback/peripheral models beyond the current pin-activity check.
- Add interrupt-driven firmware once CSR/trap support is implemented.
- Add post-synthesis simulation after final FPGA pin/debug output selection.
