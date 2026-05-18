`ifndef AES_RESET_SEQUENCE_SV
`define AES_RESET_SEQUENCE_SV

class aes_reset_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_reset_sequence)
    function new(string name = "aes_reset_sequence"); super.new(name); endfunction
    virtual task body();
        add_vector("CLOCK-GATE-RESET-COLLISION",
            128'hffeeddccbbaa99887766554433221100,
            128'h0f0e0d0c0b0a09080706050403020100,
            AES_SCENARIO_RESET_COLLISION, 0, 3);
    endtask
endclass

`endif
