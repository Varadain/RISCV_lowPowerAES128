// ============================================================
// ID STAGE (Instruction Decode Stage)
// ============================================================
//
// PIPELINE POSITION:
//
//   IF → ID → EX → MEM → WB
//
// This stage is responsible for:
//   1. Decoding the instruction
//   2. Extracting register addresses (rs1, rs2, rd)
//   3. Reading register values from register file
//   4. Generating immediate values
//   5. Generating control signals for later stages
//
// ------------------------------------------------------------
// DATA FLOW:
//
//   instr_i
//      |
//      |--> opcode, funct3, funct7 (instruction decoding)
//      |
//      |--> rs1, rs2, rd (register indices)
//      |
//      |--> reg_file → rs1_data_o, rs2_data_o
//      |
//      |--> imm_gen → imm_o
//      |
//      |--> control_unit → control signals
//
// ------------------------------------------------------------
// WRITEBACK PATH:
//
//   WB Stage → (wb_rd_i, wb_data_i, wb_en_i)
//           → Register File → updated register values
//
// This enables correct data propagation across pipeline stages.
//
// ============================================================

`timescale 1ns/1ps
module id_stage (
    input  logic        clk,
    input  logic [31:0] instr_i,
    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o,
    output logic [31:0] imm_o,
    output logic [4:0]  rs1_o,
    output logic [4:0]  rs2_o,
    output logic [4:0]  rd_o,
    output logic        reg_write_o,
    output logic        mem_read_o,
    output logic        mem_write_o,
    output logic        mem_to_reg_o,
    output logic        alu_src_o,
    output logic        branch_o,
    output logic [3:0]  alu_ctrl_o,
    input  logic        wb_en_i,
    input  logic [4:0]  wb_rd_i,
    input  logic [31:0] wb_data_i
);
    logic [6:0] opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode = instr_i[6:0];
    assign funct3 = instr_i[14:12];
    assign funct7 = instr_i[31:25];

    assign rs1_o = instr_i[19:15];
    assign rs2_o = instr_i[24:20];
    assign rd_o  = instr_i[11:7];

    reg_file u_reg_file (
        .clk      (clk),
        .rs1_i    (rs1_o),
        .rs2_i    (rs2_o),
        .rd_i     (wb_rd_i),
        .rd_data_i(wb_data_i),
        .rd_we_i  (wb_en_i),
        .rs1_data_o(rs1_data_o),
        .rs2_data_o(rs2_data_o)
    );

    imm_gen u_imm_gen (
        .instr_i(instr_i),
        .imm_o  (imm_o)
    );

control_unit u_control_unit (
    .opcode_i    (opcode),
    .funct3_i    (funct3),
    .funct7_i    (funct7),
    .reg_write_o (reg_write_o),
    .mem_read_o  (mem_read_o),
    .mem_write_o (mem_write_o),
    .mem_to_reg_o(mem_to_reg_o),
    .alu_src_o   (alu_src_o),
    .branch_o    (branch_o),
    .alu_ctrl_o  (alu_ctrl_o)
);

endmodule
