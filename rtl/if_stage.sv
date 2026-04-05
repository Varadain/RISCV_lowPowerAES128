// ============================================================
// IF STAGE (Instruction Fetch Stage)
// ============================================================
//
// PIPELINE POSITION:
//
//   ┌────────┐
//   │   IF   │ → → → ID → EX → MEM → WB
//   └────────┘
//
// FUNCTION:
//
//   The IF (Instruction Fetch) stage is responsible for:
//   1. Receiving the current Program Counter (PC)
//   2. Fetching the corresponding instruction from instruction memory
//   3. Sending the instruction to the next pipeline stage (ID)
//
// ------------------------------------------------------------
// DATA FLOW:
//
//   pc_i (Program Counter)
//        │
//        ▼
//   ┌──────────────┐
//   │ instr_mem    │   (Instruction Memory)
//   └──────────────┘
//        │
//        ▼
//   instr_o (Fetched Instruction)
//
// ------------------------------------------------------------
// KEY NOTES:
//
//   - This stage is purely combinational (no registers here)
//   - Instruction memory is read using the PC as address
//   - PC update logic is handled in pc_reg (not here)
//   - Output is passed to IF/ID pipeline register
//
// ============================================================

module if_stage (
    input  logic [31:0] pc_i,     // Input: Program Counter (address of instruction)
    output logic [31:0] instr_o   // Output: Instruction fetched from memory
);

    // --------------------------------------------------------
    // Instruction Memory Instance
    // --------------------------------------------------------
    //
    // This module represents the instruction memory.
    // It takes the PC as input and returns the instruction
    // stored at that address.
    //
    // addr_i  → address input (PC)
    // instr_o → instruction output
    //
    instr_mem u_instr_mem (
        .addr_i (pc_i),       // Address input to instruction memory
        .instr_o(instr_o)     // Instruction output from memory
    );

endmodule
