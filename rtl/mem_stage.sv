// ============================================================
// MEM STAGE (Memory Access Stage)
// ============================================================
//
// This stage performs:
//   1. Load operations  (read from memory)
//   2. Store operations (write to memory)
//
// It also handles:
//   - Subword accesses (byte, halfword)
//   - Sign/zero extension for loads
//   - Store data merging for SB/SH
//
// ------------------------------------------------------------
// DATA FLOW DIAGRAM:
//
//          EX STAGE OUTPUT
//                |
//                v
//        +------------------+
//        |   Address Decode |
//        |  (ls_tag split)  |
//        +------------------+
//          |            |
//          |            v
//          |      +---------------------+
//          |      | load_store_unit     |
//          |      | - byte select       |
//          |      | - sign extend       |
//          |      | - store merge       |
//          |      +---------------------+
//          |            |
//          v            v
//     +--------------------------+
//     |        data_mem          |
//     |   (actual memory array)  |
//     +--------------------------+
//                |
//                v
//          Final Read Data
//
// ------------------------------------------------------------
// ADDRESS FORMAT:
//
//   addr_i[31:29] → ls_tag   → defines load/store type
//   addr_i[28:0]  → eff_addr → actual memory address
//
// Example:
//   LB, LH, LBU, LHU → encoded in ls_tag
//
// ------------------------------------------------------------
// KEY DESIGN IDEA:
//
//   - Memory always reads full 32-bit word
//   - load_store_unit extracts correct bytes
//   - Stores use read-modify-write (for SB/SH)
//
// ============================================================

module mem_stage (
    input  logic        clk,            // System clock
    input  logic [31:0] addr_i,         // Address from EX stage (ALU result)
    input  logic [31:0] write_data_i,   // Data to be written (for store)
    input  logic        mem_read_i,     // Load enable signal
    input  logic        mem_write_i,    // Store enable signal
    output logic [31:0] read_data_o     // Final processed read data
);

    // --------------------------------------------------------
    // Internal Signals
    // --------------------------------------------------------

    logic [2:0]  ls_tag;              // Load/Store type tag (LB, LH, LW, etc.)
    logic [31:0] eff_addr;            // Effective address (actual memory address)

    logic [31:0] raw_mem_word;        // Raw 32-bit word read from memory
    logic [31:0] merged_store_word;   // Modified word for partial store (SB/SH)

    // --------------------------------------------------------
    // Address Decoding
    // --------------------------------------------------------
    // Upper 3 bits used to encode load/store type
    // Remaining bits used as actual memory address

    assign ls_tag   = addr_i[31:29];          // Extract operation type
    assign eff_addr = {3'b000, addr_i[28:0]}; // Mask upper bits for real address

    // --------------------------------------------------------
    // Load/Store Unit
    // --------------------------------------------------------
    // Responsible for:
    //   - Extracting correct byte/halfword from memory word
    //   - Performing sign/zero extension for loads
    //   - Creating merged word for store operations (SB/SH)

    load_store_unit u_load_store_unit (
        .ls_tag_i           (ls_tag),              // Load/store type
        .byte_off_i         (eff_addr[1:0]),       // Byte offset within word
        .mem_word_i         (raw_mem_word),        // Raw memory data
        .store_data_i       (write_data_i),        // Data to be stored
        .load_data_o        (read_data_o),         // Final processed load data
        .merged_store_word_o(merged_store_word)    // Modified store word
    );

    // --------------------------------------------------------
    // Data Memory Block
    // --------------------------------------------------------
    // Performs:
    //   - Memory read (for both load and store operations)
    //   - Memory write (for store operations)
    //
    // Important:
    //   - For SB/SH, memory performs read-modify-write
    //   - merged_store_word ensures correct byte/half update

    data_mem u_data_mem (
        .clk(clk),

        // Address for memory access
        .addr_i(eff_addr),

        // Write data:
        //   - If normal store (SW): use write_data_i
        //   - If partial store (SB/SH): use merged_store_word
        .write_data_i((ls_tag == 3'b000) ? write_data_i : merged_store_word),

        // Memory read enabled for both load and store:
        //   - Store needs read for merge operation
        .mem_read_i(mem_read_i | mem_write_i),

        // Write enable
        .mem_write_i(mem_write_i),

        // Raw 32-bit data output
        .read_data_o(raw_mem_word)
    );

endmodule
