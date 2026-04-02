module instr_mem (
    input  logic [31:0] addr_i,
    output logic [31:0] instr_o
);
    logic [31:0] rom [0:255];

    initial begin
        integer i;
        for (i = 0; i < 256; i++) begin
            rom[i] = 32'h00000013;
        end
        rom[0] = 32'h00500093; // addi x1, x0, 5
        rom[1] = 32'h00A00113; // addi x2, x0, 10
        rom[2] = 32'h002081B3; // add x3, x1, x2
        rom[3] = 32'h00302023; // sw x3, 0(x0)
        rom[4] = 32'h00002203; // lw x4, 0(x0)
        rom[5] = 32'h00320463; // beq x4, x3, +8
        rom[6] = 32'h00100293; // addi x5, x0, 1
        rom[7] = 32'h00000013; // nop
    end

    assign instr_o = rom[addr_i[9:2]];
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
