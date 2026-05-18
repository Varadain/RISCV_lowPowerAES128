`ifndef AES_TRANSACTION_SV
`define AES_TRANSACTION_SV

typedef enum int {
    AES_SCENARIO_FUNCTIONAL,
    AES_SCENARIO_IDLE_WAKEUP,
    AES_SCENARIO_CLK_STALL,
    AES_SCENARIO_GLITCH_STRESS,
    AES_SCENARIO_SCAN_SHIFT,
    AES_SCENARIO_RESET_COLLISION,
    AES_SCENARIO_TRAFFIC_STRESS,
    AES_SCENARIO_FINAL_ROUND
} aes_scenario_e;

class aes_transaction extends uvm_sequence_item;
    bit [127:0] plaintext;
    bit [127:0] key;
    bit [127:0] expected_ciphertext;
    bit [127:0] observed_ciphertext;
    string      test_name;
    aes_scenario_e scenario;
    int unsigned idle_cycles;
    int unsigned stall_cycles;
    int unsigned scan_shift_cycles;
    int unsigned latency_cycles;

    `uvm_object_utils_begin(aes_transaction)
        `uvm_field_int(plaintext, UVM_ALL_ON)
        `uvm_field_int(key, UVM_ALL_ON)
        `uvm_field_int(expected_ciphertext, UVM_ALL_ON)
        `uvm_field_int(observed_ciphertext, UVM_ALL_ON)
        `uvm_field_string(test_name, UVM_ALL_ON)
        `uvm_field_enum(aes_scenario_e, scenario, UVM_ALL_ON)
        `uvm_field_int(idle_cycles, UVM_ALL_ON)
        `uvm_field_int(stall_cycles, UVM_ALL_ON)
        `uvm_field_int(scan_shift_cycles, UVM_ALL_ON)
        `uvm_field_int(latency_cycles, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "aes_transaction");
        super.new(name);
        test_name = name;
        scenario = AES_SCENARIO_FUNCTIONAL;
        idle_cycles = 0;
        stall_cycles = 0;
        scan_shift_cycles = 0;
        latency_cycles = 0;
    endfunction
endclass

`endif
