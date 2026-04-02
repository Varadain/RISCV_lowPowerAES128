`timescale 1ns/1ps

// Standalone design entry used by external runners.

`include "rtl/pc_reg.sv"
`include "rtl/instr_mem.sv"
`include "rtl/if_stage.sv"
`include "rtl/reg_file.sv"
`include "rtl/imm_gen.sv"
`include "rtl/control_unit.sv"
`include "rtl/id_stage.sv"
`include "rtl/alu.sv"
`include "rtl/ex_stage.sv"
`include "rtl/data_mem.sv"
`include "rtl/load_store_unit.sv"
`include "rtl/mem_stage.sv"
`include "rtl/wb_stage.sv"
`include "rtl/hazard_unit.sv"
`include "rtl/forwarding_unit.sv"
`include "rtl/riscv_core_top.sv"

module risc_codex (
    input logic clk,
    input logic rst_n
);
    riscv_core_top u_core (
        .clk  (clk),
        .rst_n(rst_n)
    );
endmodule
