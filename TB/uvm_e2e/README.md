# UVM End-to-End AES-CTR UART Verification

This folder contains a separate UVM-style end-to-end verification environment.
It does not replace the existing directed `riscv_core_tb.sv` regression.

## Verification Goal

The UVM test randomizes complete sensor plaintext blocks, AES keys, nonces, and
counters. For each transaction:

1. A randomized 128-bit sensor plaintext is generated.
2. The C DPI reference model computes AES-CTR ciphertext and decrypted data.
3. The SystemVerilog RTL `aes_mmio.sv` + `aes128_lowpower.sv` encrypts the same plaintext.
4. RTL ciphertext is compared against the C reference ciphertext.
5. The decrypted C reference data is compared with the original plaintext.
6. The RTL `uart_mmio.sv` + `uart_tx.sv` transmits an ASCII line containing:
   - input plaintext
   - key
   - ciphertext
   - decrypted data
   - `MATCH=PASS`
7. The UART monitor decodes the serial `uart_tx` line.
8. The scoreboard compares the observed UART text against the expected text.

## Files

| File | Purpose |
| --- | --- |
| `aes_ctr_ref.c` | C AES-128 CTR reference model used through DPI-C |
| `uvm_e2e_if.sv` | Verification interface with AES/UART MMIO tasks |
| `uvm_e2e_pkg.sv` | UVM sequence, driver, monitor, scoreboard, and test |
| `uvm_e2e_tb_top.sv` | Testbench top instantiating AES and UART RTL blocks |
| `run_uvm_e2e_questa.ps1` | Questa compile/run script |

## Run

From this folder:

```powershell
.\run_uvm_e2e_questa.ps1
```

The script requires:

- Questa/ModelSim commands in PATH
- `gcc` in PATH to build the DPI-C reference DLL

You can change the number of randomized transactions by editing the script or
passing another `+NUM_TXNS=<N>` value to `vsim`.

## Why This Is End-To-End

This test checks more than the AES block alone. It verifies the flow:

```text
randomized sensor plaintext
    -> RTL AES-CTR encryption
    -> RTL UART transmission
    -> UART serial decode
    -> C reference decrypt comparison
    -> plaintext/decrypted match
```

The scoreboard confirms that the exact plaintext reported on UART matches the
decrypted data generated using the same key, nonce, and counter.
