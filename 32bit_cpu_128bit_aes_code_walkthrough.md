# How the 32-Bit RISC-V Processor Handles 128-Bit AES Data

## Purpose

This document explains, using the actual SystemVerilog code, how the 32-bit RISC-V processor in this project controls a 128-bit AES-128 accelerator.

The central idea is:

```text
The CPU does not perform a 128-bit AES round using its 32-bit ALU.

The CPU transfers the key, plaintext and ciphertext as four 32-bit words.
The AES MMIO wrapper joins those words into 128-bit registers.
The dedicated AES hardware performs the 128-bit encryption internally.
```

The normal full-width path is:

```text
32-bit CPU register
        |
        | four SW instructions
        v
Four 32-bit AES MMIO registers
        |
        | joined inside aes_mmio
        v
One 128-bit key/plaintext register
        |
        v
128-bit iterative AES accelerator
        |
        v
One 128-bit ciphertext register
        |
        | four LW instructions
        v
32-bit CPU register
```

> Line numbers in this document refer to the current project revision. If RTL is added or removed above these blocks, the line numbers may move.

---

## 1. The Processor Register File Is 32 Bits Wide

The CPU contains 32 general-purpose registers. Each register stores one 32-bit value.

Source: [`reg_file.sv`, lines 63-82](reg_file.sv#L63-L82)

```systemverilog
module reg_file (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [4:0]  rs1_i,
    input  logic [4:0]  rs2_i,
    input  logic [4:0]  rd_i,
    input  logic [31:0] rd_data_i,
    input  logic        rd_we_i,
    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o
);

logic [31:0] regs [0:31];
```

### Line-by-line meaning

| Code | Meaning |
|---|---|
| `logic [31:0] rd_data_i` | Writeback can place only 32 bits into one CPU register. |
| `logic [31:0] rs1_data_o` | Source register 1 provides 32 bits. |
| `logic [31:0] rs2_data_o` | Source register 2 provides 32 bits. |
| `logic [31:0] regs [0:31]` | There are 32 registers, and every register is 32 bits wide. |

Therefore, one CPU register cannot contain the complete 128-bit AES block.

The 128-bit value must be divided into four words:

```text
128 bits = 32 bits + 32 bits + 32 bits + 32 bits
```

---

## 2. Load and Store Instructions Move One 32-Bit Word

The CPU uses ordinary RISC-V `SW` instructions to write AES registers and `LW` instructions to read them.

### Store decoding

Source: [`control_unit.sv`, lines 170-182](control_unit.sv#L170-L182)

```systemverilog
7'b0100011: begin
    mem_write_o = 1'b1;
    alu_src_o   = 1'b1;

    case (funct3_o)
        3'b000: alu_ctrl_o = ALU_BNE; // SB
        3'b001: alu_ctrl_o = ALU_BLT; // SH
        3'b010: alu_ctrl_o = ALU_ADD; // SW
        default: alu_ctrl_o = ALU_ADD;
    endcase
end
```

For an `SW` instruction:

1. Opcode `0100011` identifies a store.
2. `mem_write_o` becomes one.
3. `alu_src_o` selects the immediate address offset.
4. `funct3 = 010` identifies a 32-bit word store.

### Load decoding

Source: [`control_unit.sv`, lines 149-168](control_unit.sv#L149-L168)

```systemverilog
7'b0000011: begin
    reg_write_o  = 1'b1;
    mem_read_o   = 1'b1;
    mem_to_reg_o = 1'b1;
    alu_src_o    = 1'b1;

    case (funct3_o)
        3'b010: alu_ctrl_o = ALU_ADD; // LW
        default: alu_ctrl_o = ALU_ADD;
    endcase
end
```

For an `LW` instruction:

1. Opcode `0000011` identifies a load.
2. `mem_read_o` requests a read.
3. `reg_write_o` allows the returned 32-bit word to enter `rd`.
4. `mem_to_reg_o` selects memory or peripheral read data for writeback.

---

## 3. The EX Stage Calculates the MMIO Address

For load and store instructions, the execute stage calculates:

```text
effective address = base register + immediate offset
```

Source: [`ex_stage.sv`, lines 105-177](ex_stage.sv#L105-L177)

```systemverilog
always_comb begin
    case (forward_a_i)
        2'b10: op_a_raw = mem_alu_result_i;
        2'b01: op_a_raw = wb_data_i;
        default: op_a_raw = rs1_data_i;
    endcase

    case (forward_b_i)
        2'b10: op_b_raw = mem_alu_result_i;
        2'b01: op_b_raw = wb_data_i;
        default: op_b_raw = rs2_data_i;
    endcase
end

always_comb begin
    op_a = op_a_raw;
    op_b = alu_src_i ? imm_i : op_b_raw;
end

assign rs2_forwarded_o = op_b_raw;
```

### Meaning

| Signal | Purpose during `SW` |
|---|---|
| `op_a_raw` | Contains the base address from `rs1`, or a forwarded value. |
| `imm_i` | Contains the store-address offset. |
| `op_b` | Selects the immediate because `alu_src_i = 1`. |
| ALU result | Produces `base + offset`, which becomes the MMIO address. |
| `rs2_forwarded_o` | Carries the 32-bit word that must be stored. |

The address and store data remain 32 bits wide. A single instruction writes one AES word.

---

## 4. The MEM Stage Recognizes the AES Address Range

The AES peripheral owns the page beginning at `0x0000_0300`.

Source: [`mem_stage.sv`, lines 103-128](mem_stage.sv#L103-L128)

```systemverilog
assign eff_addr = {3'b000, addr_i[28:0]};

assign aes_sel    = (eff_addr[31:8] == 24'h000003);
assign sensor_sel = (eff_addr[31:8] == 24'h000004);
assign uart_sel   = (eff_addr[31:8] == 24'h000005);
assign intc_sel   = (eff_addr[31:8] == 24'h000006);
assign dma_sel    = (eff_addr[31:8] == 24'h000007);
assign power_sel  = (eff_addr[31:8] == 24'h000008);

assign aes_write_en = mem_write_i & aes_sel;
assign aes_read_en  = mem_read_i  & aes_sel;
```

If the address is between `0x0000_0300` and `0x0000_03FF`, `aes_sel` becomes one.

An AES store requires both conditions:

```text
mem_write_i = 1
aes_sel     = 1
```

An AES load requires:

```text
mem_read_i = 1
aes_sel    = 1
```

The MEM stage connects its 32-bit address and data buses to the AES wrapper.

Source: [`mem_stage.sv`, lines 166-184](mem_stage.sv#L166-L184)

```systemverilog
aes_mmio u_aes_mmio (
    .clk           (clk),
    .rst_n         (rst_n),
    .clk_en_i      (!sleep_o),
    .addr_i        (eff_addr),
    .write_data_i  (write_data_i),
    .write_en_i    (aes_write_en),
    .read_en_i     (aes_read_en),
    .custom_valid_i(custom_valid_i && (custom_cmd_i != 3'b000)),
    .custom_cmd_i  (custom_cmd_i),
    .custom_rs1_i  (addr_i),
    .custom_rs2_i  (write_data_i),
    .custom_result_o(aes_custom_result),
    .read_data_o   (aes_read_data)
);
```

`write_data_i` and `aes_read_data` are both 32-bit values. The width conversion occurs inside `aes_mmio`.

---

## 5. The AES MMIO Interface Is 32 Bits Wide

Source: [`aes_mmio.sv`, lines 27-43](aes_mmio.sv#L27-L43)

```systemverilog
module aes_mmio (
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        write_en_i,
    input  logic        read_en_i,
    input  logic [31:0] custom_rs1_i,
    input  logic [31:0] custom_rs2_i,
    output logic [31:0] custom_result_o,
    output logic [31:0] read_data_o
);
```

The wrapper accepts one 32-bit word for every CPU store and returns one 32-bit word for every CPU load.

---

## 6. Four MMIO Locations Represent One 128-Bit Value

The wrapper provides four key registers, four plaintext registers and four ciphertext registers.

Source: [`aes_mmio.sv`, lines 46-65](aes_mmio.sv#L46-L65)

```systemverilog
localparam logic [7:0] OFF_CTRL   = 8'h00;
localparam logic [7:0] OFF_STATUS = 8'h04;
localparam logic [7:0] OFF_KEY0   = 8'h08;
localparam logic [7:0] OFF_KEY1   = 8'h0C;
localparam logic [7:0] OFF_KEY2   = 8'h10;
localparam logic [7:0] OFF_KEY3   = 8'h14;
localparam logic [7:0] OFF_PT0    = 8'h18;
localparam logic [7:0] OFF_PT1    = 8'h1C;
localparam logic [7:0] OFF_PT2    = 8'h20;
localparam logic [7:0] OFF_PT3    = 8'h24;
localparam logic [7:0] OFF_CT0    = 8'h28;
localparam logic [7:0] OFF_CT1    = 8'h2C;
localparam logic [7:0] OFF_CT2    = 8'h30;
localparam logic [7:0] OFF_CT3    = 8'h34;
localparam logic [7:0] OFF_NONCE0 = 8'h38;
localparam logic [7:0] OFF_NONCE1 = 8'h3C;
localparam logic [7:0] OFF_COUNT0 = 8'h40;
localparam logic [7:0] OFF_COUNT1 = 8'h44;
```

Adding these offsets to the AES base address gives:

| Register | Address | Width | AES bits |
|---|---:|---:|---:|
| `KEY0` | `0x0000_0308` | 32 | Key `[31:0]` |
| `KEY1` | `0x0000_030C` | 32 | Key `[63:32]` |
| `KEY2` | `0x0000_0310` | 32 | Key `[95:64]` |
| `KEY3` | `0x0000_0314` | 32 | Key `[127:96]` |
| `PT0` | `0x0000_0318` | 32 | Plaintext `[31:0]` |
| `PT1` | `0x0000_031C` | 32 | Plaintext `[63:32]` |
| `PT2` | `0x0000_0320` | 32 | Plaintext `[95:64]` |
| `PT3` | `0x0000_0324` | 32 | Plaintext `[127:96]` |
| `CT0` | `0x0000_0328` | 32 | Ciphertext `[31:0]` |
| `CT1` | `0x0000_032C` | 32 | Ciphertext `[63:32]` |
| `CT2` | `0x0000_0330` | 32 | Ciphertext `[95:64]` |
| `CT3` | `0x0000_0334` | 32 | Ciphertext `[127:96]` |

---

## 7. The Wrapper Contains 128-Bit Storage

Source: [`aes_mmio.sv`, lines 74-93](aes_mmio.sv#L74-L93)

```systemverilog
logic [127:0] key_reg;
logic [127:0] pt_reg;
logic [127:0] ct_reg;
logic [63:0]  nonce_reg;
logic [63:0]  counter_reg;

logic [127:0] aes_input_block;
logic [127:0] aes_ciphertext;
```

These registers create the boundary between the 32-bit CPU and the 128-bit accelerator.

| Register | Function |
|---|---|
| `key_reg` | Holds the complete 128-bit AES key. |
| `pt_reg` | Holds the complete 128-bit plaintext. |
| `ct_reg` | Holds the complete 128-bit final ciphertext. |
| `nonce_reg` | Holds the 64-bit CTR nonce. |
| `counter_reg` | Holds the 64-bit CTR counter. |
| `aes_input_block` | Carries one 128-bit block into the AES primitive. |
| `aes_ciphertext` | Carries the primitive's 128-bit output. |

---

## 8. Four 32-Bit Stores Assemble the 128-Bit Key and Plaintext

Source: [`aes_mmio.sv`, lines 128-163](aes_mmio.sv#L128-L163)

```systemverilog
if (clk_en_i && write_en_i) begin
    case (reg_offset)
        OFF_KEY0: key_reg[31:0]    <= write_data_i;
        OFF_KEY1: key_reg[63:32]   <= write_data_i;
        OFF_KEY2: key_reg[95:64]   <= write_data_i;
        OFF_KEY3: key_reg[127:96]  <= write_data_i;

        OFF_PT0:  pt_reg[31:0]     <= write_data_i;
        OFF_PT1:  pt_reg[63:32]    <= write_data_i;
        OFF_PT2:  pt_reg[95:64]    <= write_data_i;
        OFF_PT3:  pt_reg[127:96]   <= write_data_i;

        OFF_NONCE0: nonce_reg[31:0]   <= write_data_i;
        OFF_NONCE1: nonce_reg[63:32]  <= write_data_i;
        OFF_COUNT0: counter_reg[31:0] <= write_data_i;
        OFF_COUNT1: counter_reg[63:32] <= write_data_i;
        default: ;
    endcase
end
```

Each `SW` reaches one case item. That case item updates one 32-bit slice on the next active clock edge.

After all four stores:

```text
key_reg = {KEY3, KEY2, KEY1, KEY0}
pt_reg  = {PT3,  PT2,  PT1,  PT0 }
```

The CPU never needs a 128-bit general-purpose register.

---

## 9. Worked NIST Example

Consider the standard AES-128 values:

```text
Key       = 000102030405060708090A0B0C0D0E0F
Plaintext = 00112233445566778899AABBCCDDEEFF
```

### Key stores

| CPU operation | MMIO address | `write_data_i` | Destination slice |
|---|---:|---:|---:|
| Store key word 0 | `0x0308` | `0x0C0D0E0F` | `key_reg[31:0]` |
| Store key word 1 | `0x030C` | `0x08090A0B` | `key_reg[63:32]` |
| Store key word 2 | `0x0310` | `0x04050607` | `key_reg[95:64]` |
| Store key word 3 | `0x0314` | `0x00010203` | `key_reg[127:96]` |

The result is:

```text
key_reg = {00010203, 04050607, 08090A0B, 0C0D0E0F}
        = 000102030405060708090A0B0C0D0E0F
```

### Plaintext stores

| CPU operation | MMIO address | `write_data_i` | Destination slice |
|---|---:|---:|---:|
| Store plaintext word 0 | `0x0318` | `0xCCDDEEFF` | `pt_reg[31:0]` |
| Store plaintext word 1 | `0x031C` | `0x8899AABB` | `pt_reg[63:32]` |
| Store plaintext word 2 | `0x0320` | `0x44556677` | `pt_reg[95:64]` |
| Store plaintext word 3 | `0x0324` | `0x00112233` | `pt_reg[127:96]` |

The result is:

```text
pt_reg = {00112233, 44556677, 8899AABB, CCDDEEFF}
       = 00112233445566778899AABBCCDDEEFF
```

The word order is important. `KEY0`, `PT0` and `CT0` always represent the least-significant 32 bits.

---

## 10. A Control-Register Store Starts Encryption

The AES control register is located at offset `0x00`, which is absolute address `0x0000_0300`.

The relevant bits are:

| Bit | Meaning |
|---:|---|
| `CTRL[0]` | Start encryption. |
| `CTRL[1]` | Clear the sticky done flag. |
| `CTRL[2]` | Select ECB when zero or CTR when one. |

Source: [`aes_mmio.sv`, lines 130-147](aes_mmio.sv#L130-L147)

```systemverilog
OFF_CTRL: begin
    mode_ctr_reg <= write_data_i[2];

    if (write_data_i[0] && !busy_reg) begin
        aes_start_pulse <= 1'b1;
        busy_reg        <= 1'b1;
        done_reg        <= 1'b0;
    end

    if (write_data_i[1]) begin
        done_reg <= 1'b0;
    end
end
```

### Start values

```text
Write 0x00000001 to 0x0300 -> start ECB
Write 0x00000005 to 0x0300 -> start CTR
```

`0x5` is binary `101`, so bit zero starts AES and bit two selects CTR.

The start command does not contain the full plaintext. It tells the accelerator to use the 128-bit values already stored in its internal registers.

---

## 11. ECB and CTR Select Different 128-Bit AES Inputs

Source: [`aes_mmio.sv`, lines 108-110](aes_mmio.sv#L108-L110)

```systemverilog
assign aes_input_block = mode_ctr_reg
                       ? {nonce_reg, counter_reg}
                       : pt_reg;
```

### ECB mode

```text
aes_input_block = pt_reg
ciphertext      = AES_encrypt(key, plaintext)
```

### CTR mode

```text
aes_input_block = {nonce_reg, counter_reg}
keystream       = AES_encrypt(key, nonce || counter)
ciphertext      = pt_reg XOR keystream
```

In CTR mode, the AES primitive encrypts the nonce-counter block. The plaintext is XORed with the resulting keystream after the primitive completes.

---

## 12. The AES Primitive Has True 128-Bit Ports

The compatibility wrapper presents 128-bit inputs and output.

Source: [`aes128_lowpower.sv`, lines 20-46](aes128_lowpower.sv#L20-L46)

```systemverilog
module aes128_lowpower (
    input  logic         clk,
    input  logic         reset,
    input  logic         clk_en,
    input  logic         start,
    input  logic [127:0] plaintext,
    input  logic [127:0] key,
    output logic [127:0] ciphertext,
    output logic         done
);

logic core_busy;

AES128_updated_new u_reusable_aes (
    .clk       (clk),
    .reset     (reset),
    .start     (start && clk_en && !core_busy),
    .busy      (core_busy),
    .done      (done),
    .plaintext (plaintext),
    .key       (key),
    .ciphertext(ciphertext)
);
```

The 32-bit restriction ends at the MMIO boundary. Inside the AES accelerator, plaintext, key, state, round key and ciphertext are all 128 bits wide.

The MMIO wrapper connects its assembled registers to these ports.

Source: [`aes_mmio.sv`, lines 244-255](aes_mmio.sv#L244-L255)

```systemverilog
aes128_lowpower u_aes128_lowpower (
    .clk       (clk),
    .reset     (~rst_n),
    .clk_en    (aes_clk_en),
    .start     (aes_start_pulse),
    .plaintext (aes_input_block),
    .key       (key_reg),
    .ciphertext(aes_ciphertext),
    .done      (aes_done)
);
```

---

## 13. The Reusable AES Core Processes the 128-Bit Block Over Time

The word `iterative` does not mean that the CPU performs 32-bit AES pieces. It means that the dedicated AES hardware reuses the same internal transformation units over multiple clock cycles.

The reusable core contains 128-bit state and round-key registers.

Source: [`rtl/aes128_reusable/00_aes128_top.sv`, lines 43-45](rtl/aes128_reusable/00_aes128_top.sv#L43-L45)

```systemverilog
reg [127:0] state_reg;
reg [127:0] round_key;
reg [3:0]   round;
```

The initial AES operation is a complete 128-bit XOR:

Source: [`rtl/aes128_reusable/00_aes128_top.sv`, lines 73-88](rtl/aes128_reusable/00_aes128_top.sv#L73-L88)

```systemverilog
assign initial_addroundkey  = plaintext ^ key;
assign state_after_shiftrows = shift_rows(sb_out);
assign state_after_roundkey = state_reg ^ new_key;
assign final_round          = (round == 4'd10);
```

The same helper blocks are reused for every round.

Source: [`rtl/aes128_reusable/00_aes128_top.sv`, lines 90-93](rtl/aes128_reusable/00_aes128_top.sv#L90-L93)

```systemverilog
AES_SBOX_SEQ   u_sbox (... .in_block(state_reg), .out_block(sb_out), ...);
AES_MIXCOL_SEQ u_mix  (... .in_block(state_reg), .out_block(mix_out), ...);
AES_KEYEXP_SEQ u_key  (... .round(round), .in_key(round_key), .out_key(new_key), ...);
```

### Iterative round sequence

Source: [`rtl/aes128_reusable/00_aes128_top.sv`, lines 113-189](rtl/aes128_reusable/00_aes128_top.sv#L113-L189)

```systemverilog
S_IDLE: begin
    if (start) begin
        state_reg <= initial_addroundkey;
        round_key <= key;
        round     <= 4'd1;
        busy      <= 1'b1;
        state     <= S_SUB_START;
    end
end

S_SUB_WAIT: begin
    if (sbox_done) begin
        state_reg <= state_after_shiftrows;
        if (!final_round)
            state <= S_MIX_START;
    end
end

S_MIX_WAIT: begin
    if (mix_done) begin
        state_reg <= mix_out;
        state     <= S_KEY_START;
    end
end

S_KEY_WAIT: begin
    if (key_done) begin
        round_key <= new_key;
        state_reg <= state_after_roundkey;

        if (final_round) begin
            ciphertext <= state_after_roundkey;
            state      <= S_DONE;
        end else begin
            round <= round + 4'd1;
            state <= S_SUB_START;
        end
    end
end

S_DONE: begin
    done  <= 1'b1;
    busy  <= 1'b0;
    state <= S_IDLE;
end
```

This sequence explains the hardware reuse:

```text
Round 1: reuse SubBytes -> MixColumns -> Key Expansion
Round 2: reuse the same hardware
...
Round 9: reuse the same hardware
Round 10: reuse SubBytes and Key Expansion, skip MixColumns
```

The CPU is not executing these round states. The AES finite-state machine controls them.

---

## 14. Capturing the 128-Bit Result

When the AES primitive asserts `aes_done`, the MMIO wrapper saves the complete output.

Source: [`aes_mmio.sv`, lines 188-200](aes_mmio.sv#L188-L200)

```systemverilog
if (clk_en_i && aes_done && busy_reg && !aes_start_pulse) begin
    ct_reg   <= mode_ctr_reg
              ? (pt_reg ^ aes_ciphertext)
              : aes_ciphertext;
    busy_reg <= 1'b0;
    done_reg <= 1'b1;

    if (mode_ctr_reg)
        counter_reg <= counter_reg + 64'd1;
end
```

### ECB result

```text
ct_reg = aes_ciphertext
```

### CTR result

```text
ct_reg = pt_reg XOR aes_ciphertext
```

In CTR mode, `aes_ciphertext` is actually the encrypted nonce-counter keystream. XOR produces the final protected sensor block.

The 64-bit counter is incremented automatically after every completed CTR block.

---

## 15. Four 32-Bit Loads Return the Ciphertext

The CPU cannot load all 128 ciphertext bits into one register. It reads four words.

Source: [`aes_mmio.sv`, lines 218-240](aes_mmio.sv#L218-L240)

```systemverilog
if (read_en_i) begin
    case (reg_offset)
        OFF_CT0: read_data_o = ct_reg[31:0];
        OFF_CT1: read_data_o = ct_reg[63:32];
        OFF_CT2: read_data_o = ct_reg[95:64];
        OFF_CT3: read_data_o = ct_reg[127:96];
        default: read_data_o = 32'h0;
    endcase
end
```

For the NIST expected ciphertext:

```text
Ciphertext = 69C4E0D86A7B0430D8CDB78070B4C55A
```

The CPU reads:

| Load | Address | Returned word |
|---|---:|---:|
| `CT0` | `0x0328` | `0x70B4C55A` |
| `CT1` | `0x032C` | `0xD8CDB780` |
| `CT2` | `0x0330` | `0x6A7B0430` |
| `CT3` | `0x0334` | `0x69C4E0D8` |

Joining the words in high-to-low order gives:

```text
{CT3, CT2, CT1, CT0}
= 69C4E0D8 6A7B0430 D8CDB780 70B4C55A
```

---

## 16. The WB Stage Writes One Ciphertext Word into the CPU Register File

Source: [`wb_stage.sv`, lines 1-8](wb_stage.sv#L1-L8)

```systemverilog
module wb_stage (
    input  logic [31:0] alu_result_i,
    input  logic [31:0] mem_read_data_i,
    input  logic        mem_to_reg_i,
    output logic [31:0] wb_data_o
);

assign wb_data_o = mem_to_reg_i ? mem_read_data_i : alu_result_i;
```

For an AES `LW` instruction:

```text
mem_to_reg_i = 1
wb_data_o    = one selected 32-bit ciphertext word
```

The CPU can then store that word in RAM or write its bytes to UART.

---

## 17. Exact Full MMIO Transaction

A complete ECB transaction is conceptually:

```text
1. SW KEY0  -> 0x0308
2. SW KEY1  -> 0x030C
3. SW KEY2  -> 0x0310
4. SW KEY3  -> 0x0314

5. SW PT0   -> 0x0318
6. SW PT1   -> 0x031C
7. SW PT2   -> 0x0320
8. SW PT3   -> 0x0324

9. SW 0x1   -> 0x0300  start ECB
10. LW      <- 0x0304  poll STATUS until done = 1

11. LW CT0  <- 0x0328
12. LW CT1  <- 0x032C
13. LW CT2  <- 0x0330
14. LW CT3  <- 0x0334
```

A complete CTR setup additionally writes:

```text
SW NONCE0 -> 0x0338
SW NONCE1 -> 0x033C
SW COUNT0 -> 0x0340
SW COUNT1 -> 0x0344
SW 0x5    -> 0x0300  start CTR
```

The key, nonce and counter can be reused according to the software protocol, but the same key and nonce-counter combination must never encrypt two different plaintext blocks.

---

## 18. Current Custom-Instruction Path

The custom instruction path is different from the full MMIO data-loading path.

The custom instruction contains two source-register fields:

```text
rs1 = 32 bits
rs2 = 32 bits
total directly available data = 64 bits
```

The MEM stage passes the two 32-bit operands into `aes_mmio`.

Source: [`mem_stage.sv`, lines 176-180](mem_stage.sv#L176-L180)

```systemverilog
.custom_valid_i(custom_valid_i && (custom_cmd_i != 3'b000)),
.custom_cmd_i  (custom_cmd_i),
.custom_rs1_i  (addr_i),
.custom_rs2_i  (write_data_i),
.custom_result_o(aes_custom_result),
```

`CSEC_AES_START` uses those two operands as only the lower 64 plaintext bits.

Source: [`aes_mmio.sv`, lines 165-180](aes_mmio.sv#L165-L180)

```systemverilog
if (clk_en_i && custom_valid_i) begin
    case (custom_cmd_i)
        CSEC_AES_START: begin
            mode_ctr_reg   <= 1'b1;
            pt_reg[31:0]   <= custom_rs1_i;
            pt_reg[63:32]  <= custom_rs2_i;
            pt_reg[127:64] <= 64'h0;

            if (!busy_reg) begin
                aes_start_pulse <= 1'b1;
                busy_reg        <= 1'b1;
                done_reg        <= 1'b0;
            end
        end
    endcase
end
```

### Important consequence

The present `CSEC_AES_START` instruction does not carry a complete 128-bit plaintext.

It produces:

```text
pt_reg = {64'h0000000000000000, rs2, rs1}
```

The current practical flow is therefore:

```text
MMIO stores: load full key, nonce, counter and full plaintext when required
Custom ISA:  start AES, read status, read CT0 and clear done
```

The custom instruction is a compact control experiment. It is not a 128-bit vector instruction.

---

## 19. Custom-Instructions Return Only One 32-Bit Result

Source: [`aes_mmio.sv`, lines 208-216](aes_mmio.sv#L208-L216)

```systemverilog
custom_result_o = 32'h0;
case (custom_cmd_i)
    CSEC_AES_STATUS: custom_result_o = {29'h0, mode_ctr_reg, done_reg, busy_reg};
    CSEC_AES_START:  custom_result_o = {29'h0, mode_ctr_reg, done_reg, busy_reg};
    CSEC_AES_CT0:    custom_result_o = ct_reg[31:0];
    CSEC_AES_CLEAR:  custom_result_o = {31'h0, done_reg};
    default:         custom_result_o = 32'h0;
endcase
```

`CSEC_AES_CT0` returns only `ct_reg[31:0]`. The other three ciphertext words remain available through MMIO loads.

A future custom ISA could add commands such as:

```text
CSEC_AES_PT0
CSEC_AES_PT1
CSEC_AES_PT2
CSEC_AES_PT3
CSEC_AES_CT0
CSEC_AES_CT1
CSEC_AES_CT2
CSEC_AES_CT3
```

Another future option would be a vector extension or register-pair protocol. Neither is implemented in the current RTL.

---

## 20. MMIO and Custom ISA Comparison

| Property | MMIO path | Current custom ISA path |
|---|---|---|
| CPU operand width | 32 bits | Two 32-bit source registers |
| Full 128-bit key loading | Four stores | Not directly supported |
| Full 128-bit plaintext loading | Four stores | Not in one instruction |
| Nonce and counter loading | Four stores total | Uses values already stored |
| Start operation | Store to `CTRL` | `CSEC_AES_START` |
| Status operation | Load from `STATUS` | `CSEC_AES_STATUS` |
| Full ciphertext reading | Four loads | Only `CT0` directly |
| AES internal width | 128 bits | 128 bits |
| AES execution location | AES hardware | AES hardware |

Both paths finally control the same `aes_mmio` wrapper and the same 128-bit reusable AES core.

The ID stage only recognizes the custom opcode. It does not perform AES. The AES command reaches the wrapper through the MEM stage, after which the AES finite-state machine executes independently over multiple clock cycles.

---

## 21. What Happens While AES Is Busy?

Starting AES does not produce the final ciphertext in the same CPU instruction.

The sequence is:

```text
CPU writes START or executes CSEC_AES_START
        |
        v
busy_reg = 1
        |
        v
AES FSM performs all rounds over multiple clock cycles
        |
        v
aes_done = 1
        |
        v
ct_reg captures the 128-bit result
busy_reg = 0
done_reg = 1
```

Software can poll `STATUS`, use `CSEC_AES_STATUS`, or observe the AES done interrupt event.

The processor is 32-bit, but the accelerator continues its own multi-cycle 128-bit operation after the start request.

---

## 22. Why This Architecture Works

Processor width and accelerator width do not need to be equal.

Many processors communicate with wider peripherals by using multiple transfers. Examples include:

- a 32-bit CPU accessing a 64-bit timer using two loads;
- a 32-bit CPU sending a 256-bit hash state through eight words;
- a 32-bit CPU loading a 128-bit AES key through four words.

In this project:

```text
CPU data width             = 32 bits
AES MMIO transfer width    = 32 bits
AES key width              = 128 bits
AES plaintext width        = 128 bits
AES internal state width   = 128 bits
AES ciphertext width       = 128 bits
```

The MMIO wrapper performs the packing and unpacking.

---

## 23. Short Viva Explanation

Use this answer during a viva:

> The RISC-V processor is 32 bits wide, so it cannot hold one complete AES block in a single register. It writes the 128-bit key and plaintext as four consecutive 32-bit MMIO words. The `aes_mmio` wrapper stores these words in slices of 128-bit `key_reg` and `pt_reg`. When the CPU writes the start bit, the wrapper passes the assembled 128-bit values to the dedicated iterative AES accelerator. The AES finite-state machine performs all ten rounds using 128-bit internal state and round-key registers. When encryption is complete, the 128-bit ciphertext is stored in `ct_reg`, and the CPU reads it back as four 32-bit words. Therefore, the CPU handles control and data movement, while the AES hardware performs the actual 128-bit cryptographic computation.

---

## 24. Final Summary

```text
The CPU is 32-bit.
One CPU load or store moves one 32-bit word.

Four stores assemble a 128-bit key.
Four stores assemble a 128-bit plaintext.

The AES accelerator has 128-bit ports and registers.
It performs the actual encryption independently.

The result is stored as one 128-bit ciphertext.
Four loads return that ciphertext to the 32-bit CPU.
```

The design does not convert AES into four independent 32-bit encryptions. It transfers one block in four pieces, reassembles the original 128-bit value, and encrypts that complete value in dedicated 128-bit hardware.
