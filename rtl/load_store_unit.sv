// ============================================================
// LOAD STORE UNIT (LSU)
// ============================================================
//
// Purpose:
// This module handles sub-word memory operations for loads and stores.
// It extracts bytes/halfwords from a 32-bit memory word for loads,
// and merges partial store data into an existing memory word.
//
// ============================================================
//
// DATA FLOW DIAGRAM:
//
//                +-----------------------+
// mem_word_i --->|                       |
//                |   BYTE / HALF SELECT  |----> sel_byte / sel_half
// store_data_i ->|                       |
//                +-----------+-----------+
//                            |
//                            v
//                   +------------------+
//                   |  LOAD GENERATOR  |----> load_data_o
//                   +------------------+
//                            |
//                            v
//                   +------------------------+
//                   | STORE MERGE GENERATOR |
//                   +------------------------+
//                            |
//                            v
//                   merged_store_word_o
//
// ============================================================
//
// FUNCTIONALITY:
//
// LOADS:
//   LB  → Load byte (sign-extended)
//   LH  → Load halfword (sign-extended)
//   LBU → Load byte (zero-extended)
//   LHU → Load halfword (zero-extended)
//   LW  → Load full word (default pass-through)
//
// STORES:
//   SB → Store byte (merge into word)
//   SH → Store halfword (merge into word)
//   SW → Store full word (default pass-through)
//
// ============================================================

// ============================================================
// LOAD STORE UNIT (LSU)
// ============================================================
//
// Purpose:
// This module handles sub-word memory operations for loads and stores.
// It extracts bytes/halfwords from a 32-bit memory word for loads,
// and merges partial store data into an existing memory word.
//
// ============================================================
//
// DATA FLOW DIAGRAM:
//
//                +-----------------------+
// mem_word_i --->|                       |
//                |   BYTE / HALF SELECT  |----> sel_byte / sel_half
// store_data_i ->|                       |
//                +-----------+-----------+
//                            |
//                            v
//                   +------------------+
//                   |  LOAD GENERATOR  |----> load_data_o
//                   +------------------+
//                            |
//                            v
//                   +------------------------+
//                   | STORE MERGE GENERATOR |
//                   +------------------------+
//                            |
//                            v
//                   merged_store_word_o
//
// ============================================================
//
// FUNCTIONALITY:
//
// LOADS:
//   LB  → Load byte (sign-extended)
//   LH  → Load halfword (sign-extended)
//   LBU → Load byte (zero-extended)
//   LHU → Load halfword (zero-extended)
//   LW  → Load full word (default pass-through)
//
// STORES:
//   SB → Store byte (merge into word)
//   SH → Store halfword (merge into word)
//   SW → Store full word (default pass-through)
//
// ============================================================

module load_store_unit (
    input  logic [2:0]  ls_tag_i,          // Load/store type selector
    input  logic [1:0]  byte_off_i,        // Byte offset within 32-bit word
    input  logic [31:0] mem_word_i,        // Data read from memory (full word)
    input  logic [31:0] store_data_i,      // Data to be written to memory
    output logic [31:0] load_data_o,       // Final load output (formatted)
    output logic [31:0] merged_store_word_o// Final store word (merged)
);

    // ========================================================
    // Internal Signals
    // ========================================================

    logic [7:0]  sel_byte;   // Selected byte from memory word
    logic [15:0] sel_half;   // Selected halfword from memory word

    // ========================================================
    // Combinational Logic Block
    // ========================================================
    always_comb begin

        // ----------------------------------------------------
        // BYTE SELECTION (based on address offset)
        //
        // byte_off_i determines which byte is selected:
        //
        //   mem_word_i = [31:24][23:16][15:8][7:0]
        //                   3       2      1     0
        // ----------------------------------------------------
        case (byte_off_i)
            2'b00: sel_byte = mem_word_i[7:0];     // lowest byte
            2'b01: sel_byte = mem_word_i[15:8];
            2'b10: sel_byte = mem_word_i[23:16];
            default: sel_byte = mem_word_i[31:24]; // highest byte
        endcase

        // ----------------------------------------------------
        // HALFWORD SELECTION
        //
        // byte_off_i[1] determines upper or lower half:
        //
        //   0 → lower 16 bits  [15:0]
        //   1 → upper 16 bits  [31:16]
        // ----------------------------------------------------
        sel_half = byte_off_i[1] ? mem_word_i[31:16] : mem_word_i[15:0];

        // ----------------------------------------------------
        // DEFAULT BEHAVIOR (for LW and SW)
        //
        // No modification required:
        // - Load full 32-bit word
        // - Store full 32-bit word
        // ----------------------------------------------------
        load_data_o = mem_word_i;
        merged_store_word_o = store_data_i;

        // ----------------------------------------------------
        // LOAD/STORE TYPE HANDLING
        // ----------------------------------------------------
        case (ls_tag_i)

            // =================================================
            // BYTE OPERATIONS (LB / SB)
            // =================================================
            3'b001: begin
                // -------- LOAD BYTE (signed) --------
                // Sign-extend selected byte to 32 bits
                load_data_o = {{24{sel_byte[7]}}, sel_byte};

                // -------- STORE BYTE --------
                // Replace only the selected byte in memory word
                case (byte_off_i)
                    2'b00: merged_store_word_o = {mem_word_i[31:8], store_data_i[7:0]};
                    2'b01: merged_store_word_o = {mem_word_i[31:16], store_data_i[7:0], mem_word_i[7:0]};
                    2'b10: merged_store_word_o = {mem_word_i[31:24], store_data_i[7:0], mem_word_i[15:0]};
                    default: merged_store_word_o = {store_data_i[7:0], mem_word_i[23:0]};
                endcase
            end

            // =================================================
            // HALFWORD OPERATIONS (LH / SH)
            // =================================================
            3'b010: begin
                // -------- LOAD HALFWORD (signed) --------
                // Sign-extend selected halfword
                load_data_o = {{16{sel_half[15]}}, sel_half};

                // -------- STORE HALFWORD --------
                // Replace either upper or lower 16 bits
                if (byte_off_i[1]) begin
                    // Upper half
                    merged_store_word_o = {store_data_i[15:0], mem_word_i[15:0]};
                end else begin
                    // Lower half
                    merged_store_word_o = {mem_word_i[31:16], store_data_i[15:0]};
                end
            end

            // =================================================
            // LOAD BYTE UNSIGNED (LBU)
            // =================================================
            3'b011: begin
                // Zero-extend byte
                load_data_o = {24'h0, sel_byte};
            end

            // =================================================
            // LOAD HALFWORD UNSIGNED (LHU)
            // =================================================
            3'b100: begin
                // Zero-extend halfword
                load_data_o = {16'h0, sel_half};
            end

            // =================================================
            // DEFAULT CASE (LW / SW already handled)
            // =================================================
            default: begin
                // No change needed
            end
        endcase
    end

endmodule

