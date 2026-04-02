module data_mem #(
  parameter int MEM_WORDS = 1024,
  parameter string MEM_HEX_FILE = ""
) (
  input  logic        clk,
  input  logic        mem_read,
  input  logic        mem_write,
  input  logic [31:0] addr,
  input  logic [31:0] wdata,
  output logic [31:0] rdata
);
  logic [31:0] mem [0:MEM_WORDS-1];

  initial begin
    if (MEM_HEX_FILE != "") begin
      $readmemh(MEM_HEX_FILE, mem);
    end
  end

  always_ff @(posedge clk) begin
    if (mem_write) begin
      mem[addr[31:2]] <= wdata;
    end
  end

  always_comb begin
    if (mem_read) begin
      rdata = mem[addr[31:2]];
    end else begin
      rdata = 32'h0;
    end
  end
endmodule
