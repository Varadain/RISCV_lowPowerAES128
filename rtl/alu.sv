module alu (
    input  logic [31:0] a_i,
    input  logic [31:0] b_i,
    input  logic [3:0]  alu_ctrl_i,
    output logic [31:0] result_o,
    output logic        zero_o
);
    always_comb begin
        case (alu_ctrl_i)
            4'b0000: result_o = a_i + b_i;
            4'b0001: result_o = a_i - b_i;
            4'b0010: result_o = a_i & b_i;
            4'b0011: result_o = a_i | b_i;
            4'b0100: result_o = a_i ^ b_i;
            default: result_o = 32'h0;
        endcase
    end

    assign zero_o = (result_o == 32'h0);
endmodule
