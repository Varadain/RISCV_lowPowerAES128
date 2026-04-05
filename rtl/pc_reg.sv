// ============================================================
// PROGRAM COUNTER REGISTER (pc_reg)
// ============================================================
//
// FUNCTION:
// This module implements the Program Counter (PC) register,
// which holds the address of the current instruction.
//
// The PC is updated every clock cycle unless a stall occurs.
//
// ------------------------------------------------------------
// OPERATION:
//
//   On RESET:
//      PC ← 0
//
//   On CLOCK EDGE (posedge clk):
//      if (stall == 0)
//          PC ← next_pc
//      else
//          PC remains unchanged
//
// ------------------------------------------------------------
// PIPELINE CONTEXT:
//
//          +---------------------+
//          |     pc_reg          |
//          |---------------------|
//          | current_pc (output) |
//          +----------+----------+
//                     |
//                     v
//               Instruction Memory
//                     |
//                     v
//                  IF Stage
//
// ------------------------------------------------------------
// CONTROL BEHAVIOR:
//
//   stall = 1 → Freeze PC (used during hazards)
//   stall = 0 → Normal sequential execution
//
// ------------------------------------------------------------
// NEXT PC LOGIC (from top-level):
//
//   next_pc = branch_taken ? branch_target : (PC + 4)
//
// This enables:
//   - Sequential instruction flow (PC + 4)
//   - Branch/jump redirection
//
// ------------------------------------------------------------
// DESIGN NOTES:
//
// - Uses asynchronous active-low reset
// - Uses synchronous update on clock edge
// - Minimal logic for high-speed pipeline operation
//
// ============================================================

module pc_reg (
    input  logic        clk,         // System clock
    input  logic        rst_n,       // Active-low reset
    input  logic        stall,       // Stall signal to freeze PC update
    input  logic [31:0] next_pc,     // Next PC value (sequential or branch)
    output logic [31:0] current_pc   // Current PC value (used in IF stage)
);

    // ========================================================
    // PC REGISTER UPDATE LOGIC
    // ========================================================
    // - Reset initializes PC to 0
    // - PC updates only when stall is not asserted
    // ========================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset condition: start execution from address 0
            current_pc <= 32'h0;
        end 
        else if (!stall) begin
            // Normal operation: update PC to next instruction address
            current_pc <= next_pc;
        end
        // If stall == 1, PC holds its previous value (pipeline freeze)
    end

endmodule
