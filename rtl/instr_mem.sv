// ============================================================
// INSTRUCTION MEMORY (ROM)
// ============================================================
//
// PURPOSE:
// --------
// This module represents the instruction memory of the processor.
// It stores program instructions and provides the instruction
// corresponding to the current Program Counter (PC).
//
// This is a READ-ONLY MEMORY (ROM) initialized at simulation time.
//
// ============================================================
//
// MEMORY ORGANIZATION:
//
//   Address (byte) → Instruction (32-bit)
//
//   addr_i (byte address)
//        |
//        |  [9:2] used → word aligned access
//        v
//   +---------------------------+
//   |        ROM ARRAY          |
//   |   256 entries (32-bit)    |
//   +---------------------------+
//        |
//        v
//     instr_o (output)
//
// ============================================================
//
// ADDRESSING LOGIC:
//
//   addr_i[31:0]  → full byte address
//
//   addr_i[9:2]   → word index
//
// Why [9:2]?
// -----------
// - Each instruction is 4 bytes (32 bits)
// - Lower 2 bits (addr_i[1:0]) are always 0 (alignment)
// - So we ignore them and use [9:2] as index
//
// Example:
//   PC = 0x00000000 → index = 0
//   PC = 0x00000004 → index = 1
//   PC = 0x00000008 → index = 2
//
// ============================================================
//
// PIPELINE CONTEXT:
//
//   IF STAGE:
//
//        PC → instr_mem → Instruction
//
//   This module is used in the Instruction Fetch stage.
//
// ============================================================

`timescale 1ns/1ps
module instr_mem (
    input  logic [31:0] addr_i,
    output logic [31:0] instr_o
);
    logic [31:0] rom [0:255];

    // NO initial block → testbench controls memory

    assign instr_o = rom[addr_i[9:2]]; // word aligned

endmodule
