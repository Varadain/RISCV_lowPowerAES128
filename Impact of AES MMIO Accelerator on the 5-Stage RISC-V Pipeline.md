# RISC-V Modules Affected When AES Is Active

| RISC-V Module | Affected by AES? | How It Is Affected | Impact Level |
|---|---|---|---|
| Instruction Fetch (IF) Stage | No | Continues fetching instructions normally while AES runs | None |
| IF/ID Pipeline Register | No | Pipeline flow unchanged | None |
| Instruction Decode (ID) Stage | No | Decodes normal `lw/sw/beq` instructions only | None |
| Register File | Slightly | Stores AES MMIO addresses/data values in registers | Low |
| Immediate Generator | Slightly | Generates MMIO addresses like `0x300`, `0x308` | Low |
| Control Unit | No major change | Still handles standard load/store instructions | Low |
| Hazard Unit | Slightly | Handles polling loop hazards (`lw` + `beq`) | Medium |
| Forwarding Unit | Slightly | May forward AES status/ciphertext load data | Medium |
| ID/EX Pipeline Register | No | Carries normal memory instructions | None |
| Execute (EX) Stage | Slightly | Computes AES MMIO addresses using ALU | Medium |
| ALU | Slightly | Calculates MMIO addresses (`AES_BASE + offset`) | Medium |
| Branch Logic | Slightly | Used in polling loops waiting for AES done | Medium |
| EX/MEM Pipeline Register | Yes | Carries AES MMIO address/data into MEM stage | Medium |
| MEM Stage | YES (Mainly Affected) | Detects AES MMIO addresses and routes accesses to `aes_mmio` | HIGH |
| Address Decoder | YES | Determines RAM vs AES peripheral access | HIGH |
| Data Memory | Slightly | Bypassed during AES MMIO access | Medium |
| MEM/WB Pipeline Register | Slightly | Stores ciphertext/status read data | Medium |
| Writeback (WB) Stage | Slightly | Writes AES status/ciphertext into CPU registers | Medium |
| Program Counter (PC) Logic | No | Pipeline control unchanged | None |
| Pipeline Flush Logic | No | AES independent of branch flushing | None |
| Stall Logic | No direct effect | AES does not stall CPU automatically | Low |
| AES MMIO Peripheral | YES | Main communication interface between CPU and AES | VERY HIGH |
| AES Control Registers | YES | Start/done/busy control handled here | VERY HIGH |
| AES Key Registers | YES | Store AES-128 encryption key | VERY HIGH |
| AES Plaintext Registers | YES | Store plaintext block | VERY HIGH |
| AES Ciphertext Registers | YES | Hold encryption result | VERY HIGH |
| AES Clock Enable Logic | YES | Activates AES only during encryption | VERY HIGH |
| AES Core (`aes128_lowpower`) | YES | Performs encryption rounds independently | VERY HIGH |
| SubBytes Module | YES | Executes AES byte substitution | HIGH |
| ShiftRows Module | YES | Performs AES row permutation | HIGH |
| MixColumns Module | YES | Performs AES column transformation | HIGH |
| Key Expansion Module | YES | Generates round keys | HIGH |
| AES S-Boxes | YES | Used during SubBytes + key expansion | HIGH |

---

# Most Important Architectural Insight

When AES is active:

```text
CPU pipeline CONTINUES RUNNING
```

The AES engine operates:

```text
IN PARALLEL
```

So the pipeline itself is **NOT blocked**.

Only the MEM stage becomes aware of AES because of MMIO address decoding.

---

# Practically Speaking

While AES encrypts:

| CPU Can Still Do | AES Does Simultaneously |
|---|---|
| Arithmetic | AES rounds |
| Branches | SubBytes |
| Loads/stores | ShiftRows |
| Loops | MixColumns |
| Polling | Key expansion |
| Other peripherals | Cipher generation |

---

# Most Affected RISC-V Module

The module most affected is:

```text
MEM STAGE
```

because it now handles:

```text
RAM + AES MMIO peripheral routing
```

Everything else mostly continues operating normally.
