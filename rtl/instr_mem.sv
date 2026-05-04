module instr_mem (
    input  logic [31:0] addr_i,
    output logic [31:0] instr_o
);

    logic [31:0] rom [0:255];  // <-- REQUIRED for UVM access
initial begin
  // Default all to NOP
  for (int i = 0; i < 256; i++) begin
    rom[i] = 32'h00000013; // NOP (ADDI x0,x0,0)
  end

  // Your program
  rom[0] = 32'h00100093; // ADDI x1, x0, 1
  rom[1] = 32'h00200113; // ADDI x2, x0, 2
  rom[2] = 32'h002081b3; // ADD x3, x1, x2
end
    // Address decode
    assign instr_o = rom[addr_i[9:2]];

endmodule
