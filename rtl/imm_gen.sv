module imm_gen (
    input  logic [31:0] instr_i,
    output logic [31:0] imm_o
);
    logic [6:0] opcode;
    assign opcode = instr_i[6:0];

    always_comb begin
        case (opcode)
            7'b0010011, 7'b0000011: imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
            7'b0100011: imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};
            7'b1100011: imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};
            7'b0110111, 7'b0010111: imm_o = {instr_i[31:12], 12'h000};
            default: imm_o = 32'h0;
        endcase
    end
endmodule
