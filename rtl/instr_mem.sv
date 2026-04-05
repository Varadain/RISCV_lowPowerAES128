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

module instr_mem (
    input  logic [31:0] addr_i,   // Byte address from Program Counter (PC)
    output logic [31:0] instr_o   // Instruction output (32-bit)
);

    // --------------------------------------------------------
    // ROM DECLARATION
    // --------------------------------------------------------
    // 256 words of 32-bit instructions
    // Total memory = 256 * 4 bytes = 1 KB
    // --------------------------------------------------------
    logic [31:0] rom [0:255];

    // --------------------------------------------------------
    // INITIAL BLOCK (SIMULATION ONLY)
    // --------------------------------------------------------
    // Initializes instruction memory with a small test program
    // --------------------------------------------------------
    initial begin
        integer i;

        // ----------------------------------------------------
        // Default initialization:
        // Fill entire memory with NOP instructions
        //
        // NOP = ADDI x0, x0, 0 = 32'h00000013
        //
        // This ensures:
        // - Safe execution if PC goes out of program range
        // - No unintended behavior
        // ----------------------------------------------------
        for (i = 0; i < 256; i++) begin
            rom[i] = 32'h00000013;
        end

        // ----------------------------------------------------
        // TEST PROGRAM LOADED INTO ROM
        // ----------------------------------------------------
        // This program demonstrates:
        // - Arithmetic operations
        // - Memory access (load/store)
        // - Branching
        // ----------------------------------------------------

        // Address 0:
        // x1 = 5
        rom[0] = 32'h00500093; // addi x1, x0, 5

        // Address 4:
        // x2 = 10
        rom[1] = 32'h00A00113; // addi x2, x0, 10

        // Address 8:
        // x3 = x1 + x2 = 15
        rom[2] = 32'h002081B3; // add x3, x1, x2

        // Address 12:
        // Store x3 (15) to memory[0]
        rom[3] = 32'h00302023; // sw x3, 0(x0)

        // Address 16:
        // Load memory[0] into x4
        rom[4] = 32'h00002203; // lw x4, 0(x0)

        // Address 20:
        // If x4 == x3, branch forward by 8 bytes
        rom[5] = 32'h00320463; // beq x4, x3, +8

        // Address 24:
        // This executes ONLY if branch fails
        rom[6] = 32'h00100293; // addi x5, x0, 1

        // Address 28:
        // NOP (pipeline safe)
        rom[7] = 32'h00000013; // nop
    end

    // --------------------------------------------------------
    // INSTRUCTION READ
    // --------------------------------------------------------
    // Word-aligned access:
    // addr_i[9:2] selects instruction index
    //
    // This is a combinational read:
    // instruction is available immediately
    // --------------------------------------------------------
    assign instr_o = rom[addr_i[9:2]];

endmodule
