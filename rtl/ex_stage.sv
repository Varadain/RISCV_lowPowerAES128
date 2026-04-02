module ex_stage (
  input  logic                [31:0] pc,
  input  logic                [31:0] rs1_data,
  input  logic                [31:0] rs2_data,
  input  logic                [31:0] imm,
  input  logic                [31:0] ex_mem_alu,
  input  logic                [31:0] wb_data,
  input  logic                [1:0]  fwd_a_sel,
  input  logic                [1:0]  fwd_b_sel,
  input  riscv_pkg::control_s         ctrl,
  input  logic                [2:0]  funct3,
  output logic                [31:0] alu_out,
  output logic                [31:0] rs2_forwarded,
  output logic                [31:0] branch_target,
  output logic                       branch_taken,
  output logic                [31:0] pc_plus4
);
  logic [31:0] fwd_a;
  logic [31:0] fwd_b;
  logic [31:0] alu_b;
  logic        alu_zero;

  always_comb begin
    unique case (fwd_a_sel)
      2'b10: fwd_a = ex_mem_alu;
      2'b01: fwd_a = wb_data;
      default: fwd_a = rs1_data;
    endcase

    unique case (fwd_b_sel)
      2'b10: fwd_b = ex_mem_alu;
      2'b01: fwd_b = wb_data;
      default: fwd_b = rs2_data;
    endcase
  end

  assign rs2_forwarded = fwd_b;
  assign alu_b         = ctrl.alu_src ? imm : fwd_b;
  assign pc_plus4      = pc + 32'd4;

  alu u_alu (
    .alu_ctrl(ctrl.alu_ctrl),
    .a       ((ctrl.jalr) ? fwd_a : ((ctrl.jump && !ctrl.jalr) ? pc : fwd_a)),
    .b       ((ctrl.jump && !ctrl.jalr) ? imm : alu_b),
    .y       (alu_out),
    .zero    (alu_zero)
  );

  assign branch_target = ctrl.jalr ? {alu_out[31:1], 1'b0} : (pc + imm);

  always_comb begin
    branch_taken = 1'b0;
    if (ctrl.jump) begin
      branch_taken = 1'b1;
    end else if (ctrl.branch) begin
      unique case (funct3)
        3'b000: branch_taken = (fwd_a == fwd_b); // BEQ
        3'b001: branch_taken = (fwd_a != fwd_b); // BNE
        default: branch_taken = alu_zero;
      endcase
    end
  end
endmodule
