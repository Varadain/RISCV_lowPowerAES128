# AES-128 Mathematical Foundation and Algorithm Explanation

This document provides the complete mathematical background required to understand the AES-128 encryption algorithm implemented in this repository.

It covers:
- Finite field arithmetic (GF(2^8))
- AES transformations (SubBytes, ShiftRows, MixColumns)
- Key expansion mathematics
- Step-by-step encryption flow
- NIST test vector validation mapped to RTL behavior

---

# 1. AES Overview

AES (Advanced Encryption Standard) is a **block cipher** with:

- Block size: 128 bits
- Key size: 128 bits (AES-128)
- Number of rounds: 10

The data is represented as a **4 × 4 byte matrix**:

```
State Matrix:

| s0  s4  s8  s12 |
| s1  s5  s9  s13 |
| s2  s6  s10 s14 |
| s3  s7  s11 s15 |
```

---

# 2. Finite Field Arithmetic (GF(2^8))

AES operates in the finite field:

```
GF(2^8) with irreducible polynomial:
m(x) = x^8 + x^4 + x^3 + x + 1
```

This corresponds to hexadecimal:
```
0x11B
```

---

## 2.1 Addition

Addition in GF(2^8) is simply:

```
a ⊕ b (bitwise XOR)
```

Example:
```
0x57 ⊕ 0x83 = 0xD4
```

---

## 2.2 Multiplication (xtime)

Multiplication by 2:

```
xtime(b) = (b << 1) XOR 0x1B (if MSB = 1)
```

RTL equivalent:
```verilog
xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
```

---

# 3. AES Transformations

---

## 3.1 SubBytes

Each byte is replaced using the AES S-box:

```
S(x) = AffineTransform(Inverse(x in GF(2^8)))
```

This introduces **non-linearity**.

In RTL:
- Implemented via `aes_sbox`
- 16 parallel lookups

---

## 3.2 ShiftRows

Rows are cyclically shifted:

| Row | Shift |
|-----|------|
| 0   | 0    |
| 1   | 1    |
| 2   | 2    |
| 3   | 3    |

Example:

```
Before:
| a b c d |
| e f g h |
| i j k l |
| m n o p |

After:
| a b c d |
| f g h e |
| k l i j |
| p m n o |
```

---

## 3.3 MixColumns

Each column is multiplied by a matrix:

```
|02 03 01 01|
|01 02 03 01|
|01 01 02 03|
|03 01 01 02|
```

For a column:

```
|y0|   |02 03 01 01| |s0|
|y1| = |01 02 03 01| |s1|
|y2|   |01 01 02 03| |s2|
|y3|   |03 01 01 02| |s3|
```

Example equation:

```
y0 = (2*s0) ⊕ (3*s1) ⊕ s2 ⊕ s3
```

Where:
```
3*x = xtime(x) ⊕ x
```

---

## 3.4 AddRoundKey

Simple XOR with round key:

```
State = State ⊕ RoundKey
```

---

# 4. Key Expansion (AES-128)

Initial key split:

```
K = [w0, w1, w2, w3]
```

Each round generates:

```
w0' = w0 ⊕ SubWord(RotWord(w3)) ⊕ Rcon
w1' = w1 ⊕ w0'
w2' = w2 ⊕ w1'
w3' = w3 ⊕ w2'
```

---

## 4.1 RotWord

Rotate left by 1 byte:

```
[a b c d] → [b c d a]
```

---

## 4.2 SubWord

Apply S-box to each byte.

---

## 4.3 Rcon

Round constants:

```
Rcon[1] = 0x01
Rcon[2] = 0x02
Rcon[3] = 0x04
...
```

---

# 5. AES Encryption Flow

---

## Step 0: Initial Round

```
State = Plaintext ⊕ Key
```

---

## Steps 1–9: Main Rounds

Each round:

1. SubBytes
2. ShiftRows
3. MixColumns
4. AddRoundKey

---

## Step 10: Final Round

```
No MixColumns
```

Steps:

1. SubBytes
2. ShiftRows
3. AddRoundKey

---

# 6. NIST Test Vector Validation

Standard test vector:

```
Plaintext:
00112233445566778899aabbccddeeff

Key:
000102030405060708090a0b0c0d0e0f

Expected Ciphertext:
69c4e0d86a7b0430d8cdb78070b4c55a
```

---

## Step 1: Initial AddRoundKey

```
State = Plaintext ⊕ Key
```

Result:
```
00102030405060708090a0b0c0d0e0f0
```

---

## Step 2: Round Transformations

Each round applies:

```
SubBytes → ShiftRows → MixColumns → AddRoundKey
```

Example (conceptual):

```
After SubBytes:
63cab7040953d051cd60e0e7ba70e18c

After ShiftRows:
6353e08c0960e104cd70b751bacad0e7

After MixColumns:
5f72641557f5bc92f7be3b291db9f91a
```

---

## Final Round Output

After round 10:

```
Ciphertext:
69c4e0d86a7b0430d8cdb78070b4c55a
```

---

# 7. Mapping to RTL Implementation

---

## RTL vs AES Step

| AES Step        | RTL Module          |
|----------------|--------------------|
| SubBytes       | `sub_bytes.sv`     |
| ShiftRows      | `shift_rows.sv`    |
| MixColumns     | `mix_columns.sv`   |
| Key Expansion  | `key_expand.sv`    |
| AddRoundKey    | XOR logic in top   |

---

## Low Power Feature

```
if (clk_en)
```

Ensures:
- No switching when idle
- Reduced dynamic power

---

# 8. Key Observations

- AES is based on linear algebra + finite field math
- Security comes from:
  - Non-linearity (S-box)
  - Diffusion (MixColumns)
  - Confusion (ShiftRows + SubBytes)
- RTL maps directly to mathematical operations

---

# 9. Conclusion

This implementation:
- Correctly follows AES mathematical model
- Matches NIST test vectors
- Uses hardware-efficient structures
- Optimized for low power using clock gating

---
# 10. Complete NIST AES-128 Execution (Step-by-Step Explanation)

This section explains how AES-128 encryption is performed using a standard NIST test vector.  
Each transformation is explained clearly and mapped to hardware (RTL) behavior.

---

## 10.1 Test Vector (NIST Standard)

Plaintext:
`00112233445566778899aabbccddeeff`

Key:
`000102030405060708090a0b0c0d0e0f`

Expected Ciphertext:
`69c4e0d86a7b0430d8cdb78070b4c55a`

AES operates on a 128-bit block arranged as a 4 × 4 byte matrix called the **state**.

---

## 10.2 Step 0: Initial AddRoundKey

Operation:
`State = Plaintext XOR Key`

Byte-wise result:

| Plaintext | Key | Output |
|----------|-----|--------|
| 00       | 00  | 00     |
| 11       | 01  | 10     |
| 22       | 02  | 20     |
| 33       | 03  | 30     |
| ...      | ... | ...    |

Final state:
`00102030405060708090a0b0c0d0e0f0`

This becomes input to Round 1.

RTL mapping:
- Implemented using XOR logic in the top module

---

## 10.3 Round 1 Execution

Each round performs:

SubBytes → ShiftRows → MixColumns → AddRoundKey

---

### 10.3.1 SubBytes

Each byte is replaced using the AES S-box.

Result:
63 ca b7 04
09 53 d0 51
cd 60 e0 e7
ba 70 e1 8c

Explanation:
- Introduces non-linearity
- Prevents predictable patterns

RTL mapping:
- Implemented using parallel S-box modules

---

### 10.3.2 ShiftRows

Rows are shifted left:

| Row | Shift |
|-----|------|
| 0   | 0    |
| 1   | 1    |
| 2   | 2    |
| 3   | 3    |

Result:
63 53 e0 8c
09 60 e1 04
cd 70 b7 51
ba ca d0 e7

Explanation:
- Spreads data across columns

RTL mapping:
- Implemented using fixed wiring

---

### 10.3.3 MixColumns

Each column is transformed using matrix multiplication in GF(2^8).

Equation:
`y0 = (2*s0) XOR (3*s1) XOR s2 XOR s3`

Result:
5f 72 64 15
57 f5 bc 92
f7 be 3b 29
1d b9 f9 1a

Explanation:
- Provides diffusion across all bytes

RTL mapping:
- Implemented using combinational logic and xtime

---

### 10.3.4 AddRoundKey

State is XORed with round key.

Result after Round 1:

89 d8 10 e8
85 5a ce 68
2d 18 43 d8
cb 12 8f e4

---

## 10.4 Rounds 2 to 9

Each round repeats:

SubBytes → ShiftRows → MixColumns → AddRoundKey

During these rounds:
- Data becomes highly mixed
- Each output depends on all input bits

---

## 10.5 Final Round (Round 10)

Operations:

SubBytes → ShiftRows → AddRoundKey

Note:
- MixColumns is NOT used in final round

Final state:
69 c4 e0 d8
6a 7b 04 30
d8 cd b7 80
70 b4 c5 5a


---

## 10.6 Final Ciphertext

Flattened output:

`69c4e0d86a7b0430d8cdb78070b4c55a`

This matches the NIST reference output.

---

## 10.7 RTL Execution Flow

Cycle-wise execution:

| Cycle | Operation |
|------|----------|
| 0    | Initial AddRoundKey |
| 1–9  | Main rounds |
| 10   | Final round |

---

## 10.8 Key Observations

- SubBytes provides non-linearity
- ShiftRows provides permutation
- MixColumns provides diffusion
- AddRoundKey integrates key material
- Each round increases security strength

---

## 10.9 Conclusion

This example verifies that:

- AES transformations are correctly implemented
- Finite field arithmetic is accurate
- Key expansion works correctly
- RTL matches mathematical model
- Output matches NIST standard
