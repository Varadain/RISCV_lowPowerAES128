module mem_stage (
    input  logic        clk,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        mem_read_i,
    input  logic        mem_write_i,
    output logic [31:0] read_data_o
);
    logic [2:0]  ls_tag;
    logic [31:0] eff_addr;
    logic [31:0] raw_mem_word;
    logic [31:0] merged_store_word;

    assign ls_tag   = addr_i[31:29];
    assign eff_addr = {3'b000, addr_i[28:0]};

    load_store_unit u_load_store_unit (
        .ls_tag_i           (ls_tag),
        .byte_off_i         (eff_addr[1:0]),
        .mem_word_i         (raw_mem_word),
        .store_data_i       (write_data_i),
        .load_data_o        (read_data_o),
        .merged_store_word_o(merged_store_word)
    );

    data_mem u_data_mem (
        .clk         (clk),
        .addr_i      (eff_addr),
        .write_data_i((ls_tag == 3'b000) ? write_data_i : merged_store_word),
        .mem_read_i  (mem_read_i | mem_write_i),
        .mem_write_i (mem_write_i),
        .read_data_o (raw_mem_word)
    );
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
