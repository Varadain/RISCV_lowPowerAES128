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
//   - Sign/zero extension for load
//   - Store data merging for SB/SH
//   - Memory-mapped AES accelerator accesses
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
    input  logic        rst_n,          // Active-low reset for peripherals
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
    logic [31:0] mem_read_data;       // Data path for normal data memory

    // AES MMIO decode/control signals
    logic        aes_sel;
    logic        aes_write_en;
    logic        aes_read_en;
    logic [31:0] aes_read_data;

    logic        data_mem_read_en;
    logic        data_mem_write_en;
    // --------------------------------------------------------
    // Address Decoding
    // --------------------------------------------------------
    // Upper 3 bits used to encode load/store type
    // Remaining bits used as actual memory address

    assign ls_tag   = addr_i[31:29];          // Extract operation type
    assign eff_addr = {3'b000, addr_i[28:0]}; // Mask upper bits for real address
    
    // AES MMIO range: 0x300 - 0x33F
    assign aes_sel      = (eff_addr[31:6] == 26'h000000c);
    assign aes_write_en = mem_write_i & aes_sel;
    assign aes_read_en  = mem_read_i & aes_sel;
    // --------------------------------------------------------
    // Load/Store Unit
    // --------------------------------------------------------
    // Responsible for:
    //   - Extracting correct byte/halfword from memory word
    //   - Performing sign/zero extension for loads
    //   - Creating merged word for store operations (SB/SH)

    load_store_unit u_load_store_unit (
         .ls_tag_i           (ls_tag),
        .byte_off_i         (eff_addr[1:0]),
        .mem_word_i         (raw_mem_word),
        .store_data_i       (write_data_i),
        .load_data_o        (mem_read_data),
        .merged_store_word_o(merged_store_word)
    );

  
    assign data_mem_read_en  = (mem_read_i | mem_write_i) & ~aes_sel;
    assign data_mem_write_en = mem_write_i & ~aes_sel;

    data_mem u_data_mem (
        .clk(clk),

        // Address for memory access
        .addr_i(eff_addr),

        // Write data:
        //   - If normal store (SW): use write_data_i
        //   - If partial store (SB/SH): use merged_store_word
        .write_data_i((ls_tag == 3'b000) ? write_data_i : merged_store_word),
        .mem_read_i(data_mem_read_en),
        .mem_write_i(data_mem_write_en),
        .read_data_o(raw_mem_word)
    );
           aes_mmio u_aes_mmio (
        .clk(clk),
        .rst_n(rst_n),
        .addr_i(eff_addr),
        .write_data_i(write_data_i),
        .write_en_i(aes_write_en),
        .read_en_i(aes_read_en),
        .read_data_o(aes_read_data)
    );

    // Select between data memory reads and AES MMIO reads
    assign read_data_o = aes_sel ? aes_read_data : mem_read_data;

endmodule
