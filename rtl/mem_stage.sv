module mem_stage (
  input  logic                clk,
  input  riscv_pkg::control_s ctrl,
  input  logic [31:0]         addr,
  input  logic [31:0]         store_data,
  output logic [31:0]         load_data
);
  data_mem u_dmem (
    .clk      (clk),
    .mem_read (ctrl.mem_read),
    .mem_write(ctrl.mem_write),
    .addr     (addr),
    .wdata    (store_data),
    .rdata    (load_data)
  );
endmodule
