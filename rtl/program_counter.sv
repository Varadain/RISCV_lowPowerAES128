// ============================================================
// PROGRAM COUNTER (PC) MODULE
// ============================================================
//
// PURPOSE:
// --------
// The Program Counter (PC) holds the address of the current
// instruction being executed in the processor.
//
// It is updated every clock cycle (if enabled) to point to the
// next instruction.
//
// ------------------------------------------------------------
// ROLE IN PIPELINE:
//
//   [IF STAGE - Instruction Fetch]
//
//        PC ─────────────► Instruction Memory
//         │
//         ▼
//   Fetch instruction at address = PC
//
// ------------------------------------------------------------
// PC UPDATE FLOW:
//
//   Normal execution:
//       next_pc = pc + 4   (next instruction)
//
//   Branch/Jump:
//       next_pc = branch_target
//
// ------------------------------------------------------------
// CONTROL BEHAVIOR:
//
//   rst_n = 0  → PC reset to 0
//   en    = 1  → PC updates to next_pc
//   en    = 0  → PC holds value (stall condition)
//
// ------------------------------------------------------------
// DESIGN NOTES:
//
// - Uses always_ff → synthesizable sequential logic
// - Active-low reset ensures deterministic startup
// - Enable signal supports pipeline stall handling
//
// ============================================================

module program_counter (
  input  logic        clk,      // Clock signal (synchronous update)
  input  logic        rst_n,    // Active-low reset
  input  logic        en,       // Enable signal (controls PC update)
  input  logic [31:0] next_pc,  // Next PC value (from PC+4 or branch)
  output logic [31:0] pc        // Current PC value
);

  // ==========================================================
  // SEQUENTIAL LOGIC: PC REGISTER UPDATE
  // ==========================================================
  //
  // Behavior:
  //   1. On reset → PC = 0
  //   2. If enabled → PC = next_pc
  //   3. If disabled → PC holds its value
  //
  // This supports:
  //   - Normal instruction flow
  //   - Pipeline stalls (when en = 0)
  //
  // ==========================================================

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset condition:
      // Initialize PC to 0 (start of program memory)
      pc <= 32'h0;
    end 
    else if (en) begin
      // Normal operation:
      // Update PC with next instruction address
      pc <= next_pc;
    end
    // If en == 0:
    // PC retains its previous value (stall)
  end

endmodule
