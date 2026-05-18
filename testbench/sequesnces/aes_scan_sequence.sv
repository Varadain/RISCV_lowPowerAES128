`ifndef AES_SCAN_SEQUENCE_SV
`define AES_SCAN_SEQUENCE_SV

class aes_scan_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_scan_sequence)
    function new(string name = "aes_scan_sequence"); super.new(name); endfunction
    virtual task body();
        add_vector("SCAN-BYPASS-SHIFT",
            128'h00112233445566778899aabbccddeeff,
            128'h000102030405060708090a0b0c0d0e0f,
            AES_SCENARIO_SCAN_SHIFT, 0, 0, 24);
    endtask
endclass

`endif
