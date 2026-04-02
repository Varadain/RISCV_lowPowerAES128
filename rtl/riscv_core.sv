module riscv_core #(
  parameter int XLEN = 32,
  parameter int IMEM_DEPTH = 256,
  parameter string PROGRAM_HEX = "tests/isa/smoke.hex"
) (
  input  logic             clk_i,
  input  logic             rst_ni,
  output logic [31:0]      instr_o,
  output logic [XLEN-1:0]  pc_o,
  output logic [XLEN-1:0]  rs1_data_o,
  output logic [XLEN-1:0]  rs2_data_o,
  output logic [XLEN-1:0]  rd_data_o,
  output logic [4:0]       rs1_o,
  output logic [4:0]       rs2_o,
  output logic [4:0]       rd_o,
  output logic             rd_we_o,
  output logic             trap_o
);
  logic [31:0] imem [0:IMEM_DEPTH-1];
  logic [XLEN-1:0] x [0:31];

  logic [XLEN-1:0] pc_q, pc_n;
  logic [31:0] instr;
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] rd;
  logic [XLEN-1:0] imm_i;

  logic [XLEN-1:0] rs1_data;
  logic [XLEN-1:0] rs2_data;
  logic [XLEN-1:0] rd_data;
  logic rd_we;
  logic trap;

  initial begin
    $readmemh(PROGRAM_HEX, imem);
  end

  assign instr = imem[pc_q[XLEN-1:2]];

  assign opcode = instr[6:0];
  assign rd     = instr[11:7];
  assign funct3 = instr[14:12];
  assign rs1    = instr[19:15];
  assign rs2    = instr[24:20];
  assign funct7 = instr[31:25];
  assign imm_i  = {{20{instr[31]}}, instr[31:20]};

  assign rs1_data = x[rs1];
  assign rs2_data = x[rs2];

  always_comb begin
    pc_n    = pc_q + XLEN'(4);
    rd_data = '0;
    rd_we   = 1'b0;
    trap    = 1'b0;

    unique case (opcode)
      7'b0010011: begin // OP-IMM
        if (funct3 == 3'b000) begin // ADDI
          rd_data = rs1_data + imm_i;
          rd_we   = 1'b1;
        end else begin
          trap = 1'b1;
        end
      end

      7'b0110011: begin // OP
        if ((funct3 == 3'b000) && (funct7 == 7'b0000000)) begin // ADD
          rd_data = rs1_data + rs2_data;
          rd_we   = 1'b1;
        end else begin
          trap = 1'b1;
        end
      end

      7'b1110011: begin // SYSTEM
        if (instr == 32'h00000073) begin // ECALL
          trap = 1'b1;
        end else begin
          trap = 1'b1;
        end
      end

      default: begin
        trap = 1'b1;
      end
    endcase
  end

  integer i;
  always_ff @(posedge clk_i) begin
    if (!rst_ni) begin
      pc_q <= '0;
      for (i = 0; i < 32; i++) begin
        x[i] <= '0;
      end
    end else begin
      pc_q <= pc_n;
      if (rd_we && (rd != 5'd0)) begin
        x[rd] <= rd_data;
      end
      x[0] <= '0;
    end
  end

  assign instr_o    = instr;
  assign pc_o       = pc_q;
  assign rs1_data_o = rs1_data;
  assign rs2_data_o = rs2_data;
  assign rd_data_o  = rd_data;
  assign rs1_o      = rs1;
  assign rs2_o      = rs2;
  assign rd_o       = rd;
  assign rd_we_o    = rd_we;
  assign trap_o     = trap;
endmodule
