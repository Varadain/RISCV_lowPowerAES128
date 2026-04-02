module alu (
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic [3:0]  alu_ctrl_i,
    output logic [31:0] result_o,
    output logic        zero_o
);
    localparam logic [3:0] ALU_ADD   = 4'h0;
    localparam logic [3:0] ALU_SUB   = 4'h1;
    localparam logic [3:0] ALU_AND   = 4'h2;
    localparam logic [3:0] ALU_OR    = 4'h3;
    localparam logic [3:0] ALU_XOR   = 4'h4;
    localparam logic [3:0] ALU_SLL   = 4'h5;
    localparam logic [3:0] ALU_SLT   = 4'h6;
    localparam logic [3:0] ALU_SLTU  = 4'h7;
    localparam logic [3:0] ALU_SRL   = 4'h8;
    localparam logic [3:0] ALU_SRA   = 4'h9;
    localparam logic [3:0] ALU_LUI   = 4'hA;

    always_comb begin
        unique case (alu_ctrl_i)
            ALU_ADD:  result_o = a_i + b_i;
            ALU_SUB:  result_o = a_i - b_i;
            ALU_AND:  result_o = a_i & b_i;
            ALU_OR:   result_o = a_i | b_i;
            ALU_XOR:  result_o = a_i ^ b_i;
            ALU_SLL:  result_o = a_i << b_i[4:0];
            ALU_SLT:  result_o = ($signed(a_i) < $signed(b_i)) ? 32'd1 : 32'd0;
            ALU_SLTU: result_o = (a_i < b_i) ? 32'd1 : 32'd0;
            ALU_SRL:  result_o = a_i >> b_i[4:0];
            ALU_SRA:  result_o = $signed(a_i) >>> b_i[4:0];
            ALU_LUI:  result_o = b_i;
            default:  result_o = a_i + b_i;
        endcase
    end

    assign zero_o = (result_o == 32'h0);
endmodule
