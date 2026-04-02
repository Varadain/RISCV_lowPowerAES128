module id_stage (
  input  logic                clk,
  input  logic [31:0]         instr,
  input  logic [31:0]         wb_data,
  input  logic [4:0]          wb_rd,
  input  logic                wb_we,
  output logic [4:0]          rs1,
  output logic [4:0]          rs2,
  output logic [4:0]          rd,
  output logic [31:0]         reg_rs1,
  output logic [31:0]         reg_rs2,
  output logic [31:0]         imm,
  output riscv_pkg::control_s ctrl
);
  assign rs1 = instr[19:15];
  assign rs2 = instr[24:20];
  assign rd  = instr[11:7];

  reg_file u_rf (
    .clk(clk),
    .we (wb_we),
    .rs1(rs1),
    .rs2(rs2),
    .rd (wb_rd),
    .wd (wb_data),
    .rd1(reg_rs1),
    .rd2(reg_rs2)
  );

  control_unit u_ctrl (
    .instr(instr),
    .ctrl (ctrl)
  );

  imm_gen u_imm (
    .instr(instr),
    .imm  (imm)
  );
endmodule
