interface riscv_if #(parameter XLEN = 32) (input logic clk);
  logic        rst_n;
  logic [31:0] instr;
  logic [XLEN-1:0] pc;
  logic [XLEN-1:0] rs1_data;
  logic [XLEN-1:0] rs2_data;
  logic [XLEN-1:0] rd_data;
  logic [4:0]  rs1;
  logic [4:0]  rs2;
  logic [4:0]  rd;
  logic        rd_we;
  logic        trap;

  modport dut (
    input  clk,
    input  rst_n,
    output instr,
    output pc,
    output rs1_data,
    output rs2_data,
    output rd_data,
    output rs1,
    output rs2,
    output rd,
    output rd_we,
    output trap
  );

  modport mon (
    input clk,
    input rst_n,
    input instr,
    input pc,
    input rs1_data,
    input rs2_data,
    input rd_data,
    input rs1,
    input rs2,
    input rd,
    input rd_we,
    input trap
  );
endinterface
