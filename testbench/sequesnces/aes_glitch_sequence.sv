`ifndef AES_GLITCH_SEQUENCE_SV
`define AES_GLITCH_SEQUENCE_SV

class aes_glitch_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_glitch_sequence)
    function new(string name = "aes_glitch_sequence"); super.new(name); endfunction
    virtual task body();
        add_vector("IMPROPER-ENABLE-TIMING",
            128'h00112233445566778899aabbccddeeff,
            128'h000102030405060708090a0b0c0d0e0f,
            AES_SCENARIO_GLITCH_STRESS, 2, 3);
        add_vector("RESET-DURING-GATED-CLOCK",
            128'h00000000000000000000000000000000,
            128'h00000000000000000000000000000000,
            AES_SCENARIO_RESET_COLLISION, 0, 2);
    endtask
endclass

`endif
