`ifndef AES_RANDOM_SEQUENCE_SV
`define AES_RANDOM_SEQUENCE_SV

class aes_random_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_random_sequence)
    function new(string name = "aes_random_sequence"); super.new(name); endfunction
    virtual task body();
        repeat (2) begin
            super.body();
        end
    endtask
endclass

`endif
