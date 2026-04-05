// ============================================================
// FORWARDING UNIT (Data Hazard Resolution)
// ============================================================
//
// PURPOSE:
// --------
// This module resolves **data hazards** in a pipelined RISC-V CPU
// by forwarding data from later pipeline stages (MEM/WB)
// back to the EX stage, avoiding pipeline stalls.
//
// ------------------------------------------------------------
// PIPELINE CONTEXT:
//
//   IF → ID → EX → MEM → WB
//
// The EX stage needs operands (rs1, rs2), but the correct value
// may still be in MEM or WB stage (not yet written back).
//
// ------------------------------------------------------------
// FORWARDING PATH DIAGRAM:
//
//                ┌───────────────┐
//                │   WB Stage    │
//                │ (writeback)   │
//                └───────┬───────┘
//                        │
//                        ▼
//   ID → EX → ALU → MEM → WB
//        ↑        ↑
//        │        │
//        │        └────────────── Forward from MEM (2'b10)
//        │
//        └────────────────────── Forward from WB  (2'b01)
//
// ------------------------------------------------------------
// FORWARDING CONTROL SIGNALS:
//
// forward_a_o (for rs1):
//   00 → Use original rs1_data (no forwarding)
//   10 → Forward from MEM stage
//   01 → Forward from WB stage
//
// forward_b_o (for rs2):
//   Same encoding as above
//
// ------------------------------------------------------------
// PRIORITY:
// ---------
// MEM stage has higher priority than WB stage because it has
// more recent data.
//
// ------------------------------------------------------------
// SPECIAL CASE:
// ------------
// Register x0 (zero register) is ignored because it is always 0.
//
// ============================================================

module forwarding_unit (
    input  logic [4:0] ex_rs1_i,   // Source register 1 in EX stage
    input  logic [4:0] ex_rs2_i,   // Source register 2 in EX stage
    input  logic [4:0] mem_rd_i,   // Destination register in MEM stage
    input  logic [4:0] wb_rd_i,    // Destination register in WB stage
    input  logic       mem_reg_write_i, // MEM stage writes to register?
    input  logic       wb_reg_write_i,  // WB stage writes to register?
    output logic [1:0] forward_a_o,     // Forward control for rs1
    output logic [1:0] forward_b_o      // Forward control for rs2
);

    // ========================================================
    // COMBINATIONAL LOGIC
    // Determines forwarding decisions every cycle
    // ========================================================
    always_comb begin
        // Default: no forwarding (use register file values)
        forward_a_o = 2'b00;
        forward_b_o = 2'b00;

        // ====================================================
        // FORWARDING FOR rs1 (Operand A)
        // ====================================================

        // Case 1: Forward from MEM stage (highest priority)
        if (mem_reg_write_i &&               // MEM stage writes
            (mem_rd_i != 5'h0) &&            // Not x0 register
            (mem_rd_i == ex_rs1_i)) begin    // Dependency match

            forward_a_o = 2'b10;             // Select MEM result

        end 
        // Case 2: Forward from WB stage
        else if (wb_reg_write_i &&           // WB stage writes
                 (wb_rd_i != 5'h0) &&        // Not x0
                 (wb_rd_i == ex_rs1_i)) begin

            forward_a_o = 2'b01;             // Select WB result
        end

        // ====================================================
        // FORWARDING FOR rs2 (Operand B)
        // ====================================================

        // Case 1: Forward from MEM stage
        if (mem_reg_write_i &&
            (mem_rd_i != 5'h0) &&
            (mem_rd_i == ex_rs2_i)) begin

            forward_b_o = 2'b10;

        end 
        // Case 2: Forward from WB stage
        else if (wb_reg_write_i &&
                 (wb_rd_i != 5'h0) &&
                 (wb_rd_i == ex_rs2_i)) begin

            forward_b_o = 2'b01;
        end
    end

endmodule
