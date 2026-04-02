module control_unit (
    input  logic [6:0] opcode_o,
    input  logic [2:0] funct3_o,
    input  logic [6:0] funct7_o,
    output logic       reg_write_o,
    output logic       mem_read_o,
    output logic       mem_write_o,
    output logic       mem_to_reg_o,
    output logic       alu_src_o,
    output logic       branch_o,
    output logic [3:0] alu_ctrl_o
);
    always_comb begin
        reg_write_o = 1'b0;
        mem_read_o  = 1'b0;
        mem_write_o = 1'b0;
        mem_to_reg_o = 1'b0;
        alu_src_o   = 1'b0;
        branch_o    = 1'b0;
        alu_ctrl_o  = 4'b0000;

        case (opcode_o)
            7'b0110011: begin
                reg_write_o = 1'b1;
                case ({funct7_o, funct3_o})
                    10'b0000000_000: alu_ctrl_o = 4'b0000;
                    10'b0100000_000: alu_ctrl_o = 4'b0001;
                    10'b0000000_111: alu_ctrl_o = 4'b0010;
                    10'b0000000_110: alu_ctrl_o = 4'b0011;
                    default:         alu_ctrl_o = 4'b0000;
                endcase
            end
            7'b0010011: begin
                reg_write_o = 1'b1;
                alu_src_o   = 1'b1;
                alu_ctrl_o  = 4'b0000;
            end
            7'b0000011: begin
                reg_write_o = 1'b1;
                mem_read_o  = 1'b1;
                mem_to_reg_o = 1'b1;
                alu_src_o   = 1'b1;
                alu_ctrl_o  = 4'b0000;
            end
            7'b0100011: begin
                mem_write_o = 1'b1;
                alu_src_o   = 1'b1;
                alu_ctrl_o  = 4'b0000;
            end
            7'b1100011: begin
                branch_o    = 1'b1;
                alu_ctrl_o  = 4'b0001;
            end
            default: begin
            end
        endcase
    end
endmodule
