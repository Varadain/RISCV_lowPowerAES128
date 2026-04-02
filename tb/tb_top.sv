`timescale 1ns/1ps

module tb_top;
  localparam int XLEN = 32;

  logic clk;
  initial clk = 1'b0;
  always #5 clk = ~clk;

  riscv_if #(XLEN) riscv_vif (clk);

  // Reset sequence
  initial begin
    riscv_vif.rst_n = 1'b0;
    repeat (10) @(posedge clk);
    riscv_vif.rst_n = 1'b1;
  end

  riscv_core #(
    .XLEN(XLEN),
    .IMEM_DEPTH(256),
    .PROGRAM_HEX("tests/isa/smoke.hex")
  ) dut (
    .clk_i      (clk),
    .rst_ni     (riscv_vif.rst_n),
    .instr_o    (riscv_vif.instr),
    .pc_o       (riscv_vif.pc),
    .rs1_data_o (riscv_vif.rs1_data),
    .rs2_data_o (riscv_vif.rs2_data),
    .rd_data_o  (riscv_vif.rd_data),
    .rs1_o      (riscv_vif.rs1),
    .rs2_o      (riscv_vif.rs2),
    .rd_o       (riscv_vif.rd),
    .rd_we_o    (riscv_vif.rd_we),
    .trap_o     (riscv_vif.trap)
  );

  riscv_scoreboard #(XLEN) sb (
    .vif(riscv_vif)
  );

  initial begin
    wait (riscv_vif.rst_n);
    wait (riscv_vif.trap);
    $display("INFO: Test completed with trap at pc=0x%08h", riscv_vif.pc);
    #10;
    $finish;
  end

  // Timeout guard
  initial begin
    repeat (20000) @(posedge clk);
    $fatal(1, "Simulation timeout");
  end
endmodule
