// ============================================================
// REGISTER FILE (32 x 32-bit)
// ============================================================
//
// ARCHITECTURE OVERVIEW:
//
//                +-------------------------+
//   rs1_i -----> |                         | -----> rs1_data_o
//                |                         |
//   rs2_i -----> |     REGISTER FILE       | -----> rs2_data_o
//                |        (32 x 32)        |
//   rd_i  -----> |                         |
//   rd_data_i -->|                         |
//   rd_we_i ---->|                         |
//                +-------------------------+
//
// ------------------------------------------------------------
// DESCRIPTION:
//
// - Contains 32 registers (x0 to x31), each 32 bits wide
// - Supports:
//     * Two simultaneous reads (rs1, rs2)
//     * One write (rd)
//
// ------------------------------------------------------------
// SPECIAL RISC-V RULE:
//
// - Register x0 is hardwired to zero
// - Any read from x0 returns 0
// - Writes to x0 are ignored
//
// ------------------------------------------------------------
// BYPASS (WRITE-FORWARDING) LOGIC:
//
// This module implements "same-cycle bypass":
//
//   If instruction writes to rd and reads same register:
//     → return rd_data_i directly (no need to wait for clock)
//
// Example:
//   ADD x1, x2, x3
//   SUB x4, x1, x5   (same cycle read of x1)
//
// Without bypass → wrong value
// With bypass    → correct value
//
// ------------------------------------------------------------
// READ PRIORITY:
//
//   1. If rs == x0 → return 0
//   2. Else if bypass condition → return write data
//   3. Else → return stored register value
//
// ------------------------------------------------------------
// WRITE BEHAVIOR:
//
// - Happens on positive clock edge
// - Only if:
//     rd_we_i = 1 AND rd_i != 0
//
// ============================================================

module reg_file (
    input  logic        clk,
    input  logic [4:0]  rs1_i,
    input  logic [4:0]  rs2_i,
    input  logic [4:0]  rd_i,
    input  logic [31:0] rd_data_i,
    input  logic        rd_we_i,

    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o
);

    logic [31:0] regs [0:31];

    // ---------------- Bypass ----------------
    logic rs1_bypass;
    logic rs2_bypass;

    assign rs1_bypass = rd_we_i && (rd_i != 5'h0) && (rd_i == rs1_i);
    assign rs2_bypass = rd_we_i && (rd_i != 5'h0) && (rd_i == rs2_i);

    // ---------------- Read ----------------
    assign rs1_data_o =
        (rs1_i == 5'h0) ? 32'h0 :
        (rs1_bypass     ? rd_data_i : regs[rs1_i]);

    assign rs2_data_o =
        (rs2_i == 5'h0) ? 32'h0 :
        (rs2_bypass     ? rd_data_i : regs[rs2_i]);

    // ---------------- Write ----------------
    always_ff @(posedge clk) begin
        if (rd_we_i && (rd_i != 5'h0)) begin
            regs[rd_i] <= rd_data_i;
        end

        // enforce x0 = 0 every cycle (important)
        regs[0] <= 32'h0;
    end

endmodule
