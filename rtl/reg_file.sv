module reg_file (
    input  logic        clk,
    input  logic [4:0]  rs1_i,
    input  logic [4:0]  rs2_i,
    input  logic [4:0]  rd_i,
    input  logic [31:0] rd_data_i,
    input  logic        rd_we_i,
    output logic [31:0] rs1_data_o,
    output logic [31:0] rs2_data_o
);
    logic [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i++) begin
            regs[i] = 32'h0;
        end
    end

    assign rs1_data_o = (rs1_i == 5'h0) ? 32'h0 : regs[rs1_i];
    assign rs2_data_o = (rs2_i == 5'h0) ? 32'h0 : regs[rs2_i];

    always_ff @(posedge clk) begin
        if (rd_we_i && (rd_i != 5'h0)) begin
            regs[rd_i] <= rd_data_i;
        end
    end
  input  logic        clk,
  input  logic        we,
  input  logic [4:0]  rs1,
  input  logic [4:0]  rs2,
  input  logic [4:0]  rd,
  input  logic [31:0] wd,
  output logic [31:0] rd1,
  output logic [31:0] rd2
);
  logic [31:0] regs [0:31];

  always_ff @(posedge clk) begin
    if (we && (rd != 5'd0)) begin
      regs[rd] <= wd;
    end
  end

  assign rd1 = (rs1 == 5'd0) ? 32'h0 : regs[rs1];
  assign rd2 = (rs2 == 5'd0) ? 32'h0 : regs[rs2];
endmodule
