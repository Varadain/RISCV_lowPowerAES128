`timescale 1ns/1ps

module aes_tb_top;
    import uvm_pkg::*;
    import aes_uvm_pkg::*;
    `include "uvm_macros.svh"

    localparam int CLK_HALF = 5;
    logic clk;

    initial begin
        clk = 1'b0;
        forever #CLK_HALF clk = ~clk;
    end

    aes_interface aes_if(clk);

    AES128_lowPower dut (
        .clk(clk),
        .reset(aes_if.reset),
        .clk_en(aes_if.clk_en),
        .test_mode(aes_if.test_mode),
        .scan_enable(aes_if.scan_enable),
        .scan_in(aes_if.scan_in),
        .load(aes_if.load),
        .load_sel(aes_if.load_sel),
        .load_index(aes_if.load_index),
        .data_in(aes_if.data_in),
        .start(aes_if.start),
        .data_out_index(aes_if.data_out_index),
        .data_out(aes_if.data_out),
        .done(aes_if.done),
        .scan_out(aes_if.scan_out),
        .gated_clk_dbg(aes_if.gated_clk_dbg)
    );

    assign aes_if.plaintext_dbg  = dut.plaintext_reg;
    assign aes_if.key_dbg        = dut.key_reg;
    assign aes_if.state_dbg      = dut.CORE.state;
    assign aes_if.round_key_dbg  = dut.CORE.round_key;
    assign aes_if.ciphertext_dbg = dut.ciphertext;
    assign aes_if.round_dbg      = dut.CORE.round;

    aes_assertions assertions(aes_if);

    initial begin
        aes_if.reset = 1'b1;
        aes_if.clk_en = 1'b0;
        aes_if.test_mode = 1'b0;
        aes_if.scan_enable = 1'b0;
        aes_if.scan_in = 1'b0;
        aes_if.load = 1'b0;
        aes_if.load_sel = 1'b0;
        aes_if.load_index = 4'd0;
        aes_if.data_in = 8'd0;
        aes_if.start = 1'b0;
        aes_if.data_out_index = 4'd0;
        $dumpfile("../logs/aes_advanced_uvm.vcd");
        $dumpvars(0, aes_tb_top);
        uvm_config_db #(virtual aes_interface)::set(null, "uvm_test_top.env.*", "vif", aes_if);
        uvm_config_db #(virtual aes_interface)::set(null, "uvm_test_top.env.agent.*", "vif", aes_if);
        run_test("aes_stress_test");
    end
endmodule
