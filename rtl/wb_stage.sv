// ============================================================
// WRITEBACK (WB) STAGE
// ============================================================
//
// FUNCTION:
// This stage selects the final result that will be written
// back into the register file (rd).
//
// ------------------------------------------------------------
// DATA FLOW DIAGRAM:
//
//             +----------------------+
/*           |      WB STAGE        |
             |----------------------|
             |                      |
             |  mem_to_reg_i       |
             |        │             |
             |        ▼             |
             |   ┌────────────┐     |
             |   │   MUX      │     |
             |   └────────────┘     |
             |    ▲          ▲      |
             |    │          │      |
             | alu_result   mem_data|
             |    │          │      |
             +----┼----------┼------+
                  │          │
                  ▼          ▼
         ALU result     Data memory output
                  │
                  ▼
             wb_data_o  → Register File
*/
//
// ------------------------------------------------------------
// OPERATION:
//
// If instruction is a LOAD:
//    wb_data_o = mem_read_data_i
//
// Else (ALU operation):
//    wb_data_o = alu_result_i
//
// ------------------------------------------------------------
// CONTROL SIGNAL:
//
// mem_to_reg_i:
//    1 → Select memory data (for load instructions)
//    0 → Select ALU result (for arithmetic/logical instructions)
//
// ------------------------------------------------------------
// PIPELINE CONTEXT:
//
// This is the final stage of the 5-stage pipeline:
// IF → ID → EX → MEM → WB
//
// The output (wb_data_o) is fed back to:
// - Register file write port
//
// ============================================================

module wb_stage (
    input  logic [31:0] alu_result_i,      // Result from ALU (EX stage)
    input  logic [31:0] mem_read_data_i,   // Data read from memory (MEM stage)
    input  logic        mem_to_reg_i,      // Control signal to select source
    output logic [31:0] wb_data_o          // Final data written back to register file
);

    // --------------------------------------------------------
    // Multiplexer logic:
    // Select between ALU result and memory data
    // --------------------------------------------------------
    assign wb_data_o = mem_to_reg_i ? mem_read_data_i : alu_result_i;

endmodule
