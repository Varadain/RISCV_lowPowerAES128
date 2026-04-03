module data_mem (
    input  logic        clk,
    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,
    input  logic        mem_read_i,
    input  logic        mem_write_i,
    output logic [31:0] read_data_o
);
    logic [31:0] ram [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i++) begin
            ram[i] = 32'h0;
        end
    end

    always_ff @(posedge clk) begin
        if (mem_write_i) begin
            ram[addr_i[9:2]] <= write_data_i;
        end
    end

    assign read_data_o = mem_read_i ? ram[addr_i[9:2]] : 32'h0;
endmodule
