# Low Power AES-128 (SystemVerilog)

SystemVerilog RTL implementation and verification of a **low-power AES-128 encryption core** with activity-aware clock gating.

---

## Overview

This design implements AES-128 encryption with a focus on reducing dynamic power using a clock enable (`clk_en`) mechanism.

Key features:
- 128-bit AES encryption
- Round-based architecture
- Clock gating using `clk_en` for activity-aware operation
- Modular design for integration into larger systems (e.g., RISC-V)

---

## Top Module

- `aes128_lowpower`

### Inputs
- `clk` – system clock  
- `reset` – asynchronous reset  
- `clk_en` – clock enable for low-power operation  
- `start` – start encryption  
- `plaintext[127:0]` – input data  
- `key[127:0]` – encryption key  

### Outputs
- `ciphertext[127:0]` – encrypted output  
- `done` – encryption complete  

---

## Architecture

The design follows standard AES-128 flow:

- AddRoundKey
- SubBytes (`sub_bytes`)
- ShiftRows (`shift_rows`)
- MixColumns (`mix_columns`)
- Key Expansion (`key_expand`)

Final round excludes MixColumns.

---

## Submodules

- `sub_bytes` – S-box substitution  
- `shift_rows` – row permutation  
- `mix_columns` – column mixing  
- `mix_col` – 32-bit column operation  
- `key_expand` – round key generation  
- `aes_sbox` – lookup table implementation  

---

## Low Power Features

- Clock gating using `clk_en`
- No unnecessary switching when disabled
- Reduced switching activity in registers and datapath

---

## Power Report

Instance: `/AES128_updated_new`  
Power Unit: W  

| Category   | Leakage       | Internal     | Switching    | Total        | %     |
|------------|---------------|--------------|--------------|--------------|-----  |
| Register   | 2.57e-07      | 5.74e-04     | 2.98e-05     | 6.04e-04     | 70.86 |
| Logic      | 1.94e-07      | 1.22e-04     | 6.95e-05     | 1.91e-04     | 22.50 |
| Clock      | 0             | 0            | 5.66e-05     | 5.66e-05     | 6.63  |
| **Total**  | 4.51e-07      | 6.96e-04     | 1.55e-04     | **8.53e-04** | 100   |

Breakdown:
- Internal power dominates (~81.66%)
- Switching power reduced via clock gating
- Minimal leakage contribution

---

## Area Report

Tool: Genus Synthesis Solution  
Technology: 1.0V, 25°C  

| Module                  | Cell Count | Area     |
|-------------------------|------------|----------|
| AES128_updated_new      | 2694       | 11841.48 |
| AES_SBOX_SEQ            | 331        | 1698.12  |
| AES_MIXCOL_SEQ          | 297        | 1859.04  |
| AES_KEYEXP_SEQ          | 444        | 2049.84  |

Total Area:
```
11841.48
```

---

## Timing Report

- Setup Slack: `6806 ps`
- Path: `state_reg → round_key_reg`
- Timing Status: MET

Key observations:
- No timing violations
- Balanced datapath
- Stable performance under nominal conditions

---

## Verification

- Directed testbench with multiple test vectors
- Functional validation using known AES inputs
- Output comparison with expected ciphertext
- PASS/FAIL reporting per test

---

## Design Goals

- Maintain functional correctness of AES-128
- Reduce switching activity for low power
- Preserve synthesis results (power and area stability)
- Enable integration into processor-based systems

---

## Future Work

- Integration with RISC-V core
- Memory-mapped AES accelerator
- UVM-based verification environment
- Power-aware simulation and toggle analysis

---
