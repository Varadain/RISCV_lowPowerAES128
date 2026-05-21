module data_mem (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [31:0] addr_i,
    input  logic [31:0] write_data_i,

    input  logic        mem_read_i,
    input  logic        mem_write_i,

    output logic [31:0] read_data_o,

    // DMA-lite second port. Word-addressed through normal byte addresses.
    input  logic [31:0] dma_read_addr_i,
    input  logic [31:0] dma_write_addr_i,
    input  logic [31:0] dma_write_data_i,
    input  logic        dma_write_en_i,
    output logic [31:0] dma_read_data_o
);

    // 256 x 32-bit data memory.
    logic [31:0] ram [0:255];

    integer i;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (i = 0; i < 256; i = i + 1) begin
                ram[i] <= 32'h0;
            end
        end else begin
            if (mem_write_i) begin
                ram[addr_i[9:2]] <= write_data_i;
            end

            if (dma_write_en_i) begin
                ram[dma_write_addr_i[9:2]] <= dma_write_data_i;
            end
        end
    end

    assign read_data_o = mem_read_i ? ram[addr_i[9:2]] : 32'h0;
    assign dma_read_data_o = ram[dma_read_addr_i[9:2]];

endmodule
