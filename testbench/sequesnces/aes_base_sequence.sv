`ifndef AES_BASE_SEQUENCE_SV
`define AES_BASE_SEQUENCE_SV

class aes_base_sequence extends uvm_sequence #(aes_transaction);
    `uvm_object_utils(aes_base_sequence)
    aes_reference_model ref_model;

    function new(string name = "aes_base_sequence");
        super.new(name);
        ref_model = aes_reference_model::type_id::create("ref_model");
    endfunction

    task add_vector(string name, bit [127:0] pt, bit [127:0] key,
                    aes_scenario_e scenario = AES_SCENARIO_FUNCTIONAL,
                    int unsigned idle = 0, int unsigned stall = 0,
                    int unsigned scan_cycles = 0);
        aes_transaction tr;
        bit [127:0] exp;
        tr = aes_transaction::type_id::create(name);
        start_item(tr);
        tr.test_name = name;
        tr.plaintext = pt;
        tr.key = key;
        tr.scenario = scenario;
        tr.idle_cycles = idle;
        tr.stall_cycles = stall;
        tr.scan_shift_cycles = scan_cycles;
        if (!ref_model.get_expected(pt, key, exp)) begin
            `uvm_fatal("NO_REF", $sformatf("No reference ciphertext for %s", name))
        end
        tr.expected_ciphertext = exp;
        finish_item(tr);
    endtask

    virtual task body();
        add_vector("NIST-ECB-128",
            128'h00112233445566778899aabbccddeeff,
            128'h000102030405060708090a0b0c0d0e0f);
        add_vector("ALL-ZERO",
            128'h00000000000000000000000000000000,
            128'h00000000000000000000000000000000);
        add_vector("CUSTOM-REV",
            128'hffeeddccbbaa99887766554433221100,
            128'h0f0e0d0c0b0a09080706050403020100);
    endtask
endclass

`endif
