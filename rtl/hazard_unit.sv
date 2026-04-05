// ============================================================
// HAZARD UNIT (LOAD-USE DATA HAZARD DETECTION)
// ============================================================
//
// PURPOSE:
// --------
// This module detects a specific type of pipeline hazard called
// a "load-use hazard" and generates control signals to:
//   - Stall the pipeline
//   - Flush incorrect instructions
//
// ------------------------------------------------------------
// WHAT IS A LOAD-USE HAZARD?
//
// Occurs when:
//
//   1. An instruction in EX stage is a LOAD instruction
//   2. The next instruction (in ID stage) needs that data
//   3. BUT the data is not yet available (still in memory stage)
//
// ------------------------------------------------------------
// PIPELINE SCENARIO:
//
//   Cycle N:
//
//      IF      ID        EX        MEM       WB
//    -------------------------------------------------
//             ADD       LW
//
//   Cycle N+1:
//
//      IF      ID        EX        MEM       WB
//              ADD       LW
//
// Problem:
// --------
// ADD needs data loaded by LW, but LW hasn't completed yet.
//
// ------------------------------------------------------------
// DATA DEPENDENCY:
//
//   LW   x5, 0(x1)     ← loads into x5
//   ADD  x6, x5, x2    ← needs x5 immediately 
//
// ------------------------------------------------------------
// SOLUTION:
//
//   - Stall pipeline for 1 cycle
//   - Insert NOP (flush)
//   - Wait until data becomes available
//
// ------------------------------------------------------------
// VISUAL DIAGRAM:
//
//   Without Stall (WRONG):
//
//     LW   → EX → MEM → WB
//     ADD  → ID → EX → MEM → WB   (uses wrong data )
//
//   With Stall (CORRECT):
//
//     LW   → EX → MEM → WB
//     ADD  → ID → STALL → EX → MEM → WB
//
// ------------------------------------------------------------
// INPUT SIGNALS:
//
//   id_rs1_i, id_rs2_i → Source registers of instruction in ID
//   ex_rd_i            → Destination register of instruction in EX
//   ex_mem_read_i      → Indicates EX instruction is LOAD
//
// ------------------------------------------------------------
// OUTPUT SIGNALS:
//
//   stall_o      → Freeze PC and IF stage
//   flush_ifid_o → Insert NOP into pipeline
//
// ============================================================

module hazard_unit (
    input  logic [4:0] id_rs1_i,   // Source register 1 (ID stage)
    input  logic [4:0] id_rs2_i,   // Source register 2 (ID stage)
    input  logic [4:0] ex_rd_i,    // Destination register (EX stage)
    input  logic       ex_mem_read_i, // Indicates EX instruction is a LOAD

    output logic       stall_o,       // Stall signal for pipeline
    output logic       flush_ifid_o   // Flush IF/ID register (insert NOP)
);

    // --------------------------------------------------------
    // COMBINATIONAL LOGIC
    // This block continuously checks for hazard conditions
    // --------------------------------------------------------
    always_comb begin

        // Default: No hazard → No stall, No flush
        stall_o = 1'b0;
        flush_ifid_o = 1'b0;

        // ----------------------------------------------------
        // HAZARD DETECTION CONDITION
        //
        // Condition Breakdown:
        //
        // 1. ex_mem_read_i == 1
        //    → EX stage instruction is a LOAD
        //
        // 2. ex_rd_i != 0
        //    → Ignore x0 (always zero, no dependency)
        //
        // 3. ex_rd_i matches ID stage source registers
        //    → Data dependency detected
        //
        // ----------------------------------------------------
        if (ex_mem_read_i &&                      // Load instruction in EX
            (ex_rd_i != 5'h0) &&                  // Not x0 register
            ((ex_rd_i == id_rs1_i) ||             // Dependency on rs1
             (ex_rd_i == id_rs2_i))) begin        // Dependency on rs2

            // ------------------------------------------------
            // ACTION TAKEN:
            //
            // 1. Stall pipeline (freeze PC + IF)
            // 2. Flush IF/ID (insert NOP)
            //
            // This gives time for LOAD to complete
            // ------------------------------------------------
            stall_o = 1'b1;
            flush_ifid_o = 1'b1;
        end
    end

endmodule
