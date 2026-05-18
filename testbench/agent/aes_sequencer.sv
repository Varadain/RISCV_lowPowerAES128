`ifndef AES_SEQUENCER_SV
`define AES_SEQUENCER_SV

class aes_sequencer extends uvm_sequencer #(aes_transaction);
    `uvm_component_utils(aes_sequencer)
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
