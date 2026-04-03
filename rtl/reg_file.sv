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

assign rs1_bypass = rd_we_i && (rd_i != 5'h0) && (rd_i == rs1_i);
assign rs2_bypass = rd_we_i && (rd_i != 5'h0) && (rd_i == rs2_i);
assign rs1_data_o = (rs1_i == 5'h0) ? 32'h0 : (rs1_bypass ? rd_data_i : regs[rs1_i]);
assign rs2_data_o = (rs2_i == 5'h0) ? 32'h0 : (rs2_bypass ? rd_data_i : regs[rs2_i]);

    always_ff @(posedge clk) begin
        if (rd_we_i && (rd_i != 5'h0)) begin
            regs[rd_i] <= rd_data_i;
        end
    end
endmodule
