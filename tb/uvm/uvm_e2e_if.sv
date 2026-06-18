// ============================================================================
// UVM end-to-end virtual interface
//
// This interface is the signal-level bridge between UVM classes and the RTL.
// The driver calls the tasks below instead of manually toggling MMIO signals.
// Observation-only fields are also provided so important reference, RTL,
// coverage, and scoreboard values can be displayed in Questa waveforms.
// ============================================================================
interface uvm_e2e_if(input logic clk);
    timeunit 1ns;
    timeprecision 1ps;

    logic rst_n;

    // Direct MMIO connection to the AES ECB/CTR wrapper.
    logic [31:0] aes_addr;
    logic [31:0] aes_wdata;
    logic        aes_write_en;
    logic        aes_read_en;
    logic [31:0] aes_rdata;
    logic        aes_done;

    // Direct MMIO connection to the UART wrapper.
    logic [31:0] uart_addr;
    logic [31:0] uart_wdata;
    logic        uart_write_en;
    logic        uart_read_en;
    logic [31:0] uart_rdata;
    logic        uart_tx;
    logic        uart_busy;
    logic        uart_done;

    // Waveform-observation signals. These do not drive the cryptographic RTL;
    // they make each randomized transaction and its comparison result visible.
    logic [127:0] sensor_plaintext;
    logic [31:0]  transaction_index;
    logic [127:0] reference_ciphertext;
    logic [127:0] reference_decrypted;
    logic [127:0] rtl_ciphertext;
    logic         rtl_ciphertext_match;
    logic         decrypted_plaintext_match;
    logic [31:0]  coverage_bins;
    logic [31:0]  coverage_percent_x100;
    logic [31:0]  uart_matches;
    logic [31:0]  uart_mismatches;

    // Place all driven and observation signals in known inactive states.
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
        transaction_index = 32'h0;
        reference_ciphertext = 128'h0;
        reference_decrypted = 128'h0;
        rtl_ciphertext = 128'h0;
        rtl_ciphertext_match = 1'b0;
        decrypted_plaintext_match = 1'b0;
        coverage_bins = 32'h0;
        coverage_percent_x100 = 32'h0;
        uart_matches = 32'h0;
        uart_mismatches = 32'h0;
    endtask

    // Hold active-low reset for five clocks, then allow two settling clocks.
    task automatic apply_reset();
        init();
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);
    endtask

    // Perform one synchronous 32-bit write to an AES register offset.
    // Signals change on the falling edge and are sampled on the rising edge.
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

    // Read one AES register. The small delay allows combinational read data to
    // settle before the task returns it to the UVM driver.
    task automatic aes_read(input logic [7:0] offset, output logic [31:0] data);
        @(negedge clk);
        aes_addr    = {24'h0, offset};
        aes_read_en = 1'b1;
        #1;
        data = aes_rdata;
        @(negedge clk);
        aes_read_en = 1'b0;
    endtask

    // Perform one synchronous write to the UART MMIO register set.
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
