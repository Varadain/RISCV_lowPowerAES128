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
    logic [31:0] op_a;
    logic [31:0] op_b_raw;
    logic [31:0] op_b;
    logic        zero;

    always_comb begin
        case (forward_a_i)
            2'b10: op_a = mem_alu_result_i;
            2'b01: op_a = wb_data_i;
            default: op_a = rs1_data_i;
        endcase

        case (forward_b_i)
            2'b10: op_b_raw = mem_alu_result_i;
            2'b01: op_b_raw = wb_data_i;
            default: op_b_raw = rs2_data_i;
        endcase
    end

    assign op_b = alu_src_i ? imm_i : op_b_raw;
    assign rs2_forwarded_o = op_b_raw;
    assign branch_target_o = pc_i + imm_i;

    alu u_alu (
        .a_i      (op_a),
        .b_i      (op_b),
        .alu_ctrl_i(alu_ctrl_i),
        .result_o (alu_result_o),
        .zero_o   (zero)
    );

    assign branch_taken_o = branch_i && zero;
endmodule
