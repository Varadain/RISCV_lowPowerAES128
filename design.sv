`timescale 1ns/1ps

// -----------------------------------------------------------------------------
// design.sv
// -----------------------------------------------------------------------------
// Purpose:
//   Standalone design entry file for EDA Playground / Verilator-style flows that
//   compile only: `design.sv` + `testbench.sv`.
//
// Notes:
//   - This file intentionally includes all RTL modules needed by `riscv_core_top`.
//   - A thin wrapper module (`risc_codex`) is provided for environments that look
//     for a specific top-level DUT name.
//   - No functional logic changes are introduced here.
// -----------------------------------------------------------------------------

// --------------------------
// Core RTL module includes
// --------------------------
`include "rtl/pc_reg.sv"            // Program counter register
`include "rtl/instr_mem.sv"         // Instruction memory model
`include "rtl/if_stage.sv"          // IF stage wrapper
`include "rtl/reg_file.sv"          // Integer register file
`include "rtl/imm_gen.sv"           // Immediate generator
`include "rtl/control_unit.sv"      // Instruction decode/control
`include "rtl/id_stage.sv"          // ID stage wrapper
`include "rtl/alu.sv"               // ALU operations
`include "rtl/ex_stage.sv"          // EX stage wrapper
`include "rtl/data_mem.sv"          // Data memory model
`include "rtl/load_store_unit.sv"   // Sub-word load/store handling
`include "rtl/mem_stage.sv"         // MEM stage wrapper
`include "rtl/wb_stage.sv"          // WB stage mux logic
`include "rtl/hazard_unit.sv"       // Load-use hazard detection
`include "rtl/forwarding_unit.sv"   // Data forwarding selection
`include "rtl/riscv_core_top.sv"    // 5-stage core top

// -----------------------------------------------------------------------------
// Wrapper module: risc_codex
// -----------------------------------------------------------------------------
// Purpose:
//   Thin wrapper around `riscv_core_top` to provide a stable DUT name expected by
//   some playground scripts.
//
// I/O:
//   clk   : Core clock input
//   rst_n : Active-low reset input
// -----------------------------------------------------------------------------
module risc_codex (clk, rst_n);
    input logic clk;
    input logic rst_n;

    // --------------------------
    // Core instantiation
    // --------------------------
    riscv_core_top u_core (
        .clk  (clk),
        .rst_n(rst_n)
    );
endmodule
