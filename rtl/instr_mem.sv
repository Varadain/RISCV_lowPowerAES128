module instr_mem #(
  parameter int MEM_WORDS = 1024,
  parameter string MEM_HEX_FILE = ""
) (
  input  logic [31:0] addr,
  output logic [31:0] instr
);
  logic [31:0] mem [0:MEM_WORDS-1];

  initial begin
    if (MEM_HEX_FILE != "") begin
      $readmemh(MEM_HEX_FILE, mem);
    end
  end

  assign instr = mem[addr[31:2]];
endmodule
