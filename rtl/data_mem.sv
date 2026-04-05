// ============================================================
// DATA MEMORY MODULE (MEM STAGE)
// ============================================================
//
//                MEMORY ARCHITECTURE DIAGRAM
//
//              +------------------------+
//              |      DATA MEMORY       |
//              |      (256 x 32-bit)    |
//              +------------------------+
//                 |              |
//        addr_i --|              |--> read_data_o
//                 |
//        write_data_i --> [WRITE]
//                 |
//        mem_read_i  --> enables read
//        mem_write_i --> enables write
//
// ------------------------------------------------------------
// ADDRESSING:
//   - Word-aligned memory
//   - addr_i[9:2] used as index
//
//   Why?
//   - addr_i is byte address (32-bit)
//   - Lower 2 bits [1:0] ignored (word alignment)
//   - 256 entries → need 8 bits → [9:2]
//
// ------------------------------------------------------------
// MEMORY ORGANIZATION:
//
//   ram[0]   → address 0x000
//   ram[1]   → address 0x004
//   ram[2]   → address 0x008
//   ...
//   ram[255] → address 0x3FC
//
// ------------------------------------------------------------
// READ / WRITE BEHAVIOR:
//
//   WRITE (Synchronous):
//     Happens on clock edge
//
//   READ (Combinational):
//     Immediate output when mem_read_i = 1
//
// ------------------------------------------------------------
// PIPELINE CONTEXT:
//
//   This module is used in the MEM stage:
//
//   EX → MEM → WB
//        ↑
//     data_mem
//
// ------------------------------------------------------------
// KEY FEATURES:
//
//   - Simple single-port memory
//   - Word-aligned access
//   - Synchronous write
//   - Combinational read
//   - Fully synthesizable
//
// ============================================================

module data_mem (
    input  logic        clk,           // Clock signal (used for write operation)
    input  logic [31:0] addr_i,        // Address input (byte address from ALU)
    input  logic [31:0] write_data_i,  // Data to be written into memory
    input  logic        mem_read_i,    // Read enable signal
    input  logic        mem_write_i,   // Write enable signal
    output logic [31:0] read_data_o    // Data output from memory
);

    // ========================================================
    // MEMORY ARRAY DECLARATION
    // ========================================================
    // 256 entries of 32-bit words
    // Total memory size = 256 × 4 bytes = 1 KB
    logic [31:0] ram [0:255];

    integer i;  // Loop variable for initialization

    // ========================================================
    // MEMORY INITIALIZATION
    // ========================================================
    // Initialize all memory locations to zero at simulation start
    initial begin
        for (i = 0; i < 256; i++) begin
            ram[i] = 32'h0;
        end
    end

    // ========================================================
    // WRITE OPERATION (SYNCHRONOUS)
    // ========================================================
    // Happens only on rising edge of clock
    // Ensures stable and predictable write timing
    always_ff @(posedge clk) begin
        if (mem_write_i) begin
            // Use addr_i[9:2] to select word index
            // (ignores lower 2 bits → word alignment)
            ram[addr_i[9:2]] <= write_data_i;
        end
    end

    // ========================================================
    // READ OPERATION (COMBINATIONAL)
    // ========================================================
    // If mem_read_i is high → output memory value
    // Else → output zero (safe default)
    assign read_data_o = mem_read_i ? ram[addr_i[9:2]] : 32'h0;

endmodule
