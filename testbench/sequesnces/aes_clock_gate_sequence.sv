`ifndef AES_CLOCK_GATE_SEQUENCE_SV
`define AES_CLOCK_GATE_SEQUENCE_SV

class aes_clock_gate_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_clock_gate_sequence)
    function new(string name = "aes_clock_gate_sequence"); super.new(name); endfunction
    virtual task body();
        add_vector("IDLE-TO-WAKEUP",
            128'h00112233445566778899aabbccddeeff,
            128'h000102030405060708090a0b0c0d0e0f,
            AES_SCENARIO_IDLE_WAKEUP, 8, 0);
        add_vector("MID-ROUND-CLK-STALL",
            128'h00000000000000000000000000000000,
            128'h00000000000000000000000000000000,
            AES_SCENARIO_CLK_STALL, 0, 6);
        add_vector("FINAL-ROUND-GATING",
            128'hffeeddccbbaa99887766554433221100,
            128'h0f0e0d0c0b0a09080706050403020100,
            AES_SCENARIO_FINAL_ROUND, 0, 0);
    endtask
endclass

`endif
