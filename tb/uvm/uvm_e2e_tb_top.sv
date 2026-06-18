`timescale 1ns/1ps

// ============================================================================
// UVM end-to-end simulation top
//
// This top instantiates the AES and UART RTL used by the randomized security
// data path. UVM supplies MMIO transactions through e2e_if, while the UART
// monitor observes the real serial TX pin. The C model is called from the UVM
// package and is therefore independent of these RTL instances.
// ============================================================================
module uvm_e2e_tb_top;
    import uvm_pkg::*;
    import uvm_e2e_pkg::*;
    `include "uvm_macros.svh"

    // 100 MHz simulation clock: 10 ns period.
    logic clk;
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Shared virtual interface used by driver, monitor, coverage, and scoreboard.
    uvm_e2e_if e2e_if(clk);

    logic [31:0] aes_custom_result;
    logic [31:0] aes_ciphertext_debug;
    logic        aes_active;
    logic        uart_active;

    // Device under test for AES ECB/CTR register programming and encryption.
    aes_mmio u_aes_mmio (
        .clk               (clk),
        .rst_n             (e2e_if.rst_n),
        .clk_en_i          (1'b1),
        .addr_i            (e2e_if.aes_addr),
        .write_data_i      (e2e_if.aes_wdata),
        .write_en_i        (e2e_if.aes_write_en),
        .read_en_i         (e2e_if.aes_read_en),
        .custom_valid_i    (1'b0),
        .custom_cmd_i      (3'b000),
        .custom_rs1_i      (32'h0),
        .custom_rs2_i      (32'h0),
        .custom_result_o   (aes_custom_result),
        .read_data_o       (e2e_if.aes_rdata),
        .aes_done_irq_o    (e2e_if.aes_done),
        .ciphertext_debug_o(aes_ciphertext_debug),
        .active_o          (aes_active)
    );

    // Device under test for byte serialization of the verification transcript.
    uart_mmio u_uart_mmio (
        .clk          (clk),
        .rst_n        (e2e_if.rst_n),
        .clk_en_i     (1'b1),
        .addr_i       (e2e_if.uart_addr),
        .write_data_i (e2e_if.uart_wdata),
        .write_en_i   (e2e_if.uart_write_en),
        .read_en_i    (e2e_if.uart_read_en),
        .read_data_o  (e2e_if.uart_rdata),
        .uart_tx_o    (e2e_if.uart_tx),
        .tx_busy_o    (e2e_if.uart_busy),
        .tx_done_o    (e2e_if.uart_done),
        .tx_done_irq_o(),
        .active_o     (uart_active)
    );

    // Publish the interface through the UVM configuration database, then start
    // the registered test. All UVM components retrieve the same interface.
    initial begin
        uvm_config_db#(virtual uvm_e2e_if)::set(null, "*", "vif", e2e_if);
        run_test("uvm_e2e_test");
    end
endmodule
