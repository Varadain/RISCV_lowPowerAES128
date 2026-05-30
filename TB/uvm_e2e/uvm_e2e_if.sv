interface uvm_e2e_if(input logic clk);
    timeunit 1ns;
    timeprecision 1ps;

    logic rst_n;

    logic [31:0] aes_addr;
    logic [31:0] aes_wdata;
    logic        aes_write_en;
    logic        aes_read_en;
    logic [31:0] aes_rdata;
    logic        aes_done;

    logic [31:0] uart_addr;
    logic [31:0] uart_wdata;
    logic        uart_write_en;
    logic        uart_read_en;
    logic [31:0] uart_rdata;
    logic        uart_tx;
    logic        uart_busy;
    logic        uart_done;

    logic [127:0] sensor_plaintext;

    task automatic init();
        rst_n         = 1'b0;
        aes_addr      = 32'h0;
        aes_wdata     = 32'h0;
        aes_write_en  = 1'b0;
        aes_read_en   = 1'b0;
        uart_addr     = 32'h0;
        uart_wdata    = 32'h0;
        uart_write_en = 1'b0;
        uart_read_en  = 1'b0;
        sensor_plaintext = 128'h0;
    endtask

    task automatic apply_reset();
        init();
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
    endtask

    task automatic aes_write(input logic [7:0] offset, input logic [31:0] data);
        @(negedge clk);
        aes_addr     = {24'h0, offset};
        aes_wdata    = data;
        aes_write_en = 1'b1;
        aes_read_en  = 1'b0;
        @(posedge clk);
        @(negedge clk);
        aes_write_en = 1'b0;
        aes_wdata    = 32'h0;
    endtask

    task automatic aes_read(input logic [7:0] offset, output logic [31:0] data);
        @(negedge clk);
        aes_addr    = {24'h0, offset};
        aes_read_en = 1'b1;
        #1;
        data = aes_rdata;
        @(negedge clk);
        aes_read_en = 1'b0;
    endtask

    task automatic uart_write(input logic [5:0] offset, input logic [31:0] data);
        @(negedge clk);
        uart_addr     = {26'h0, offset};
        uart_wdata    = data;
        uart_write_en = 1'b1;
        uart_read_en  = 1'b0;
        @(posedge clk);
        @(negedge clk);
        uart_write_en = 1'b0;
        uart_wdata    = 32'h0;
    endtask
endinterface
