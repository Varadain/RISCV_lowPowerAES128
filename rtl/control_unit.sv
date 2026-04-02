module control_unit (
  input  logic [31:0] instr,
  output riscv_pkg::control_s ctrl
);
  import riscv_pkg::*;

  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;

  assign opcode = instr[6:0];
  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];

  always_comb begin
    ctrl = '0;
    unique case (opcode)
      7'b0110011: begin // R-type
        ctrl.reg_write = 1'b1;
        ctrl.wb_src    = WB_SRC_ALU;
        unique case ({funct7, funct3})
          10'b0000000_000: ctrl.alu_ctrl = 4'b0000; // ADD
          10'b0100000_000: ctrl.alu_ctrl = 4'b0001; // SUB
          10'b0000000_111: ctrl.alu_ctrl = 4'b0010; // AND
          10'b0000000_110: ctrl.alu_ctrl = 4'b0011; // OR
          10'b0000000_100: ctrl.alu_ctrl = 4'b0100; // XOR
          10'b0000000_010: ctrl.alu_ctrl = 4'b0101; // SLT
          10'b0000000_011: ctrl.alu_ctrl = 4'b0110; // SLTU
          10'b0000000_001: ctrl.alu_ctrl = 4'b0111; // SLL
          10'b0000000_101: ctrl.alu_ctrl = 4'b1000; // SRL
          10'b0100000_101: ctrl.alu_ctrl = 4'b1001; // SRA
          default:         ctrl.alu_ctrl = 4'b0000;
        endcase
      end
      7'b0010011: begin // I-type ALU
        ctrl.reg_write = 1'b1;
        ctrl.alu_src   = 1'b1;
        ctrl.wb_src    = WB_SRC_ALU;
        unique case (funct3)
          3'b000: ctrl.alu_ctrl = 4'b0000; // ADDI
          3'b010: ctrl.alu_ctrl = 4'b0101; // SLTI
          3'b011: ctrl.alu_ctrl = 4'b0110; // SLTIU
          3'b100: ctrl.alu_ctrl = 4'b0100; // XORI
          3'b110: ctrl.alu_ctrl = 4'b0011; // ORI
          3'b111: ctrl.alu_ctrl = 4'b0010; // ANDI
          3'b001: ctrl.alu_ctrl = 4'b0111; // SLLI
          3'b101: ctrl.alu_ctrl = funct7[5] ? 4'b1001 : 4'b1000; // SRAI/SRLI
          default: ctrl.alu_ctrl = 4'b0000;
        endcase
      end
      7'b0000011: begin // LW
        ctrl.reg_write = 1'b1;
        ctrl.mem_read  = 1'b1;
        ctrl.alu_src   = 1'b1;
        ctrl.alu_ctrl  = 4'b0000;
        ctrl.wb_src    = WB_SRC_MEM;
      end
      7'b0100011: begin // SW
        ctrl.mem_write = 1'b1;
        ctrl.alu_src   = 1'b1;
        ctrl.alu_ctrl  = 4'b0000;
      end
      7'b1100011: begin // BEQ/BNE
        ctrl.branch   = 1'b1;
        ctrl.alu_ctrl = 4'b0001;
      end
      7'b1101111: begin // JAL
        ctrl.reg_write = 1'b1;
        ctrl.jump      = 1'b1;
        ctrl.wb_src    = WB_SRC_PC4;
      end
      7'b1100111: begin // JALR
        ctrl.reg_write = 1'b1;
        ctrl.jump      = 1'b1;
        ctrl.jalr      = 1'b1;
        ctrl.alu_src   = 1'b1;
        ctrl.alu_ctrl  = 4'b0000;
        ctrl.wb_src    = WB_SRC_PC4;
      end
      7'b0110111: begin // LUI
        ctrl.reg_write = 1'b1;
        ctrl.alu_src   = 1'b1;
        ctrl.alu_ctrl  = 4'b0000;
        ctrl.wb_src    = WB_SRC_ALU;
      end
      7'b0010111: begin // AUIPC
        ctrl.reg_write = 1'b1;
        ctrl.alu_src   = 1'b1;
        ctrl.alu_ctrl  = 4'b0000;
        ctrl.wb_src    = WB_SRC_ALU;
      end
      default: ctrl = '0;
    endcase
  end
endmodule
