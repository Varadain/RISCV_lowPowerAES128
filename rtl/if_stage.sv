module if_stage (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        stall,
  input  logic        pc_redirect,
  input  logic [31:0] redirect_pc,
  output logic [31:0] if_pc,
  output logic [31:0] if_instr
);
  logic [31:0] pc_next;

  assign pc_next = pc_redirect ? redirect_pc : (if_pc + 32'd4);

  program_counter u_pc (
    .clk    (clk),
    .rst_n  (rst_n),
    .en     (~stall),
    .next_pc(pc_next),
    .pc     (if_pc)
  );

  instr_mem u_imem (
    .addr (if_pc),
    .instr(if_instr)
  );
endmodule
