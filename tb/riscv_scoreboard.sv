module riscv_scoreboard #(parameter XLEN = 32) (
  riscv_if.mon vif
);
  int unsigned instr_count;

  // Example architectural checks; extend this for your ISA subset.
  // This scoreboard is intentionally light-weight so it can be adapted
  // to cores with varying micro-architectures.
  always_ff @(posedge vif.clk) begin
    if (!vif.rst_n) begin
      instr_count <= 0;
    end else begin
      instr_count <= instr_count + 1;

      // x0 register must remain zero if writes are externally visible.
      if (vif.rd_we && (vif.rd == 5'd0) && (vif.rd_data != '0)) begin
        $error("RISC-V ISA violation: x0 written with non-zero value at pc=0x%08h", vif.pc);
      end

      // Optional trap sanity check.
      if (vif.trap) begin
        $display("INFO: Trap observed at pc=0x%08h after %0d instructions", vif.pc, instr_count);
      end
    end
  end
endmodule
