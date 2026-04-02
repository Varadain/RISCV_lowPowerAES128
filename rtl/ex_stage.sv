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

        // Small operand steering fixes for upper/jump class instructions.
        if (alu_ctrl_i == ALU_LUI) begin
            op_a = 32'h0;
            op_b = imm_i;
        end else if (alu_ctrl_i == ALU_AUIPC) begin
            op_a = pc_i;
            op_b = imm_i;
        end else if (alu_ctrl_i == ALU_LINK) begin
            op_a = pc_i;
            op_b = 32'd4;
        end
    end

    assign rs2_forwarded_o = op_b_raw;
    assign cmp_lt_signed = ($signed(op_a_raw) < $signed(op_b_raw));

    always_comb begin
        if (alu_ctrl_i == ALU_LINK && alu_src_i) begin
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
        .alu_ctrl_i(alu_ctrl_i),
        .result_o  (alu_result_o),
        .zero_o    (zero)
    );

    always_comb begin
        branch_taken_o = 1'b0;
        if (branch_i) begin
            unique case (alu_ctrl_i)
                ALU_SUB: branch_taken_o = zero;            // BEQ
                ALU_BNE: branch_taken_o = !zero;           // BNE
                ALU_BLT: branch_taken_o = cmp_lt_signed;   // BLT/BLTU (see control note)
                ALU_BGE: branch_taken_o = !cmp_lt_signed;  // BGE/BGEU (see control note)
                ALU_LINK: branch_taken_o = 1'b1;           // JAL/JALR
                default: branch_taken_o = 1'b0;
            endcase
        end
    end

`ifdef DEBUG_TRACE
    always_comb begin
        if (branch_i) begin
            $display("[EX ] alu_ctrl=%h op_a=0x%08x op_b=0x%08x br_tgt=0x%08x br_taken=%0b",
                     alu_ctrl_i, op_a, op_b, branch_target_o, branch_taken_o);
        end
    end
`endif
endmodule
