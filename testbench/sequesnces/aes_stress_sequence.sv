`ifndef AES_STRESS_SEQUENCE_SV
`define AES_STRESS_SEQUENCE_SV

class aes_stress_sequence extends aes_base_sequence;
    `uvm_object_utils(aes_stress_sequence)
    function new(string name = "aes_stress_sequence"); super.new(name); endfunction
    virtual task body();
        repeat (4) begin
            add_vector("STRESS-NIST",
                128'h00112233445566778899aabbccddeeff,
                128'h000102030405060708090a0b0c0d0e0f,
                AES_SCENARIO_TRAFFIC_STRESS, 1, 2);
            add_vector("STRESS-ZERO",
                128'h00000000000000000000000000000000,
                128'h00000000000000000000000000000000,
                AES_SCENARIO_CLK_STALL, 0, 1);
        end
    endtask
endclass

`endif
