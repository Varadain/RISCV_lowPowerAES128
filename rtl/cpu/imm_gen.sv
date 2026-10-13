module imm_gen (
    input  logic [31:0] instr_i,
    output logic [31:0] imm_o
);
    logic [6:0] opcode;
    logic [2:0] funct3;

    assign opcode = instr_i[6:0];
    assign funct3 = instr_i[14:12];

    always_comb begin
        case (opcode)
            7'b0010011: begin // I-type ALU immediates
                // Shift-immediates use shamt in [24:20] (zero-extended).
                if ((funct3 == 3'b001) || (funct3 == 3'b101)) begin
                    imm_o = {27'h0, instr_i[24:20]};
                end else begin
                    imm_o = {{20{instr_i[31]}}, instr_i[31:20]};
                end
            end
            7'b0000011, // Loads
            7'b1100111, // JALR
            7'b1110011, // SYSTEM
            7'b0001111: // FENCE/FENCE.I
                imm_o = {{20{instr_i[31]}}, instr_i[31:20]};

            7'b0100011: // S-type
                imm_o = {{20{instr_i[31]}}, instr_i[31:25], instr_i[11:7]};

            7'b1100011: // B-type
                imm_o = {{19{instr_i[31]}}, instr_i[31], instr_i[7], instr_i[30:25], instr_i[11:8], 1'b0};

            7'b0110111, // LUI
            7'b0010111: // AUIPC
                imm_o = {instr_i[31:12], 12'h000};

            7'b1101111: // J-type (JAL)
                imm_o = {{11{instr_i[31]}}, instr_i[31], instr_i[19:12], instr_i[20], instr_i[30:21], 1'b0};

            default:
                imm_o = 32'h0;
        endcase
    end
endmodule