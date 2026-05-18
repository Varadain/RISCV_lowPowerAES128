`ifndef AES_UVM_PKG_SV
`define AES_UVM_PKG_SV

package aes_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `uvm_analysis_imp_decl(_exp)
    `uvm_analysis_imp_decl(_obs)
    `uvm_analysis_imp_decl(_cov)

    `include "seq_items/aes_transaction.sv"
    `include "reference_model/aes_reference_model.sv"
    `include "sequences/aes_base_sequence.sv"
    `include "sequences/aes_random_sequence.sv"
    `include "sequences/aes_clock_gate_sequence.sv"
    `include "sequences/aes_glitch_sequence.sv"
    `include "sequences/aes_scan_sequence.sv"
    `include "sequences/aes_reset_sequence.sv"
    `include "sequences/aes_stress_sequence.sv"
    `include "agent/aes_sequencer.sv"
    `include "driver/aes_driver.sv"
    `include "monitor/aes_monitor.sv"
    `include "agent/aes_agent.sv"
    `include "scoreboard/aes_scoreboard.sv"
    `include "coverage/aes_coverage.sv"
    `include "power_monitor/aes_power_monitor.sv"
    `include "env/aes_env.sv"
    `include "tests/aes_base_test.sv"
    `include "tests/aes_power_test.sv"
    `include "tests/aes_glitch_test.sv"
    `include "tests/aes_scan_test.sv"
    `include "tests/aes_stress_test.sv"
endpackage

`endif
