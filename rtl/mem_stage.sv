module mem_stage (
    input  logic        clk,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        mem_read_i,
    input  logic        mem_write_i,
    output logic [31:0] read_data_o
);
    data_mem u_data_mem (
        .clk         (clk),
        .addr_i      (addr_i),
        .write_data_i(write_data_i),
        .mem_read_i  (mem_read_i),
        .mem_write_i (mem_write_i),
        .read_data_o (read_data_o)
    );
endmodule
