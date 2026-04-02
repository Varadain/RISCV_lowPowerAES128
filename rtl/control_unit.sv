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
    localparam logic [3:0] ALU_AUIPC = 4'hB;
    localparam logic [3:0] ALU_BNE   = 4'hC;
    localparam logic [3:0] ALU_BLT   = 4'hD;
    localparam logic [3:0] ALU_BGE   = 4'hE;
    localparam logic [3:0] ALU_LINK  = 4'hF;

    always_comb begin
        reg_write_o  = 1'b0;
        mem_read_o   = 1'b0;
        mem_write_o  = 1'b0;
        mem_to_reg_o = 1'b0;
        alu_src_o    = 1'b0;
        branch_o     = 1'b0;
        alu_ctrl_o   = ALU_ADD;

        case (opcode_o)
            7'b0110011: begin // R-type
                reg_write_o = 1'b1;
                unique case ({funct7_o, funct3_o})
                    10'b0000000_000: alu_ctrl_o = ALU_ADD;
                    10'b0100000_000: alu_ctrl_o = ALU_SUB;
                    10'b0000000_001: alu_ctrl_o = ALU_SLL;
                    10'b0000000_010: alu_ctrl_o = ALU_SLT;
                    10'b0000000_011: alu_ctrl_o = ALU_SLTU;
                    10'b0000000_100: alu_ctrl_o = ALU_XOR;
                    10'b0000000_101: alu_ctrl_o = ALU_SRL;
                    10'b0100000_101: alu_ctrl_o = ALU_SRA;
                    10'b0000000_110: alu_ctrl_o = ALU_OR;
                    10'b0000000_111: alu_ctrl_o = ALU_AND;
                    default:         alu_ctrl_o = ALU_ADD;
                endcase
            end

            7'b0010011: begin // I-type ALU immediate
                reg_write_o = 1'b1;
                alu_src_o   = 1'b1;
                unique case (funct3_o)
                    3'b000: alu_ctrl_o = ALU_ADD;  // ADDI
                    3'b010: alu_ctrl_o = ALU_SLT;  // SLTI
                    3'b011: alu_ctrl_o = ALU_SLTU; // SLTIU
                    3'b100: alu_ctrl_o = ALU_XOR;  // XORI
                    3'b110: alu_ctrl_o = ALU_OR;   // ORI
                    3'b111: alu_ctrl_o = ALU_AND;  // ANDI
                    3'b001: alu_ctrl_o = ALU_SLL;  // SLLI
                    3'b101: alu_ctrl_o = funct7_o[5] ? ALU_SRA : ALU_SRL; // SRAI/SRLI
                    default: alu_ctrl_o = ALU_ADD;
                endcase
            end

            7'b0000011: begin // Loads
                reg_write_o  = 1'b1;
                mem_read_o   = 1'b1;
                mem_to_reg_o = 1'b1;
                alu_src_o    = 1'b1;
                unique case (funct3_o)
                    3'b000: alu_ctrl_o = ALU_BNE; // LB  (tagged in EX/MEM)
                    3'b001: alu_ctrl_o = ALU_BLT; // LH
                    3'b010: alu_ctrl_o = ALU_ADD; // LW
                    3'b100: alu_ctrl_o = ALU_BGE; // LBU
                    3'b101: alu_ctrl_o = ALU_LINK; // LHU
                    default: alu_ctrl_o = ALU_ADD;
                endcase
            end

            7'b0100011: begin // Stores
                mem_write_o = 1'b1;
                alu_src_o   = 1'b1;
                unique case (funct3_o)
                    3'b000: alu_ctrl_o = ALU_BNE; // SB  (tagged in EX/MEM)
                    3'b001: alu_ctrl_o = ALU_BLT; // SH
                    3'b010: alu_ctrl_o = ALU_ADD; // SW
                    default: alu_ctrl_o = ALU_ADD;
                endcase
            end

            7'b1100011: begin // Branches
                branch_o = 1'b1;
                unique case (funct3_o)
                    3'b000: alu_ctrl_o = ALU_SUB; // BEQ
                    3'b001: alu_ctrl_o = ALU_BNE; // BNE
                    3'b100: alu_ctrl_o = ALU_BLT; // BLT
                    3'b101: alu_ctrl_o = ALU_BGE; // BGE
                    3'b110: alu_ctrl_o = ALU_BLT; // BLTU (signed compare limitation in current EX path)
                    3'b111: alu_ctrl_o = ALU_BGE; // BGEU (signed compare limitation in current EX path)
                    default: alu_ctrl_o = ALU_SUB;
                endcase
            end

            7'b0110111: begin // LUI
                reg_write_o = 1'b1;
                alu_src_o   = 1'b1;
                alu_ctrl_o  = ALU_LUI;
            end

            7'b0010111: begin // AUIPC
                reg_write_o = 1'b1;
                alu_src_o   = 1'b1;
                alu_ctrl_o  = ALU_AUIPC;
            end

            7'b1101111: begin // JAL
                reg_write_o = 1'b1;
                branch_o    = 1'b1;
                alu_ctrl_o  = ALU_LINK;
            end

            7'b1100111: begin // JALR
                reg_write_o = 1'b1;
                branch_o    = 1'b1;
                alu_src_o   = 1'b1;
                alu_ctrl_o  = ALU_LINK;
            end

            default: begin
            end
        endcase
    end

`ifdef DEBUG_TRACE
    always_comb begin
        $display("[CTRL] opc=%b f3=%b f7=%b alu_ctrl=%h alu_src=%0b br=%0b mr=%0b mw=%0b",
                 opcode_o, funct3_o, funct7_o, alu_ctrl_o, alu_src_o, branch_o, mem_read_o, mem_write_o);
    end
`endif
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
