// ============================================================
// IMMEDIATE GENERATOR (imm_gen)
// ============================================================
//
// PURPOSE:
// This module extracts and generates the correct 32-bit immediate
// value from a 32-bit RISC-V instruction based on instruction type.
//
// ------------------------------------------------------------
// RISC-V IMMEDIATE FORMATS
//
// Instruction Encoding (32-bit):
//
//    [31...............................0]
//    | imm | rs1 | funct3 | rd | opcode |
//
// Different instruction types use different bit fields:
//
// ------------------------------------------------------------
// I-TYPE FORMAT (e.g., ADDI, LW, JALR)
//
//   [31:20] = immediate (12-bit signed)
//
//   imm[31:0] = sign_extend(instr[31:20])
//
// ------------------------------------------------------------
// S-TYPE FORMAT (e.g., SW)
//
//   [31:25] + [11:7] = immediate
//
//   imm = sign_extend({instr[31:25], instr[11:7]})
//
// ------------------------------------------------------------
// B-TYPE FORMAT (e.g., BEQ, BNE)
//
//   imm[12|10:5|4:1|11|0]
//
//   imm = sign_extend({
//           instr[31],     // bit 12 (sign)
//           instr[7],      // bit 11
//           instr[30:25],  // bits 10:5
//           instr[11:8],   // bits 4:1
//           0              // always 0 (alignment)
//        })
//
// ------------------------------------------------------------
// U-TYPE FORMAT (LUI, AUIPC)
//
//   imm = {instr[31:12], 12'b0}
//
// ------------------------------------------------------------
// J-TYPE FORMAT (JAL)
//
//   imm[20|10:1|11|19:12|0]
//
//   imm = sign_extend({
//           instr[31],       // bit 20 (sign)
//           instr[19:12],    // bits 19:12
//           instr[20],       // bit 11
//           instr[30:21],    // bits 10:1
//           0                // alignment
//        })
//
// ------------------------------------------------------------
// SPECIAL CASE: SHIFT IMMEDIATES (SLLI, SRLI, SRAI)
//
//   Uses shamt (shift amount) instead of signed immediate
//   instr[24:20] → zero-extended (NOT sign-extended)
//
// ------------------------------------------------------------
// DATA FLOW DIAGRAM
//
//        instr_i (32-bit)
//               │
//               ▼
//        ┌───────────────┐
//        │ Decode opcode │
//        └───────────────┘
//               │
//     ┌─────────┼──────────────┐
//     ▼         ▼              ▼
//   I-type    S-type        B-type ...
//     │         │              │
//     ▼         ▼              ▼
//  sign-ext   concat       rearrange bits
//     │         │              │
//     └─────────┴──────────────┘
//               ▼
//           imm_o (32-bit)
//
// ============================================================

module imm_gen (
    input  logic [31:0] instr_i,  // Full 32-bit instruction input
    output logic [31:0] imm_o     // Generated immediate output
);

    // Extract opcode (bits [6:0]) to determine instruction type
    logic [6:0] opcode;

    // Extract funct3 (bits [14:12]) for sub-type decoding
    logic [2:0] funct3;

    // Assign opcode and funct3 from instruction
    assign opcode = instr_i[6:0];
    assign funct3 = instr_i[14:12];

    // ========================================================
    // COMBINATIONAL LOGIC
    // Generates immediate based on instruction format
    // ========================================================
    always_comb begin

        // Select immediate format based on opcode
        case (opcode)

            // ------------------------------------------------
            // I-TYPE ALU INSTRUCTIONS (ADDI, ANDI, ORI, etc.)
            // ------------------------------------------------
            7'b0010011: begin

                // Special case: shift instructions (SLLI, SRLI, SRAI)
                // These use shamt (shift amount) from bits [24:20]
                // and are ZERO-EXTENDED (not sign-extended)
                if ((funct3 == 3'b001) || (funct3 == 3'b101)) begin
                    imm_o = {27'h0, instr_i[24:20]};
                end 
                else begin
                    // Standard I-type: sign-extend 12-bit immediate
                    imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                end
            end

            // ------------------------------------------------
            // I-TYPE (LOAD, JALR, SYSTEM, FENCE)
            // ------------------------------------------------
            // All use standard 12-bit sign-extended immediate
            7'b0000011, // LOAD instructions (LB, LH, LW, etc.)
            7'b1100111, // JALR
            7'b1110011, // SYSTEM (ECALL, EBREAK)
            7'b0001111: // FENCE / FENCE.I
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]};

            // ------------------------------------------------
            // S-TYPE (STORE INSTRUCTIONS)
            // ------------------------------------------------
            // Immediate split across two fields:
            // [31:25] and [11:7]
            7'b0100011:
                imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};

            // ------------------------------------------------
            // B-TYPE (BRANCH INSTRUCTIONS)
            // ------------------------------------------------
            // Non-linear bit arrangement + implicit shift (×2)
            7'b1100011:
                imm_o = {
                    {19{instr_i[31]}}, // sign extension
                    instr_i[31],       // bit 12
                    instr_i[7],        // bit 11
                    instr_i[30:25],    // bits 10:5
                    instr_i[11:8],     // bits 4:1
                    1'b0               // alignment (LSB = 0)
                };

            // ------------------------------------------------
            // U-TYPE (LUI, AUIPC)
            // ------------------------------------------------
            // Upper 20 bits used, lower 12 bits are zero
            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_o = {instr_i[31:12], 12'h000};

            // ------------------------------------------------
            // J-TYPE (JAL)
            // ------------------------------------------------
            // Complex bit reordering + implicit shift
            7'b1101111:
                imm_o = {
                    {11{instr_i[31]}}, // sign extension
                    instr_i[31],       // bit 20
                    instr_i[19:12],    // bits 19:12
                    instr_i[20],       // bit 11
                    instr_i[30:21],    // bits 10:1
                    1'b0               // alignment
                };

            // ------------------------------------------------
            // DEFAULT CASE
            // ------------------------------------------------
            default:
                imm_o = 32'h0; // Safe fallback

        endcase
    end

endmodule
