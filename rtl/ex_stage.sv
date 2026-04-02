module ex_stage (
    input  logic [31:0] pc_i,
    input  logic [31:0] rs1_data_i,
    input  logic [31:0] rs2_data_i,
    input  logic [31:0] imm_i,
    input  logic        alu_src_i,
    input  logic        branch_i,
    input  logic [3:0]  alu_ctrl_i,
    input  logic [1:0]  forward_a_i,
    input  logic [1:0]  forward_b_i,
    input  logic [31:0] mem_alu_result_i,
    input  logic [31:0] wb_data_i,
    output logic [31:0] alu_result_o,
    output logic [31:0] rs2_forwarded_o,
    output logic [31:0] branch_target_o,
    output logic        branch_taken_o
);
    localparam logic [3:0] ALU_ADD   = 4'h0;
    localparam logic [3:0] ALU_SUB   = 4'h1;
    localparam logic [3:0] ALU_LUI   = 4'hA;
    localparam logic [3:0] ALU_AUIPC = 4'hB;
    localparam logic [3:0] ALU_BNE   = 4'hC;
    localparam logic [3:0] ALU_BLT   = 4'hD;
    localparam logic [3:0] ALU_BGE   = 4'hE;
    localparam logic [3:0] ALU_LINK  = 4'hF;

    logic [31:0] op_a_raw;
    logic [31:0] op_b_raw;
    logic [31:0] op_a;
    logic [31:0] op_b;
    logic [3:0]  alu_ctrl_eff;
    logic [31:0] alu_result_raw;
    logic [2:0]  ls_tag;
    logic        is_mem_variant;
    logic        zero;
    logic        cmp_lt_signed;

    always_comb begin
        case (forward_a_i)
            2'b10: op_a_raw = mem_alu_result_i;
            2'b01: op_a_raw = wb_data_i;
            default: op_a_raw = rs1_data_i;
        endcase

        case (forward_b_i)
            2'b10: op_b_raw = mem_alu_result_i;
            2'b01: op_b_raw = wb_data_i;
            default: op_b_raw = rs2_data_i;
        endcase
    end

    always_comb begin
        op_a = op_a_raw;
        op_b = alu_src_i ? imm_i : op_b_raw;

        // Reuse ALU_BNE/BLT/BGE/LINK as load/store type tags when not a branch.
        is_mem_variant = !branch_i && ((alu_ctrl_i == ALU_BNE) || (alu_ctrl_i == ALU_BLT) ||
                                       (alu_ctrl_i == ALU_BGE) || (alu_ctrl_i == ALU_LINK));

        // For tagged load/store ops, address math still uses ADD.
        alu_ctrl_eff = is_mem_variant ? ALU_ADD : alu_ctrl_i;

        if (alu_ctrl_i == ALU_LUI) begin
            op_a = 32'h0;
            op_b = imm_i;
        end else if (alu_ctrl_i == ALU_AUIPC) begin
            op_a = pc_i;
            op_b = imm_i;
        end else if (branch_i && (alu_ctrl_i == ALU_LINK)) begin
            // JAL/JALR link value = PC + 4.
            op_a = pc_i;
            op_b = 32'd4;
        end

        ls_tag = 3'b000;
        if (is_mem_variant) begin
            case (alu_ctrl_i)
                ALU_BNE:  ls_tag = 3'b001; // byte signed / sb
                ALU_BLT:  ls_tag = 3'b010; // half signed / sh
                ALU_BGE:  ls_tag = 3'b011; // byte unsigned
                ALU_LINK: ls_tag = 3'b100; // half unsigned
                default:  ls_tag = 3'b000;
            endcase
        end
    end

    assign rs2_forwarded_o = op_b_raw;
    assign cmp_lt_signed = ($signed(op_a_raw) < $signed(op_b_raw));

    always_comb begin
        if (branch_i && alu_src_i && (alu_ctrl_i == ALU_LINK)) begin
            // JALR target = (rs1 + imm) & ~1
            branch_target_o = (op_a_raw + imm_i) & 32'hFFFF_FFFE;
        end else begin
            // Branch/JAL target = PC + imm
            branch_target_o = pc_i + imm_i;
        end
    end

    alu u_alu (
        .a_i       (op_a),
        .b_i       (op_b),
        .alu_ctrl_i(alu_ctrl_eff),
        .result_o  (alu_result_raw),
        .zero_o    (zero)
    );

    // Carry load/store type tag in top address bits; memory indexes low bits only.
    assign alu_result_o = {ls_tag, alu_result_raw[28:0]};

    always_comb begin
        branch_taken_o = 1'b0;
        if (branch_i) begin
            unique case (alu_ctrl_i)
                ALU_SUB: branch_taken_o = zero;            // BEQ
                ALU_BNE: branch_taken_o = !zero;           // BNE
                ALU_BLT: branch_taken_o = cmp_lt_signed;   // BLT/BLTU (signed limitation)
                ALU_BGE: branch_taken_o = !cmp_lt_signed;  // BGE/BGEU (signed limitation)
                ALU_LINK: branch_taken_o = 1'b1;           // JAL/JALR
                default: branch_taken_o = 1'b0;
            endcase
        end
    end

`ifdef DEBUG_TRACE
    always_comb begin
        if (branch_i || is_mem_variant) begin
            $display("[EX ] alu_ctrl=%h eff=%h op_a=0x%08x op_b=0x%08x alu=0x%08x tag=%0d br_tgt=0x%08x br_taken=%0b",
                     alu_ctrl_i, alu_ctrl_eff, op_a, op_b, alu_result_o, ls_tag, branch_target_o, branch_taken_o);
        end
    end
`endif
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
